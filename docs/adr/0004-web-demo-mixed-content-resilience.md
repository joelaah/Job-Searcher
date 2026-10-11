# ADR 0004: Web Demo Mixed Content Resilience

## Status
Accepted

## Context
When hosting the web build on GitHub Pages (`https://joelaah.github.io/Job-Searcher/`), the origin is served strictly over HTTPS. Modern browsers enforce **Strict Mixed Content Blocking** and **Private Network Access (PNA)** rules:
- Any active network request (`fetch`, `XMLHttpRequest`, `http.post`) from an HTTPS page to an insecure HTTP loopback address (`http://localhost:8000` or `http://127.0.0.1:8000`) is rejected by browser security policies.
- In client applications, this previously caused silent failure or generic connection errors (`ClientException: XMLHttpRequest error`).

## Decision
1. **Origin Scheme Detection**:
   The Flutter client detects whether it is running on the web (`kIsWeb`) and loaded over an HTTPS origin (`Uri.base.scheme == 'https'`).
2. **Graceful Fallback & Simulation**:
   - If running on HTTPS without a user-configured HTTPS backend endpoint (via `BACKEND_URL` environment flag), the client bypasses insecure loopback requests.
   - For auto-apply, it runs a transparent **Interactive Web Demo Simulation**, logging step-by-step progress and informing the user how to run the full Playwright engine locally.
   - For custom URL scraping, it directly contacts public ATS endpoints (e.g. Ashby, Greenhouse, and Lever public JSON APIs) rather than failing against an unreachable local server.
3. **Transparent Messaging**:
   Connection errors specifically differentiate between "Backend Unreachable" and "Strict Mixed Content Blocked by Browser Policy", giving actionable guidance to the user.

## Consequences
- **Positive**: Zero silent failures, zero console mixed-content errors, and a smooth demo experience for visitors on GitHub Pages.
- **Negative**: Users testing the live web demo cannot trigger a local Python Playwright instance without either running the web app locally over HTTP or serving the backend through a secure HTTPS tunnel (e.g., ngrok/Cloudflare Tunnel).
