## Description
<!-- Provide a concise summary of your changes and why they are necessary. -->

## Type of Change
- [ ] 🚀 New Feature (non-breaking change adding functionality)
- [ ] 🐛 Bug Fix (resolving unexpected behavior or defect)
- [ ] 🛡️ Security / Zero-Knowledge Privacy Improvement
- [ ] 🌐 ATS Driver / Anti-Detection / Playwright Enhancement
- [ ] 🏛️ Architecture / Documentation / ADR update

## Checklist & Architectural Compliance
- [ ] **Zero-Knowledge Architecture**: Confirmed no candidate credentials, personal identity, or resumes leak to third parties or remote logging.
- [ ] **ATS Human-in-the-Loop**: Ensured form fillers only pre-fill fields and do NOT auto-submit without user intervention.
- [ ] **Work Authorization Honesty**: Verified questions concerning jurisdiction/sponsorship accurately match candidate profile without misrepresentation.
- [ ] **Browser Resilience**: Confirmed web demo gracefully handles HTTPS Strict Mixed Content rules without silent failures.
- [ ] **Tests Executed**: Verified all existing unit and integration tests pass cleanly (`flutter test`, `python -m unittest test_server.py`).
- [ ] **ADR Recorded**: Added or updated Architectural Decision Record in `docs/adr/` if design trade-offs were altered.
