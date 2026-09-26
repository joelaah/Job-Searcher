# Graph Report - job searcher  (2026-09-26)

## Corpus Check
- Corpus is ~33,229 words - fits in a single context window. You may not need a graph.

## Summary
- 681 nodes · 1212 edges · 41 communities (39 shown, 2 thin omitted)
- Extraction: 98% EXTRACTED · 2% INFERRED · 0% AMBIGUOUS · INFERRED: 28 edges (avg confidence: 0.9)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Windows Native Shell
- BLoC State Machine
- Bento Grid UI Components
- ATS Scraping Engine
- BLoC State Machine
- ATS Scraping Engine
- BLoC State Machine
- Windows Native Shell
- Subsystem 8
- BLoC State Machine
- 2D Latent Constellation Visualizer
- BLoC State Machine
- Bento Grid UI Components
- Zero-Knowledge Local Vault
- AI Embedding & LLM Scoring
- AI Embedding & LLM Scoring
- FastAPI Backend Service
- Bento Grid UI Components
- Supabase & Vector Tier
- ATS Scraping Engine
- ATS Scraping Engine
- ATS Scraping Engine
- BLoC State Machine
- BLoC State Machine
- BLoC State Machine
- Interactive Modal Workflows
- Zero-Knowledge Local Vault
- Marine Green-Blue Design System
- Bento Grid UI Components
- Candidate Profile & Telemetry
- Bento Grid UI Components
- Bento Grid UI Components
- Supabase & Vector Tier
- Subsystem 33
- BLoC State Machine
- Marine Green-Blue Design System
- Marine Green-Blue Design System
- BLoC State Machine
- Subsystem 38
- BLoC State Machine
- Subsystem 40

## God Nodes (most connected - your core abstractions)
1. `JobBloc` - 91 edges
2. `JobEvent` - 29 edges
3. `Config` - 21 edges
4. `Win32Window` - 21 edges
5. `ScrapedJob` - 14 edges
6. `_AiLearningLoopSectionState` - 14 edges
7. `scrape_all_sources()` - 12 edges
8. `MessageHandler` - 12 edges
9. `get_client()` - 11 edges
10. `SearchQueryChanged` - 10 edges

## Surprising Connections (you probably didn't know these)
- `get_client()` --uses--> `Config`  [INFERRED]
  backend/database.py → backend/config.py
- `generate_embedding()` --uses--> `Config`  [INFERRED]
  backend/embeddings.py → backend/config.py
- `_get_client()` --uses--> `Config`  [INFERRED]
  backend/embeddings.py → backend/config.py
- `_get_client()` --uses--> `Config`  [INFERRED]
  backend/scorer.py → backend/config.py
- `score_job_fit()` --uses--> `Config`  [INFERRED]
  backend/scorer.py → backend/config.py

## Import Cycles
- None detected.

## Communities (41 total, 2 thin omitted)

### Community 0 - "Windows Native Shell"
Cohesion: 0.05
Nodes (59): dwmapi, FlutterViewController, generated_plugin_registrant, optional, RECT, unique_ptr, DartProject, HWND (+51 more)

### Community 1 - "BLoC State Machine"
Cohesion: 0.04
Nodes (46): DateTime?, int get, allJobs, boostedSkills, companyScaleBias, computeSteeredScore, copyWith, filterRemoteOnly (+38 more)

### Community 2 - "Bento Grid UI Components"
Cohesion: 0.05
Nodes (41): accentRed, AppColors, background, bentoBorder, bentoBorderHover, bentoCard, bentoCardElevated, bentoCardGradient (+33 more)

### Community 3 - "ATS Scraping Engine"
Cohesion: 0.09
Nodes (30): AshbyScraper, detect_remote(), extract_salary_range(), GenericWebScraper, GreenhouseScraper, LeverScraper, matches_keywords(), JOB SeArCh — Multi-Source Job Scraper Scrapes jobs from public ATS APIs… (+22 more)

### Community 4 - "BLoC State Machine"
Cohesion: 0.06
Nodes (32): job_event.dart, job_state.dart, calculateBiases, _initialState, _learnFromNegative, _learnFromPositive, _onAddScrapedJobs, _onAddTargetRole (+24 more)

### Community 5 - "ATS Scraping Engine"
Cohesion: 0.12
Nodes (24): Config, Central configuration loaded from environment variables., Returns a list of missing required config keys., Print a human-readable config summary., get_job_count(), get_sources_summary(), Get total number of jobs in the database., Get count of jobs per source. (+16 more)

### Community 6 - "BLoC State Machine"
Cohesion: 0.08
Nodes (24): double?, anonKey, category, companyScale, credentials, delta, domain, fileName (+16 more)

### Community 7 - "Windows Native Shell"
Cohesion: 0.12
Nodes (19): dart_project, flutter_view_controller, flutter_windows, functional, _In_, _In_opt_, io, iostream (+11 more)

### Community 8 - "Subsystem 8"
Cohesion: 0.08
Nodes (23): applicationUrl, company, companyLogo, copyWith, currency, fromScrapedJson, fullDescription, id (+15 more)

