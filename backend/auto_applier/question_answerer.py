"""
JOB SeArCh — AI Question Answerer
══════════════════════════════════
Uses Gemini/Groq to answer custom screening questions on ATS forms.
Draws context from the candidate profile, resume text, and JD.
"""

import json
import os
import re
import sys

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from config import Config


_gemini_client = None
_groq_client = None


def _get_gemini():
    global _gemini_client
    if _gemini_client is None and Config.GEMINI_API_KEY:
        from google import genai
        _gemini_client = genai.Client(api_key=Config.GEMINI_API_KEY)
    return _gemini_client


def _get_groq():
    global _groq_client
    if _groq_client is None and Config.GROQ_API_KEY:
        from groq import Groq
        _groq_client = Groq(api_key=Config.GROQ_API_KEY)
    return _groq_client


def _call_llm(prompt: str, max_tokens: int = 400) -> str:
    """Call Groq (primary) or Gemini (fallback) for question answering."""
    # 1. Try Groq
    groq = _get_groq()
    if groq is not None:
        try:
            resp = groq.chat.completions.create(
                model=Config.GROQ_MODEL,
                messages=[
                    {
                        "role": "system",
                        "content": (
                            "You are helping a job applicant fill out their application form. "
                            "Write natural, honest, professional answers. "
                            "Keep answers concise (2-4 sentences for short answers, "
                            "1 paragraph for longer ones). "
                            "NEVER fabricate experience or skills not mentioned in the resume. "
                            "Return ONLY the answer text, no explanations or JSON."
                        ),
                    },
                    {"role": "user", "content": prompt},
                ],
                temperature=0.3,
                max_tokens=max_tokens,
            )
            content = resp.choices[0].message.content or ""
            return content.strip()
        except Exception as e:
            print(f"[QuestionAnswerer] Groq failed, trying Gemini: {e}")

    # 2. Try Gemini
    gemini = _get_gemini()
    if gemini is not None:
        try:
            response = gemini.models.generate_content(
                model=Config.LLM_MODEL,
                contents=prompt,
            )
            return response.text.strip()
        except Exception as e:
            print(f"[QuestionAnswerer] Gemini failed: {e}")

    return ""


def determine_work_auth_answer(
    question: str,
    candidate_info: dict,
) -> str | None:
    """
    Intelligently determine the truthful, ATS-compliant answer for work authorization
    and sponsorship screening questions based on candidate profile and question jurisdiction.

    Prevents ATS blacklisting caused by falsely claiming US authorization or denying sponsorship needs
    when the applicant resides abroad (e.g., India).
    """
    q_lower = question.lower().strip()

    # Work authorization phrases
    auth_phrases = [
        "authorized to work", "legally authorized", "eligible to work",
        "right to work", "work authorization", "legal right to work",
        "permitted to work", "work eligibility", "employment authorization",
        "employment eligibility", "legally permitted", "legal authorization",
    ]
    is_auth_q = any(phrase in q_lower for phrase in auth_phrases)

    # Sponsorship phrases
    sponsor_phrases = [
        "require sponsorship", "need sponsorship", "visa sponsorship",
        "require visa", "sponsorship for employment", "sponsorship to work",
        "future require sponsorship", "now or in the future require",
        "immigration sponsorship", "employer sponsorship",
        "require an employer-sponsored", "require company sponsorship",
        "sponsor a visa", "sponsor your employment",
    ]
    is_sponsor_q = any(phrase in q_lower for phrase in sponsor_phrases)

    if not is_auth_q and not is_sponsor_q:
        return None

    # Check for negative / inverted phrasing:
    # e.g., "do not require", "not require", "will not require", "not need", "without requiring"
    is_negative_sponsor = any(phrase in q_lower for phrase in [
        "not require", "do not require", "will not require",
        "don't require", "wont require", "won't require",
        "not need", "do not need", "will not need",
        "without requiring", "without the need for sponsorship",
        "without sponsorship",
    ])

    # Check if the question is an authorization question asking "authorized ... without sponsorship"
    # e.g. "Are you authorized to work in the US without sponsorship?"
    is_auth_without_sponsor = (
        is_auth_q and any(phrase in q_lower for phrase in [
            "without sponsorship", "without requiring sponsorship",
            "without visa sponsorship", "without the need for",
        ])
    )

    # Detect jurisdiction / country context
    is_us_specific = bool(
        re.search(r'\b(us|u\.s\.?|usa|u\.s\.a\.?|united states)\b', q_lower)
    )

    candidate_country = str(
        candidate_info.get("work_auth_country", candidate_info.get("country", "India"))
    ).strip().lower()

    candidate_authorized_in_us = bool(
        candidate_info.get("authorized_in_us", candidate_country in ["united states", "us", "usa"])
    )
    candidate_requires_us_sponsorship = bool(
        candidate_info.get("requires_us_sponsorship", not candidate_authorized_in_us)
    )

    candidate_general_auth = bool(candidate_info.get("authorized_to_work", True))
    candidate_general_sponsor = bool(candidate_info.get("requires_sponsorship", False))
    authorized_countries = [
        c.lower() for c in candidate_info.get("authorized_countries", [candidate_country])
    ]

    # 1. Questions asking "Are you authorized without sponsorship?"
    if is_auth_without_sponsor:
        if is_us_specific:
            return "Yes" if (candidate_authorized_in_us and not candidate_requires_us_sponsorship) else "No"
        # Check other countries
        for country in authorized_countries:
            if country in q_lower:
                return "Yes"
        return "No" if candidate_requires_us_sponsorship else "Yes"

    # 2. Sponsorship questions (Takes precedence over auth questions when compound phrases appear,
    # e.g., "Do you require sponsorship for work authorization?")
    if is_sponsor_q:
        if is_us_specific:
            needs = candidate_requires_us_sponsorship
            return "No" if is_negative_sponsor else ("Yes" if needs else "No")

        # Other known countries
        known_countries = {
            "india": "india" in authorized_countries,
            "canada": "canada" in authorized_countries,
            "united kingdom": any(c in ["united kingdom", "uk"] for c in authorized_countries),
            "uk": any(c in ["united kingdom", "uk"] for c in authorized_countries),
            "germany": "germany" in authorized_countries,
            "australia": "australia" in authorized_countries,
        }
        for country_name, is_auth in known_countries.items():
            if re.search(rf'\b{country_name}\b', q_lower):
                needs = not is_auth
                return "No" if is_negative_sponsor else ("Yes" if needs else "No")

        # Generic sponsorship question
        if candidate_country not in ["united states", "us", "usa"] and not candidate_authorized_in_us:
            needs = candidate_requires_us_sponsorship
        else:
            needs = candidate_general_sponsor
        return "No" if is_negative_sponsor else ("Yes" if needs else "No")

    # 3. Pure work authorization questions
    if is_auth_q:
        if is_us_specific:
            return "Yes" if candidate_authorized_in_us else "No"

        known_countries = {
            "india": "india" in authorized_countries,
            "canada": "canada" in authorized_countries,
            "united kingdom": any(c in ["united kingdom", "uk"] for c in authorized_countries),
            "uk": any(c in ["united kingdom", "uk"] for c in authorized_countries),
            "germany": "germany" in authorized_countries,
            "australia": "australia" in authorized_countries,
        }
        for country_name, is_auth in known_countries.items():
            if re.search(rf'\b{country_name}\b', q_lower):
                return "Yes" if is_auth else "No"

        return "Yes" if candidate_general_auth else "No"

    return None


