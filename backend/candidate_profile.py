"""
JOB SeArCh — Candidate Profile Loader
══════════════════════════════════════
Loads candidate_profile.yaml from the backend directory and provides
structured access for the auto-apply engine.

Zero-Knowledge: Profile data never leaves the local machine.
"""

import os
import yaml
from dataclasses import dataclass, field
from typing import Optional


PROFILE_PATH = os.path.join(os.path.dirname(__file__), "candidate_profile.yaml")


@dataclass
class Education:
    school: str = ""
    degree: str = ""
    graduation_year: str = ""
    gpa: str = ""


@dataclass
class WorkAuth:
    authorized_to_work: bool = True
    requires_sponsorship: bool = False
    country: str = "United States"
    authorized_in_us: bool = False
    requires_us_sponsorship: bool = True
    authorized_countries: list[str] = field(default_factory=lambda: ["India"])


@dataclass
class EEO:
    gender: str = "Decline to self-identify"
    race_ethnicity: str = "Decline to self-identify"
    veteran_status: str = "I am not a protected veteran"
    disability_status: str = "I don't wish to answer"


@dataclass
class Preferences:
    min_salary: int = 0
    willing_to_relocate: bool = True
    remote_preference: str = "remote"
    notice_period: str = "2 weeks"
    years_of_experience: int = 0


@dataclass
class CandidateProfile:
    """Full candidate application profile loaded from local YAML."""

    # Personal
    first_name: str = ""
    last_name: str = ""
    full_name: str = ""
    email: str = ""
    phone: str = ""
    location: str = ""
    address: str = ""
    current_company: str = ""
    current_title: str = ""
    pronouns: str = ""

    # Links
    linkedin_url: str = ""
    github_url: str = ""
    portfolio_url: str = ""
    website_url: str = ""
    twitter_url: str = ""

    # Resume
    resume_path: str = ""
    default_cover_letter: str = ""

    # Structured sections
    education: list[Education] = field(default_factory=list)
    work_auth: WorkAuth = field(default_factory=WorkAuth)
    eeo: EEO = field(default_factory=EEO)
    preferences: Preferences = field(default_factory=Preferences)

    # Custom Q&A bank
    custom_answers: dict[str, str] = field(default_factory=dict)

    def __post_init__(self):
        """Auto-compute full_name if not explicitly set."""
        if not self.full_name and (self.first_name or self.last_name):
            self.full_name = f"{self.first_name} {self.last_name}".strip()

    @property
    def has_resume(self) -> bool:
        return bool(self.resume_path) and os.path.exists(self.resume_path)

    @property
    def is_configured(self) -> bool:
        """Check if minimum required fields are filled."""
        return bool(self.full_name and self.email)

    def to_form_dict(self) -> dict:
        """Flatten profile into a dictionary suitable for form-filling."""
        return {
            "first_name": self.first_name,
            "last_name": self.last_name,
            "full_name": self.full_name,
            "email": self.email,
            "phone": self.phone,
            "location": self.location,
            "address": self.address,
            "current_company": self.current_company,
            "current_title": self.current_title,
            "pronouns": self.pronouns,
            "linkedin_url": self.linkedin_url,
            "github_url": self.github_url,
            "portfolio_url": self.portfolio_url,
            "website_url": self.website_url,
            "twitter_url": self.twitter_url,
            "resume_path": self.resume_path,
            "authorized_to_work": self.work_auth.authorized_to_work,
            "requires_sponsorship": self.work_auth.requires_sponsorship,
            "work_auth_country": self.work_auth.country,
            "authorized_in_us": self.work_auth.authorized_in_us,
            "requires_us_sponsorship": self.work_auth.requires_us_sponsorship,
            "authorized_countries": self.work_auth.authorized_countries,
            "years_of_experience": self.preferences.years_of_experience,
            "min_salary": self.preferences.min_salary,
            "notice_period": self.preferences.notice_period,
            "gender": self.eeo.gender,
            "race_ethnicity": self.eeo.race_ethnicity,
            "veteran_status": self.eeo.veteran_status,
            "disability_status": self.eeo.disability_status,
        }


