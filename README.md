# 🚀 JOB SeArCh — Autonomous AI Job Hunting & Semantic Matching Engine

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x%20Web-02569B?logo=flutter&logoColor=white" alt="Flutter Web" />
  <img src="https://img.shields.io/badge/Python-3.12%20FastAPI-009688?logo=fastapi&logoColor=white" alt="FastAPI" />
  <img src="https://img.shields.io/badge/Supabase-pgvector-3ECF8E?logo=supabase&logoColor=white" alt="Supabase" />
  <img src="https://img.shields.io/badge/AI-Google%20Gemini-4285F4?logo=google&logoColor=white" alt="Gemini" />
  <img src="https://img.shields.io/badge/Zero--Knowledge-Client--Side%20Vault-FF6F00?logo=security&logoColor=white" alt="Security" />
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License" />
</p>

---

## 🌟 Executive Overview
**JOB SeArCh** is an intelligent, privacy-first career discovery and automated application system. Built for modern engineers, it eliminates generic job board spam by combining **deep semantic vector search**, an **adaptive reinforcement learning loop**, and a **Zero-Knowledge local credential vault** for rapid, private job applications.

Rather than relying on basic keyword matching, the engine projects candidate resumes and real-time scraped job postings into a shared **768-dimensional latent space**, calculating genuine contextual fit, identifying skill gaps, and generating personalized recruiter pitches.

---

## 📸 Key Features & Architecture

```
                          ┌─────────────────────────────────────┐
                          │   Flutter Web Reactive Bento Grid   │
                          │   (BLoC State Machine + Marine UI)  │
                          └──────────────────┬──────────────────┘
                                             │
               ┌─────────────────────────────┼─────────────────────────────┐
               ▼                             ▼                             ▼
┌─────────────────────────────┐┌───────────────────────────┐┌─────────────────────────────┐
│ Zero-Knowledge Local Vault  ││ ATS Real-Time Web Scraper ││   2D Latent Constellation   │
│ Client-side RAM-only CSV    ││ Ashby, Greenhouse, Lever  ││ Dynamic Semantic Distance   │
│ autofill & auto-clipboard   ││ + Live URL Parser (Python)││ Real-time Bias Projection   │
└─────────────────────────────┘└─────────────┬─────────────┘└─────────────────────────────┘
                                             │
                                             ▼
                              ┌─────────────────────────────┐
                              │  Supabase + pgvector Cloud  │
                              │  768-dim HNSW Cosine Index  │
                              │  Gemini Flash Reranking     │
                              └─────────────────────────────┘
```

### 1. 🎨 Marine Glassmorphism Bento Grid
- **Modern Design System**: Tailored dark-mode glassmorphism (`#0A192F` navy base with `#00E5FF` electric cyan and `#26A69A` seafoam green accents).
- **Telemetry & Market Intelligence**: Real-time salary distributions, candidate percentile rankings, and competitive remote liquidity metrics.
- **2D Latent Space Visualizer**: Interactive canvas showing cosine proximity between the candidate vector and live job clusters.

### 2. 🛡️ Zero-Knowledge Local Credential Vault
- **Client-Side Privacy**: Candidates can import their job application credentials (usernames, passwords, platform URLs, notes) via CSV.
- **RAM-Only Isolation**: Credentials exist strictly within the browser memory and are **never transmitted** to the backend, database, or third parties.
- **1-Click Auto-Fill Assistant**: Clicking "Apply" automatically detects the target platform, matches domain credentials, copies sensitive fields to the clipboard, and opens the direct application portal.

### 3. 🕷️ Multi-Source Live ATS Scraper Engine
- **Direct ATS Integration**: Fast headless extraction for **Ashby**, **Greenhouse**, and **Lever** public APIs.
- **Custom Career Page Scraper**: Users can paste any company careers URL (e.g. `https://linear.app/careers`) to scrape, parse salary bands, and score fit in real-time.
- **Smart Keyword & Location Filtering**: Automatically filters out stale postings and normalizes currency ranges.

### 4. 🧠 AI Semantic Matching & Adaptive Steering
- **Dual-Stage Matching**:
  - *Stage 1*: Fast vector search via `pgvector` HNSW cosine similarity.
  - *Stage 2*: Re-ranking and rationale generation via **Google Gemini Flash**.