### Community 9 - "BLoC State Machine"
Cohesion: 0.18
Nodes (20): @immutable, AddTargetRole, DismissJob, JobEvent, MinSalaryChanged, RemoveTargetRole, ResetCareerAlignment, ResetSteeringBiases (+12 more)

### Community 10 - "2D Latent Constellation Visualizer"
Cohesion: 0.10
Nodes (19): CustomPainter, dart:math, _animController, animProgress, build, _ConstellationPainter, createState, dispose (+11 more)

### Community 11 - "BLoC State Machine"
Cohesion: 0.25
Nodes (18): Bloc, JobBloc, CategoryChanged, FilterRemoteOnlyToggled, MarkJobApplied, MinMatchScoreChanged, SearchQueryChanged, SupabaseConfigured (+10 more)

### Community 12 - "Bento Grid UI Components"
Cohesion: 0.13
Nodes (14): Animation, AnimationController, latent_space_constellation.dart, build, _buildConstellationCard, _buildFilterBadge, _buildMetricRow, _buildTerminalLine (+6 more)

### Community 13 - "Zero-Knowledge Local Vault"
Cohesion: 0.16
Nodes (14): argparse, find_matching_credential(), load_credentials_from_csv(), main(), JOB SeArCh — Local Zero-Knowledge Application & Auto-Fill Assistant…, Parse local CSV credentials file., Find the credential entry matching the job URL's domain., Launch local browser session with autofill support. (+6 more)

### Community 14 - "AI Embedding & LLM Scoring"
Cohesion: 0.17
Nodes (13): JOB SeArCh — Configuration Loader Loads environment variables and provides…, batch_score_jobs(), _fallback_score(), _get_client(), Client, JOB SeArCh — LLM Match Scorer Uses Gemini Flash (free tier) to generate human-…, Fallback when LLM is unavailable — use raw cosine similarity., Score the top N jobs from a vector search result. Only the top matches get LLM… (+5 more)

### Community 15 - "AI Embedding & LLM Scoring"
Cohesion: 0.16
Nodes (14): embed_job_description(), embed_resume(), generate_embedding(), _get_client(), Client, JOB SeArCh — Embedding Generator Uses Google Gemini's free-tier text-…, Generate an optimized embedding for a user's resume. Prepends a task…, Generate an optimized embedding for a job description. (+6 more)

### Community 16 - "FastAPI Backend Service"
Cohesion: 0.16
Nodes (14): api_scrape_all(), api_scrape_url(), health_check(), HealthResponse, JOB SeArCh — FastAPI Backend Server Provides REST endpoints for live job…, ScrapeUrlRequest, BaseModel, fastapi (+6 more)

### Community 17 - "Bento Grid UI Components"
Cohesion: 0.13
Nodes (14): build, _buildBentoJobsGrid, _buildFeaturedBentoDeck, _buildResultsHeader, _buildTopBentoDeck, ../widgets/ai_learning_loop_section.dart, ../widgets/bento_filter_strip.dart, ../widgets/bento_hero_job_card.dart (+6 more)

### Community 18 - "Supabase & Vector Tier"
Cohesion: 0.19
Nodes (13): get_client(), get_user_interactions(), log_interaction(), match_jobs_for_resume(), Client, JOB SeArCh — Supabase Database Client Handles all database operations: storing…, Store or update a user's profile and resume embedding., Log a user interaction for the learning feedback loop. interaction_type must be… (+5 more)

### Community 19 - "ATS Scraping Engine"
Cohesion: 0.15
Nodes (12): custom_scraper_dialog.dart, learning_insights_modal.dart, JobSearchApp, BentoMarketInsightsCard, BentoPipelineCard, build, BentoTelemetryCard, build (+4 more)

### Community 20 - "ATS Scraping Engine"
Cohesion: 0.14
Nodes (13): dart:convert, build, createState, _directPublicAtsScrape, dispose, _errorMessage, _isLoading, _presetChip (+5 more)

### Community 21 - "ATS Scraping Engine"
Cohesion: 0.19
Nodes (14): AiLearningLoopSection, CustomScraperDialog, _CustomScraperDialogState, JobDetailDialog, _JobDetailDialogState, LatentSpaceConstellation, _LatentSpaceConstellationState, ResumeUploadCard (+6 more)

### Community 22 - "BLoC State Machine"
Cohesion: 0.18
Nodes (12): job_detail_dialog.dart, ToggleSaveJob, build, build, build, createState, _getScoreColor, _isHovered (+4 more)

### Community 23 - "BLoC State Machine"
Cohesion: 0.24
Nodes (8): ../bloc/job_bloc.dart, Color, build, build, _buildStatBadge, build, LearningInsightsModal, ../theme/app_colors.dart

### Community 24 - "BLoC State Machine"
Cohesion: 0.20
Nodes (9): ../bloc/job_event.dart, ../bloc/job_state.dart, _buildScoreSlider, build, createState, _handleFilePick, _isProcessing, _processingStage (+1 more)

### Community 25 - "Interactive Modal Workflows"
Cohesion: 0.18
Nodes (10): build, _copyToClipboard, createState, dispose, _getScoreColor, initState, job, _launchUrl (+2 more)

