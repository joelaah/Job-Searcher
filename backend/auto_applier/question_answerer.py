"""
JOB SeArCh — AI Question Answerer
══════════════════════════════════
Uses Gemini/Groq to answer custom screening questions on ATS forms.
Draws context from the candidate profile, resume text, and JD.
"""

import json
import os
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
    If no match, uses the LLM to generate an answer from context.
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

    # ── Common yes/no questions with known answers ──
    if any(phrase in question_lower for phrase in ["authorized to work", "legally authorized", "eligible to work"]):
        return "Yes" if candidate_info.get("authorized_to_work", True) else "No"

    if any(phrase in question_lower for phrase in ["require sponsorship", "need sponsorship", "visa sponsorship"]):
        return "Yes" if candidate_info.get("requires_sponsorship", False) else "No"

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