def answer_screening_question(
    question: str,
    job_title: str,
    job_company: str,
    job_description: str,
    resume_text: str,
    candidate_info: dict,
    custom_answers: dict[str, str] | None = None,
) -> str:
    """
    Generate an answer for a custom screening question.

    First checks the candidate's pre-written custom_answers bank.
    If no match, uses jurisdiction-aware work authorization logic,
    and falls back to LLM for open-ended questions.
    """
    question_lower = question.lower().strip()

    # ── Check custom answer bank first ──
    if custom_answers:
        # Direct keyword matching for common questions
        keyword_map = {
            "why_interested": ["why are you interested", "why do you want", "what excites you", "what attracts you"],
            "greatest_strength": ["greatest strength", "biggest strength", "strong suit", "best quality"],
            "salary_expectations": ["salary", "compensation", "pay expectation", "desired salary"],
            "earliest_start_date": ["start date", "when can you start", "earliest", "availability"],
            "referral_source": ["how did you hear", "referral", "where did you find", "learn about this"],
        }
        for key, triggers in keyword_map.items():
            if key in custom_answers and any(t in question_lower for t in triggers):
                return custom_answers[key]

    # ── Jurisdiction-aware work authorization & visa sponsorship ──
    work_auth_ans = determine_work_auth_answer(question, candidate_info)
    if work_auth_ans is not None:
        return work_auth_ans

    if any(phrase in question_lower for phrase in ["willing to relocate", "open to relocating"]):
        return "Yes"

    if any(phrase in question_lower for phrase in ["years of experience", "how many years"]):
        yoe = candidate_info.get("years_of_experience", 0)
        return str(yoe) if yoe > 0 else "Less than 1 year"

    # ── Generate answer via LLM ──
    prompt = f"""You are filling out a job application for the role: {job_title} at {job_company}.

The application form asks this question:
"{question}"

Here is the candidate's resume/background:
{resume_text[:3000]}

Here is the job description (key parts):
{job_description[:2000]}

Candidate info:
- Name: {candidate_info.get('full_name', 'N/A')}
- Location: {candidate_info.get('location', 'N/A')}
- Current Role: {candidate_info.get('current_title', 'N/A')} at {candidate_info.get('current_company', 'N/A')}
- Experience: {candidate_info.get('years_of_experience', 'N/A')} years

Write a concise, honest, and professional answer to the question.
Only reference experience and skills actually present in the resume.
Do NOT fabricate or exaggerate."""

    return _call_llm(prompt)


def generate_tailored_cover_pitch(
    job_title: str,
    job_company: str,
    job_description: str,
    resume_text: str,
    candidate_name: str,
) -> str:
    """Generate a short tailored cover pitch for the 'Additional Info' field."""
    prompt = f"""Write a brief, tailored cover note for a job application.

Role: {job_title} at {job_company}
Candidate: {candidate_name}

Job description (summary):
{job_description[:2000]}

Candidate resume (summary):
{resume_text[:2000]}

Write 3-5 sentences connecting the candidate's real experience to this specific role.
Reference the company by name. Be specific about which skills/projects align.
Keep it natural and conversational — not robotic or generic.
Do NOT start with "Dear Hiring Manager" — this goes in an "Additional Information" text box."""

    return _call_llm(prompt, max_tokens=300)