- **Continuous Learning Loop**: Every candidate interaction (*Saved*, *Applied*, *Dismissed*) dynamically recalculates domain biases, tech-stack affinities, and seniority steering vectors in real time.
- **1-Click Tailored Outreach**: Instantly generates customized cover letters and LinkedIn recruiter cold messages based on mutual skill intersections.

---

## 🛠️ Technology Stack

| Layer | Technologies |
| :--- | :--- |
| **Frontend Web** | Flutter Web, Dart, `flutter_bloc`, `google_fonts`, Glassmorphism CSS |
| **Backend API** | Python 3.12, FastAPI, Uvicorn, Pydantic, Requests |
| **Database & Vector Tier** | Supabase, PostgreSQL 15, `pgvector`, HNSW Indexing |
| **AI & Embeddings** | Google Gemini (`text-embedding-004`, Gemini 1.5 Flash) |
| **Scraping Engine** | BeautifulSoup4, lxml, Async HTTP |
| **DevOps & CI/CD** | GitHub Actions, GitHub Pages Web Pipeline |

---

## 📂 Project Structure

```
job-searcher/
├── .github/workflows/          # GitHub Actions CI/CD (Pages deployment)
├── backend/
│   ├── scraper.py              # Ashby, Greenhouse, Lever & Generic Scrapers
│   ├── database.py             # Supabase pgvector client & telemetry logging
│   ├── db_schema.sql           # PostgreSQL DDL, HNSW index & similarity RPC
│   ├── embeddings.py           # Gemini 768-dim embedding generator
│   ├── scorer.py               # Gemini LLM match rationale & pitch generator
│   ├── local_auto_apply.py     # Local zero-knowledge credential assistant
│   └── main.py                 # FastAPI REST API endpoints
├── lib/
│   ├── bloc/                   # BLoC state machine (JobBloc, JobEvent, JobState)
│   ├── models/                 # JobModel, UserProfile, LocalCredential
│   ├── theme/                  # Marine green-blue color tokens & typography
│   ├── widgets/                # Bento grid cards, Latent Space visualizer, Vault
│   └── main.dart               # Flutter application entrypoint
├── web/                        # Web manifest, index.html, and canvas renderer
└── pubspec.yaml                # Flutter project dependencies
```

---

## 🚀 Getting Started Locally

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.22+ recommended)
- [Python](https://www.python.org/) 3.10+
- Free [Supabase Account](https://supabase.com/) & [Google AI Studio Key](https://aistudio.google.com/apikey)

### 1. Clone the Repository
```bash
git clone https://github.com/joelaah/job-searcher.git
cd job-searcher
```

### 2. Configure Environment Variables
Copy `.env.example` in the `backend/` directory:
```bash
cp backend/.env.example backend/.env
```
Fill in your credentials:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-supabase-anon-or-secret-key
GEMINI_API_KEY=your-gemini-api-key
```

### 3. Initialize the Database
Open your Supabase **SQL Editor**, paste the contents of [`backend/db_schema.sql`](backend/db_schema.sql), and click **Run**.

### 4. Start the Python Scraper Backend
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### 5. Launch the Flutter Web Frontend
```bash
# In the root directory
flutter pub get
flutter run -d web-server --web-port=5000
```
Open **`http://localhost:5000/`** in your browser.

---

## 🌐 Deploy to GitHub Pages

This repository is pre-configured with a **GitHub Actions workflow** (`.github/workflows/deploy.yml`). 
Whenever you push to the `main` or `master` branch:
1. Flutter compiles the web bundle in release mode with HTML renderer optimization.
2. The compiled assets are automatically published to **GitHub Pages**.
3. Live URL: `https://joelaah.github.io/job-searcher/`

---

## 🔒 Security & Privacy Notice
- No candidate passwords or credentials uploaded through the **Zero-Knowledge Vault** are ever saved to disk or sent to any server. All credentials exist only in browser memory and are cleared when the tab is closed.
- The `.gitignore` file strictly prohibits committing `.env` files or sensitive API keys.

---

## 📄 License
This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
