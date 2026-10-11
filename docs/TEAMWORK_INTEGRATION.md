# Automated CI/CD Pairing Partner & Multi-Agent Swarm

## Overview

**JOB SeArCh** integrates an automated **15-Agent Swarm** located in `.agents/teamwork/` designed to act as an autonomous **CI/CD Pairing Partner** alongside human maintainers.

The swarm operates on continuous verification, adversarial testing, code reality checks, and architectural integrity audits.

---

## 🐝 Swarm Structure & Roles

The 15 agents specialize in distinct phases of the software development lifecycle:

| Agent / Persona | Core Responsibility | Verification Protocol |
| :--- | :--- | :--- |
| **Architect** | High-level system design & ADR compliance | Audits alignment between code and design specs |
| **Security Sentinel** | Zero-Knowledge protection & credential safety | Verifies RAM isolation & credential leak prevention |
| **Stealth Navigator** | Bot mitigation & anti-detection (Cloudflare/Turnstile) | Tests browser fingerprinting evasion & headless flags |
| **ATS Ethicist** | Work authorization accuracy & legal EEO compliance | Validates honest candidate representation on forms |
| **Web Resilience Lead** | Mixed Content, CORS, and PNA compliance | Tests HTTPS web demo on modern browser engines |
| **BLoC Strategist** | State machine reactivity & stream hygiene | Enforces event-driven state immutability in Flutter |
| **Vector Specialist** | Dense embedding pipelines & pgvector queries | Monitors FastEmbed 768-D indexing & cosine similarity |
| **Scraper Engineer** | Resilient extraction across Ashby, Greenhouse, Lever | Validates JSON/HTML parsing and rate-limit backoffs |
| **Quality Guardian** | Comprehensive unit & integration testing | Prevents test weakening and ensures test suite passage |
| **Adversarial Red Team**| Edge case stress-testing & boundary failures | Tests negative inputs, malformed URLs, SSRF attempts |
| **Documentation Pair** | Synchronized README, API specs, and ADR records | Keeps developer documentation in lockstep with code |
| **Performance Profiler**| Sub-16ms UI frame rate & low API latency | Audits canvas rendering & database query execution |
| **Dependency Auditor**| Python & Flutter package security and versions | Scans for vulnerable dependencies & version skew |
| **Release Coordinator**| GitHub Pages build artifacts & changelogs | Validates deployment assets and web artifact bundle |
| **Human Pairing Lead** | Maintains human-in-the-loop oversight & approvals | Ensures autonomous actions always defer to user approval |

---

## 🔄 Interaction Workflow

1. **Autonomous Pre-Commit Review**:
   Whenever changes are made to ATS drivers or candidate profiles, the **Stealth Navigator** and **ATS Ethicist** review changes against Turnstile bot heuristics and work authorization accuracy.
2. **Adversarial Stress Testing**:
   The **Adversarial Red Team** executes boundary tests against endpoints (e.g. `test_server.py` SSRF prevention, empty payloads, 429 rate limit triggers).
3. **Architectural Verification**:
   The **Architect** verifies that any behavioral change is documented in an ADR under `docs/adr/` and accurately described in `README.md`.
4. **Final Gatekeeping**:
   Form submissions are permanently gatekept by the **Human Pairing Lead** — the system will only ever prepare forms for final human review.
