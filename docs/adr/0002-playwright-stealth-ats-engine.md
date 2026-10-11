# ADR 0002: Playwright Stealth Browser Automation & ATS Form Drivers

## Status
Accepted

## Context
Modern Applicant Tracking Systems (Ashby, Greenhouse, Lever) deploy advanced bot-detection systems, notably Cloudflare Turnstile, browser fingerprinting, and behavioral checks. Naive automation scripts (e.g., standard Playwright with `navigator.webdriver = undefined`) are immediately detected by Cloudflare Turnstile challenges, blocking form access or triggering ATS shadow-banning.

Additionally, fully autonomous form submission risks incorrect answers or candidate misrepresentation (e.g. visa sponsorship status).

## Decision
1. **Stealth Evasion**: Inject comprehensive prototype-level overrides before script execution, including:
   - Prototype descriptor removal of `navigator.webdriver`
   - Complete `window.chrome` runtime and app object mocks
   - Realistic `navigator.plugins` (PDF Viewer plugin suite) and `navigator.languages`
   - WebGL renderer/vendor spoofing to prevent SwiftShader detection
   - Realistic browser launch flags (`--disable-blink-features=AutomationControlled`, `--disable-infobars`)
2. **Turnstile Handling**: Actively detect Cloudflare Turnstile iframes and challenge tokens (`cf-turnstile-response`), logging challenge status and falling back to human verification when needed.
3. **Human-in-the-Loop Protocol**: The engine **only fills fields** and takes a verification screenshot. It **never clicks submit**. Final review and submission are exclusively performed by the human applicant.
4. **Jurisdiction-Aware Screening**: Automatically detect question context (e.g., United States vs. international work authorization) and verify candidate residency to eliminate ATS blacklisting from false representations.

## Consequences
- **Positive**: High pass rate through modern bot detection systems without shadow-banning; 100% human accountability for submitted job applications.
- **Negative**: Requires local Playwright installation and headless/headful browser resources on candidate hardware.