### Community 26 - "Zero-Knowledge Local Vault"
Cohesion: 0.18
Nodes (10): createState, _csvController, dispose, _launchApplicationWithCredentials, _loadSampleCsv, _revealedPasswords, _sampleCsv, _selectedJobForApply (+2 more)

### Community 27 - "Marine Green-Blue Design System"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 28 - "Bento Grid UI Components"
Cohesion: 0.22
Nodes (9): JobModel, BentoHeroJobCard, _BentoHeroJobCardState, createState, _isHovered, job, _openDetailDialog, ../models/local_credential.dart (+1 more)

### Community 29 - "Candidate Profile & Telemetry"
Cohesion: 0.20
Nodes (9): copyWith, fromMap, LocalCredential, loginUrl, notes, password, platform, resumePath (+1 more)

### Community 30 - "Bento Grid UI Components"
Cohesion: 0.22
Nodes (9): BentoJobCard, _BentoJobCardState, createState, _getScoreColor, _isHovered, job, _openDetailDialog, ../models/job_model.dart (+1 more)

### Community 31 - "Bento Grid UI Components"
Cohesion: 0.22
Nodes (8): build, _buildPresetOption, createState, _handleFilePick, _isProcessing, _processingStage, _showResumeSelectionDialog, _startProcessingSimulation

### Community 32 - "Supabase & Vector Tier"
Cohesion: 0.25
Nodes (7): build, createState, dispose, initState, _keyController, _urlController, TextEditingController

### Community 33 - "Subsystem 33"
Cohesion: 0.29
Nodes (5): app_links_plugin_c_api, plugin_registry, PluginRegistry, url_launcher_windows, RegisterPlugins()

### Community 34 - "BLoC State Machine"
Cohesion: 0.40
Nodes (6): ClearLocalCredentials, DeleteLocalCredential, ImportLocalCredentials, build, _parseAndImportCsv, _ZeroKnowledgeVaultDialogState

### Community 35 - "Marine Green-Blue Design System"
Cohesion: 0.33
Nodes (5): build, main, package:flutter_bloc/flutter_bloc.dart, screens/home_screen.dart, theme/app_theme.dart

### Community 36 - "Marine Green-Blue Design System"
Cohesion: 0.40
Nodes (4): app_colors.dart, AppTheme, package:flutter/material.dart, package:google_fonts/google_fonts.dart

### Community 37 - "BLoC State Machine"
Cohesion: 0.50
Nodes (4): ResumeUploaded, BentoProfileCard, _BentoProfileCardState, _startProcessingSimulation

### Community 38 - "Subsystem 38"
Cohesion: 0.50
Nodes (3): package:flutter_test/flutter_test.dart, package:job_searcher/main.dart, main

## Knowledge Gaps
- **277 isolated node(s):** `_onAddTargetRole`, `_onRemoveTargetRole`, `_onAddScrapedJobs`, `_onImportLocalCredentials`, `_onDeleteLocalCredential` (+272 more)
  These have ≤1 connection - possible missing edges. (Counts symbols only; 414 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `JobBloc` connect `BLoC State Machine` to `BLoC State Machine`, `BLoC State Machine`, `2D Latent Constellation Visualizer`, `Bento Grid UI Components`, `Bento Grid UI Components`, `ATS Scraping Engine`, `ATS Scraping Engine`, `ATS Scraping Engine`, `BLoC State Machine`, `BLoC State Machine`, `BLoC State Machine`, `Interactive Modal Workflows`, `Zero-Knowledge Local Vault`, `Bento Grid UI Components`, `Bento Grid UI Components`, `Bento Grid UI Components`, `Supabase & Vector Tier`, `BLoC State Machine`, `BLoC State Machine`, `BLoC State Machine`?**
  _High betweenness centrality (0.109) - this node is a cross-community bridge._
- **Why does `JobModel` connect `Bento Grid UI Components` to `Subsystem 8`, `2D Latent Constellation Visualizer`, `BLoC State Machine`, `Interactive Modal Workflows`, `Zero-Knowledge Local Vault`, `Bento Grid UI Components`?**
  _High betweenness centrality (0.022) - this node is a cross-community bridge._
- **Why does `Config` connect `ATS Scraping Engine` to `Supabase & Vector Tier`, `ATS Scraping Engine`, `AI Embedding & LLM Scoring`, `AI Embedding & LLM Scoring`?**
  _High betweenness centrality (0.011) - this node is a cross-community bridge._
- **Are the 12 inferred relationships involving `Config` (e.g. with `get_client()` and `generate_embedding()`) actually correct?**
  _`Config` has 12 INFERRED edges - model-reasoned connections that need verification._
- **What connects `_onAddTargetRole`, `_onRemoveTargetRole`, `_onAddScrapedJobs` to the rest of the system?**
  _277 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Windows Native Shell` be split into smaller, more focused modules?**
  _Cohesion score 0.05268065268065268 - nodes in this community are weakly interconnected._
- **Should `BLoC State Machine` be split into smaller, more focused modules?**
  _Cohesion score 0.0425531914893617 - nodes in this community are weakly interconnected._