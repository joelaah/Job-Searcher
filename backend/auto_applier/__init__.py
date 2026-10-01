"""
JOB SeArCh — Auto-Apply Engine Package
═══════════════════════════════════════
Autonomous Playwright-based job application bot.
Fills Greenhouse, Lever, Ashby, and generic ATS forms.
"""

from .engine import run_auto_apply, detect_ats_type, ATSType

__all__ = ["run_auto_apply", "detect_ats_type", "ATSType"]
