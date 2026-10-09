# ADR 0001: Zero-Knowledge Local Candidate Profile & Credential Storage

## Status
Accepted

## Context
Job applications require sensitive personal data: candidate resumes, phone numbers, email addresses, salary expectations, EEO demographic answers, and ATS platform credentials. Storing this information in a centralized SaaS database or transmitting it over external APIs introduces severe privacy, compliance (GDPR/CCPA), and security risks.

## Decision
All candidate information and application credentials are kept strictly **Zero-Knowledge**:
1. Profile details reside in a local YAML configuration (`backend/candidate_profile.yaml`) on the applicant's machine.
2. In-browser credential storage (Bento Vault) operates in ephemeral memory (RAM heap), never writing passwords to disk or syncing with external databases.
3. Plaintext passwords are not copied indiscriminately to OS clipboards during routine operations.

## Consequences
- **Positive**: Complete user privacy and zero risk of centralized data breach or credential leak.
- **Negative**: Profiles do not automatically synchronize across devices without user-managed backups or secure file transfers.
