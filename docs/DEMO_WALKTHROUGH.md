# 🎬 JOB SeArCh — Demonstrable Reel & Product Walkthrough

This guide serves as a **demonstration reel script and feature walkthrough** for showcasing **JOB SeArCh** in video presentations, portfolio demos, technical reviews, or client demonstrations.

---

## 🌟 Demo Assets & Generated Media

| Asset | Format | Specs | Link |
| :--- | :--- | :--- | :--- |
| **Full Video Reel** | MP4 (H.264 / AAC) | 1080p Full HD, 90.8s, 4.0 MB | [🎬 Watch demo_reel.mp4](assets/demo_reel.mp4) |
| **AI Voiceover Track** | MP3 (192 kbps) | `en-US-ChristopherNeural`, 90.8s | [🎙️ Listen voiceover_demo.mp3](assets/voiceover_demo.mp3) |
| **Hero Dashboard UI** | JPEG | 1920x1080 High Resolution | [🖼️ View hero_dashboard.jpg](assets/hero_dashboard.jpg) |
| **Vault & Scraper UI** | JPEG | 1920x1080 High Resolution | [🖼️ View vault_scraper.jpg](assets/vault_scraper.jpg) |

---

### 1. Marine Glassmorphism Dashboard
![JOB SeArCh Desktop Dashboard](assets/hero_dashboard.jpg)
*Real-time desktop dashboard featuring the Marine Bento Grid, 98% AI Match badges, 2D Latent Space Constellation, and Market Salary Telemetry.*

### 2. Zero-Knowledge Credential Vault & Live ATS Scraper
![Zero-Knowledge Vault & Scraper Interface](assets/vault_scraper.jpg)
*RAM-only isolated credential assistant modal with 1-click auto-fill alongside real-time ATS live stream parsing.*

---

## 🎙️ Official AI Voiceover Transcript (Synchronized in `demo_reel.mp4`)

> *"Welcome to JOB SeArCh — the autonomous AI career discovery and intelligent matching engine.*
> 
> *Traditional job boards are broken — flooded with generic spam, opaque ATS keyword filters, and repetitive forms. JOB SeArCh re-imagines career hunting from the ground up with deep semantic vector search, an adaptive reinforcement learning loop, and a Zero-Knowledge local credential vault.*
> 
> *Our reactive Flutter Web dashboard delivers a bespoke Marine Glassmorphism Bento Grid, presenting real-time market salary telemetry and competitive candidate percentile metrics. Instead of relying on simple keyword matching, candidate profiles and live job listings are projected into a shared 768-dimensional latent space using FastEmbed and pgvector HNSW indexing.*
> 
> *With our interactive 2D Latent Space Constellation, you can explore celestial job clusters, examine cosine similarity fit, and generate instant recruiter outreach pitches.*
> 
> *Need to source roles from anywhere? Our multi-source ATS scraper extracts listings from Greenhouse, Lever, Ashby, or any custom careers URL in seconds.*
> 
> *And when it comes to privacy, our Zero-Knowledge Credential Vault keeps your passwords strictly in browser RAM. No passwords ever touch the server, giving you one-click auto-fill application power.*
> 
> *JOB SeArCh: Autonomous, intelligent, and private career discovery for modern engineers."*

---

## 🎙️ Video / Reel Presentation Script (3-Minute Tour)

### Act 1: The Problem & The Bento Grid (0:00 – 0:45)
- **Visual**: Pan across the high-contrast obsidian navy (`#0A192F`) and electric cyan (`#00E5FF`) glassmorphism interface.
- **Narrative**:
  > *"Modern job hunting is plagued by low-signal spam, uncalibrated ATS keyword filters, and repetitive application forms. Welcome to **JOB SeArCh** — an autonomous AI career engine built with Flutter Web, Python FastAPI, and Supabase pgvector."*
- **Key Actions**:
  1. Highlight the **Bento Hero Card** displaying real-time match metrics ($98\%$ fit score).
  2. Inspect the **Market Salary Telemetry** card comparing current candidate compensation percentiles with active market distributions.

### Act 2: 2D Latent Space Constellation (0:45 – 1:30)
- **Visual**: Hover over the interactive canvas showing the candidate core node and orbiting job clusters.
- **Narrative**:
  > *"Instead of simplistic keyword matching, our engine projects candidates and live job listings into a shared 768-dimensional latent space using FastEmbed and pgvector HNSW indexing. The 2D Constellation lets you visualize semantic proximity in real-time."*
- **Key Actions**:
  1. Click an orbiting celestial node (e.g. *Senior Software Engineer* at *NexaCorp*).
  2. Observe the instant breakdown of **Why It Fits** and **Identified Skill Gaps**.
  3. Click **Generate Recruiter Pitch** to show the AI-synthesized cold email draft.

### Act 3: Live Custom URL Scraper (1:30 – 2:15)
- **Visual**: Click the **Live Scrape** button in the navigation header to open the Scraper modal.
- **Narrative**:
  > *"See an interesting role anywhere on the web? Paste any careers URL — whether it's Ashby, Greenhouse, Lever, or a custom company portal. Our FastAPI microservice crawls the page in milliseconds, extracts salary bands and requirements, and normalizes the job directly into your local feed."*
- **Key Actions**:
  1. Paste a live career URL (e.g. `https://linear.app/careers` or `https://boards.greenhouse.io/figma`).
  2. Watch the live parsing stream populate with job titles, salary estimates, and tag badges.

### Act 4: Zero-Knowledge Client Vault (2:15 – 3:00)
- **Visual**: Open the **Zero-Knowledge Vault** modal with the glowing security shield badge.
- **Narrative**:
  > *"Applying for dozens of jobs usually means re-typing passwords across countless ATS portals. JOB SeArCh solves this with a Zero-Knowledge local credential vault. You import your credentials via CSV, but they exist strictly within browser RAM. No passwords ever touch the server or database. When you click Apply, your credentials auto-copy and the portal opens securely."*
- **Key Actions**:
  1. Drag and drop sample `credentials.csv`.
  2. Demonstrate the 1-click **Apply Assistant** opening the application portal with clipboard auto-fill.
  3. Close or refresh the tab to demonstrate the immediate purge of RAM state.

---

## 🛠️ Reproducing the Live Demo Locally

```bash
# 1. Start Python Backend
cd backend
python -m unittest test_server.py   # Verify backend health (5/5 tests passing)
uvicorn server:app --reload --port 8000

# 2. Start Flutter Web Frontend (in a new terminal)
flutter test                        # Verify frontend unit/widget tests (10/10 passing)
flutter run -d chrome --web-port=5000
```
Visit `http://localhost:5000` to interact with the full live application.