def load_profile(path: str = PROFILE_PATH) -> CandidateProfile:
    """Load candidate profile from YAML file."""
    if not os.path.exists(path):
        print(f"[Profile] No profile found at {path}. Using empty profile.")
        return CandidateProfile()

    with open(path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}

    user = data.get("user", {})
    edu_list = data.get("education", [])
    work_auth_data = data.get("work_authorization", {})
    eeo_data = data.get("eeo", {})
    prefs_data = data.get("preferences", {})
    custom_answers = data.get("custom_answers", {})

    # Parse education entries
    education = []
    for entry in (edu_list or []):
        if isinstance(entry, dict) and any(entry.values()):
            education.append(Education(
                school=str(entry.get("school", "")),
                degree=str(entry.get("degree", "")),
                graduation_year=str(entry.get("graduation_year", "")),
                gpa=str(entry.get("gpa", "")),
            ))

    profile = CandidateProfile(
        first_name=str(user.get("first_name", "")),
        last_name=str(user.get("last_name", "")),
        full_name=str(user.get("full_name", "")),
        email=str(user.get("email", "")),
        phone=str(user.get("phone", "")),
        location=str(user.get("location", "")),
        address=str(user.get("address", "")),
        current_company=str(user.get("current_company", "")),
        current_title=str(user.get("current_title", "")),
        pronouns=str(user.get("pronouns", "")),
        linkedin_url=str(user.get("linkedin_url", "")),
        github_url=str(user.get("github_url", "")),
        portfolio_url=str(user.get("portfolio_url", "")),
        website_url=str(user.get("website_url", "")),
        twitter_url=str(user.get("twitter_url", "")),
        resume_path=str(user.get("resume_path", "")),
        default_cover_letter=str(user.get("default_cover_letter", "")),
        education=education,
        work_auth=WorkAuth(
            authorized_to_work=bool(work_auth_data.get("authorized_to_work", True)),
            requires_sponsorship=bool(work_auth_data.get("requires_sponsorship", False)),
            country=str(work_auth_data.get("country", "India")),
            authorized_in_us=bool(work_auth_data.get("authorized_in_us", work_auth_data.get("country", "") == "United States")),
            requires_us_sponsorship=bool(work_auth_data.get("requires_us_sponsorship", work_auth_data.get("country", "") != "United States")),
            authorized_countries=list(work_auth_data.get("authorized_countries", [work_auth_data.get("country", "India")])),
        ),
        eeo=EEO(
            gender=str(eeo_data.get("gender", "Decline to self-identify")),
            race_ethnicity=str(eeo_data.get("race_ethnicity", "Decline to self-identify")),
            veteran_status=str(eeo_data.get("veteran_status", "I am not a protected veteran")),
            disability_status=str(eeo_data.get("disability_status", "I don't wish to answer")),
        ),
        preferences=Preferences(
            min_salary=int(prefs_data.get("min_salary", 0)),
            willing_to_relocate=bool(prefs_data.get("willing_to_relocate", True)),
            remote_preference=str(prefs_data.get("remote_preference", "remote")),
            notice_period=str(prefs_data.get("notice_period", "2 weeks")),
            years_of_experience=int(prefs_data.get("years_of_experience", 0)),
        ),
        custom_answers={
            str(k): str(v) for k, v in (custom_answers or {}).items() if v
        },
    )

    return profile


def save_profile(profile: CandidateProfile, path: str = PROFILE_PATH) -> None:
    """Save candidate profile back to YAML file."""
    data = {
        "user": {
            "first_name": profile.first_name,
            "last_name": profile.last_name,
            "full_name": profile.full_name,
            "email": profile.email,
            "phone": profile.phone,
            "location": profile.location,
            "address": profile.address,
            "current_company": profile.current_company,
            "current_title": profile.current_title,
            "pronouns": profile.pronouns,
            "linkedin_url": profile.linkedin_url,
            "github_url": profile.github_url,
            "portfolio_url": profile.portfolio_url,
            "website_url": profile.website_url,
            "twitter_url": profile.twitter_url,
            "resume_path": profile.resume_path,
            "default_cover_letter": profile.default_cover_letter,
        },
        "education": [
            {
                "school": e.school,
                "degree": e.degree,
                "graduation_year": e.graduation_year,
                "gpa": e.gpa,
            }
            for e in profile.education
        ],
        "work_authorization": {
            "authorized_to_work": profile.work_auth.authorized_to_work,
            "requires_sponsorship": profile.work_auth.requires_sponsorship,
            "country": profile.work_auth.country,
            "authorized_in_us": profile.work_auth.authorized_in_us,
            "requires_us_sponsorship": profile.work_auth.requires_us_sponsorship,
            "authorized_countries": profile.work_auth.authorized_countries,
        },
        "eeo": {
            "gender": profile.eeo.gender,
            "race_ethnicity": profile.eeo.race_ethnicity,
            "veteran_status": profile.eeo.veteran_status,
            "disability_status": profile.eeo.disability_status,
        },
        "preferences": {
            "min_salary": profile.preferences.min_salary,
            "willing_to_relocate": profile.preferences.willing_to_relocate,
            "remote_preference": profile.preferences.remote_preference,
            "notice_period": profile.preferences.notice_period,
            "years_of_experience": profile.preferences.years_of_experience,
        },
        "custom_answers": profile.custom_answers,
    }

    with open(path, "w", encoding="utf-8") as f:
        yaml.dump(data, f, default_flow_style=False, allow_unicode=True, sort_keys=False)

    print(f"[Profile] Saved profile to {path}")
