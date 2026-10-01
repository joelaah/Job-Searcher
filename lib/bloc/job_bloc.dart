import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../models/job_model.dart';
import '../models/user_profile.dart';
import '../models/local_credential.dart';
import 'job_event.dart';
import 'job_state.dart';


class JobBloc extends Bloc<JobEvent, JobState> {
  JobBloc() : super(_initialState()) {
    on<SearchQueryChanged>(_onSearchQueryChanged);
    on<FilterRemoteOnlyToggled>(_onFilterRemoteOnlyToggled);
    on<MinMatchScoreChanged>(_onMinMatchScoreChanged);
    on<MinSalaryChanged>(_onMinSalaryChanged);
    on<CategoryChanged>(_onCategoryChanged);
    on<ToggleSaveJob>(_onToggleSaveJob);
    on<MarkJobApplied>(_onMarkJobApplied);
    on<DismissJob>(_onDismissJob);
    on<ResumeUploaded>(_onResumeUploaded);
    on<SupabaseConfigured>(_onSupabaseConfigured);
    on<SimulateVectorShift>(_onSimulateVectorShift);
    on<ResetVectorShift>(_onResetVectorShift);
    on<SteeringBiasChanged>(_onSteeringBiasChanged);
    on<ResetSteeringBiases>(_onResetSteeringBiases);
    on<SyncSteeringToResume>(_onSyncSteeringToResume);
    on<ToggleDomainFilter>(_onToggleDomainFilter);
    on<ToggleCompanyStageFilter>(_onToggleCompanyStageFilter);
    on<ToggleSeniorityFilter>(_onToggleSeniorityFilter);
    on<ToggleSkillBoost>(_onToggleSkillBoost);
    on<ResetCareerAlignment>(_onResetCareerAlignment);
    on<AddTargetRole>(_onAddTargetRole);
    on<RemoveTargetRole>(_onRemoveTargetRole);
    on<AddScrapedJobs>(_onAddScrapedJobs);
    on<ImportLocalCredentials>(_onImportLocalCredentials);
    on<DeleteLocalCredential>(_onDeleteLocalCredential);
    on<ClearLocalCredentials>(_onClearLocalCredentials);
    on<AutoApplyJob>(_onAutoApplyJob);
    on<AutoApplyStatusUpdate>(_onAutoApplyStatusUpdate);
  }

  void _onAddTargetRole(AddTargetRole event, Emitter<JobState> emit) {
    final trimmed = event.role.trim();
    if (trimmed.isEmpty) return;
    if (!state.targetRoles.any((r) => r.toLowerCase() == trimmed.toLowerCase())) {
      final updated = List<String>.from(state.targetRoles)..add(trimmed);
      emit(state.copyWith(targetRoles: updated));
    }
  }

  void _onRemoveTargetRole(RemoveTargetRole event, Emitter<JobState> emit) {
    if (state.targetRoles.length <= 1) return;
    final updated = state.targetRoles.where((r) => r.toLowerCase() != event.role.toLowerCase()).toList();
    emit(state.copyWith(targetRoles: updated));
  }

  void _onAddScrapedJobs(AddScrapedJobs event, Emitter<JobState> emit) {
    if (event.jobs.isEmpty) return;

    final existingUrls = state.allJobs.map((j) => j.applicationUrl).toSet();
    final List<JobModel> newScoredJobs = [];

    final userSkills = state.userProfile.primarySkills.map((s) => s.toLowerCase()).toSet();
    final userRoles = state.targetRoles.map((r) => r.toLowerCase()).toList();

    for (final job in event.jobs) {
      if (existingUrls.contains(job.applicationUrl)) continue;

      // Dynamic skill & role fit calculation against user profile
      final titleLower = job.title.toLowerCase();
      final descLower = job.fullDescription.toLowerCase();
      final tagsLower = job.tags.map((t) => t.toLowerCase()).toSet();

      int matchingSkillCount = 0;
      final List<String> matchedSkills = [];
      for (final skill in userSkills) {
        if (titleLower.contains(skill) || descLower.contains(skill) || tagsLower.contains(skill)) {
          matchingSkillCount++;
          matchedSkills.add(skill);
        }
      }

      int roleBonus = 0;
      for (final role in userRoles) {
        if (titleLower.contains(role) || descLower.contains(role)) {
          roleBonus = 15;
          break;
        }
      }

      // Base score 70, plus up to 25 for skills + role alignment
      final calculatedScore = (70 + (matchingSkillCount * 4) + roleBonus).clamp(72, 98);

      final whyFits = <String>[
        if (matchedSkills.isNotEmpty) 'Matches skills: ${matchedSkills.take(3).join(', ')}',
        if (roleBonus > 0) 'Aligned with your target career track',
        'Discovered live from company portal',
      ];

      final enriched = JobModel(
        id: job.id,
        title: job.title,
        company: job.company,
        location: job.location,
        isRemote: job.isRemote,
        salaryMin: job.salaryMin,
        salaryMax: job.salaryMax,
        tags: job.tags,
        matchScore: calculatedScore,
        whyItFits: whyFits,
        skillGaps: job.skillGaps,
        tailoredPitch: job.tailoredPitch,
        recruiterMessage: job.recruiterMessage,
        fullDescription: job.fullDescription,
        postedTimeAgo: 'Just now',
        applicationUrl: job.applicationUrl,
      );

      newScoredJobs.add(enriched);
    }

    final combined = [...newScoredJobs, ...state.allJobs];
    emit(state.copyWith(allJobs: combined));
  }

  void _onImportLocalCredentials(ImportLocalCredentials event, Emitter<JobState> emit) {
    emit(state.copyWith(localCredentials: event.credentials));
  }

  void _onDeleteLocalCredential(DeleteLocalCredential event, Emitter<JobState> emit) {
    if (event.index < 0 || event.index >= state.localCredentials.length) return;
    final updated = List<LocalCredential>.from(state.localCredentials)..removeAt(event.index);
    emit(state.copyWith(localCredentials: updated));
  }

  void _onClearLocalCredentials(ClearLocalCredentials event, Emitter<JobState> emit) {
    emit(state.copyWith(localCredentials: const []));
  }

  void _onToggleDomainFilter(ToggleDomainFilter event, Emitter<JobState> emit) {
    final updated = Set<String>.from(state.selectedDomains);
    if (updated.contains(event.domain)) {
      if (updated.length > 1) updated.remove(event.domain);
    } else {
      updated.add(event.domain);
    }
    emit(state.copyWith(selectedDomains: updated));
  }

  void _onToggleCompanyStageFilter(ToggleCompanyStageFilter event, Emitter<JobState> emit) {
    final updated = Set<String>.from(state.selectedCompanyStages);
    if (updated.contains(event.stage)) {
      if (updated.length > 1) updated.remove(event.stage);
    } else {
      updated.add(event.stage);
    }
    emit(state.copyWith(selectedCompanyStages: updated));
  }

  void _onToggleSeniorityFilter(ToggleSeniorityFilter event, Emitter<JobState> emit) {
    final updated = Set<String>.from(state.selectedSeniorities);
    if (updated.contains(event.seniority)) {
      if (updated.length > 1) updated.remove(event.seniority);
    } else {
      updated.add(event.seniority);
    }
    emit(state.copyWith(selectedSeniorities: updated));
  }

  void _onToggleSkillBoost(ToggleSkillBoost event, Emitter<JobState> emit) {
    final updated = Set<String>.from(state.boostedSkills);
    if (updated.contains(event.skill)) {
      updated.remove(event.skill);
    } else {
      updated.add(event.skill);
    }
    emit(state.copyWith(boostedSkills: updated));
  }

  void _onResetCareerAlignment(ResetCareerAlignment event, Emitter<JobState> emit) {
    emit(state.copyWith(
      targetRoles: List<String>.from(state.userProfile.targetRoles),
      selectedCompanyStages: {'🚀 Early Startup (0→1)', '⚡ Growth Scaleup'},
      selectedSeniorities: {'🌱 Junior (0–2 yrs)', '⚡ Mid-Level (2–5 yrs)'},
      boostedSkills: state.userProfile.primarySkills.take(3).toSet(),
    ));
  }

  void _onSteeringBiasChanged(SteeringBiasChanged event, Emitter<JobState> emit) {
    emit(state.copyWith(
      techFocusBias: event.techFocus ?? state.techFocusBias,
      companyScaleBias: event.companyScale ?? state.companyScaleBias,
      roleScopeBias: event.roleScope ?? state.roleScopeBias,
    ));
  }

  void _onResetSteeringBiases(ResetSteeringBiases event, Emitter<JobState> emit) {
    final biases = calculateBiases(
      skills: state.userProfile.primarySkills,
      summary: state.userProfile.parsedSummary,
    );
    emit(state.copyWith(
      techFocusBias: biases.techFocus,
      companyScaleBias: biases.companyScale,
      roleScopeBias: biases.roleScope,
    ));
  }

  void _onSyncSteeringToResume(SyncSteeringToResume event, Emitter<JobState> emit) {
    final autoBoosted = state.userProfile.primarySkills.take(3).toSet();
    final newInsight = 'Re-synchronized career alignment with "${state.userProfile.resumeFileName ?? 'active resume'}"';
    final updatedList = List<String>.from(state.userProfile.learnedPreferences);
    if (!updatedList.contains(newInsight)) {
      updatedList.insert(0, newInsight);
      if (updatedList.length > 6) updatedList.removeLast();
    }
    emit(state.copyWith(
      boostedSkills: autoBoosted,
      userProfile: state.userProfile.copyWith(
        learnedPreferences: updatedList,
      ),
    ));
  }

  void _onSimulateVectorShift(SimulateVectorShift event, Emitter<JobState> emit) {
    final updatedList = List<String>.from(state.userProfile.learnedPreferences);
    updatedList.insert(0, event.insight);
    if (updatedList.length > 6) updatedList.removeLast();

    final newShift = (state.userProfile.vectorShiftMagnitude + event.delta).clamp(0.0, 1.0);
    emit(state.copyWith(
      userProfile: state.userProfile.copyWith(
        learnedPreferences: updatedList,
        vectorShiftMagnitude: newShift,
      ),
    ));
  }

  void _onResetVectorShift(ResetVectorShift event, Emitter<JobState> emit) {
    emit(state.copyWith(
      userProfile: state.userProfile.copyWith(
        learnedPreferences: [
          'Learned affinity for Flutter & Supabase in Synthetix AI (saved)',
          'High vector weighting for PostgreSQL & pgvector roles',
          'Down-weighted on-site requirements in favour of async remote',
        ],
        vectorShiftMagnitude: 0.15,
      ),
    ));
  }

  // ──────────── Event Handlers ────────────

  void _onSearchQueryChanged(SearchQueryChanged event, Emitter<JobState> emit) {
    emit(state.copyWith(searchQuery: event.query));
  }

  void _onFilterRemoteOnlyToggled(
      FilterRemoteOnlyToggled event, Emitter<JobState> emit) {
    emit(state.copyWith(filterRemoteOnly: !state.filterRemoteOnly));
  }

  void _onMinMatchScoreChanged(
      MinMatchScoreChanged event, Emitter<JobState> emit) {
    emit(state.copyWith(minMatchScore: event.score));
  }

  void _onMinSalaryChanged(MinSalaryChanged event, Emitter<JobState> emit) {
    emit(state.copyWith(minSalary: event.salary));
  }

  void _onCategoryChanged(CategoryChanged event, Emitter<JobState> emit) {
    emit(state.copyWith(selectedCategory: event.category));
  }

  void _onToggleSaveJob(ToggleSaveJob event, Emitter<JobState> emit) {
    final updatedJobs = state.allJobs.map((job) {
      if (job.id == event.jobId) {
        final toggled = job.copyWith(isSaved: !job.isSaved);
        if (toggled.isSaved) {
          _learnFromPositive(toggled, 'saved', emit);
        }
        return toggled;
      }
      return job;
    }).toList();

    emit(state.copyWith(allJobs: updatedJobs));
  }

  void _onMarkJobApplied(MarkJobApplied event, Emitter<JobState> emit) {
    final updatedJobs = state.allJobs.map((job) {
      if (job.id == event.jobId) {
        final applied = job.copyWith(isApplied: true);
        _learnFromPositive(applied, 'applied', emit);
        return applied;
      }
      return job;
    }).toList();

    emit(state.copyWith(allJobs: updatedJobs));
  }

  void _onDismissJob(DismissJob event, Emitter<JobState> emit) {
    final updatedJobs = state.allJobs.map((job) {
      if (job.id == event.jobId) {
        final dismissed = job.copyWith(isDismissed: true);
        _learnFromNegative(dismissed, emit);
        return dismissed;
      }
      return job;
    }).toList();

    emit(state.copyWith(allJobs: updatedJobs));
  }

  static ({double techFocus, double companyScale, double roleScope}) calculateBiases({
    required List<String> skills,
    required String summary,
  }) {
    final skillsLower = skills.map((s) => s.toLowerCase()).toList();
    final summaryLower = summary.toLowerCase();

    // 1. Tech Focus Bias (-1.0 Mobile/Frontend to +1.0 Backend/Data)
    final backendSignals = [
      'postgresql', 'pgvector', 'python', 'fastapi', 'docker', 'graphql',
      'supabase', 'backend', 'sql', 'database', 'system', 'cloud', 'aws', 'data', 'redis', 'go'
    ];
    final frontendSignals = [
      'flutter', 'dart', 'react', 'frontend', 'mobile', 'ui/ux',
      'swift', 'kotlin', 'tailwind', 'ios', 'android', 'web', 'ui'
    ];

    int backendScore = 0;
    for (var s in backendSignals) {
      if (skillsLower.any((sk) => sk.contains(s)) || summaryLower.contains(s)) backendScore++;
    }
    int frontendScore = 0;
    for (var s in frontendSignals) {
      if (skillsLower.any((sk) => sk.contains(s)) || summaryLower.contains(s)) frontendScore++;
    }

    double newTechFocus = 0.0;
    if (backendScore + frontendScore > 0) {
      newTechFocus = ((backendScore - frontendScore) / (backendScore + frontendScore)).clamp(-0.85, 0.85);
      newTechFocus = double.parse(newTechFocus.toStringAsFixed(2));
    }

    // 2. Company Scale Bias (-1.0 Startup to +1.0 Enterprise)
    double newCompanyScale = -0.20;
    if (summaryLower.contains('startup') || summaryLower.contains('founding') || summaryLower.contains('0 to 1') || summaryLower.contains('fast-paced') || summaryLower.contains('seed')) {
      newCompanyScale = -0.65;
    } else if (summaryLower.contains('enterprise') || summaryLower.contains('corporate') || summaryLower.contains('distributed platform') || summaryLower.contains('fortune')) {
      newCompanyScale = 0.55;
    }

    // 3. Role Seniority Bias (-1.0 IC to +1.0 Architect/Lead)
    double newRoleScope = 0.20;
    if (summaryLower.contains('lead') || summaryLower.contains('staff') || summaryLower.contains('principal') || summaryLower.contains('architect') || summaryLower.contains('founding') || summaryLower.contains('head')) {
      newRoleScope = 0.65;
    } else if (summaryLower.contains('senior')) {
      newRoleScope = 0.35;
    } else if (summaryLower.contains('junior') || summaryLower.contains('intern') || summaryLower.contains('entry') || summaryLower.contains('associate')) {
      newRoleScope = -0.45;
    }

    return (
      techFocus: newTechFocus,
      companyScale: newCompanyScale,
      roleScope: newRoleScope,
    );
  }

  void _onResumeUploaded(ResumeUploaded event, Emitter<JobState> emit) {
    // ── Auto-Calibrate Career Alignment & Skill Gravity from Resume ──
    final summaryLower = event.summary.toLowerCase();
    final skillsLower = event.skills.map((s) => s.toLowerCase()).toSet();

    // 1. Role Domains
    final domains = <String>{};
    if (summaryLower.contains('full-stack') || summaryLower.contains('full stack') ||
        (skillsLower.any((s) => ['flutter', 'react', 'typescript', 'dart', 'vue', 'swift'].contains(s)) &&
         skillsLower.any((s) => ['postgresql', 'python', 'fastapi', 'supabase', 'docker', 'sql', 'go', 'node'].contains(s)))) {
      domains.add('Full-Stack');
    }
    if (skillsLower.any((s) => ['flutter', 'dart', 'react', 'swift', 'kotlin', 'ui/ux', 'frontend'].contains(s)) ||
        summaryLower.contains('frontend') || summaryLower.contains('mobile')) {
      domains.add('Frontend & Mobile');
    }
    if (skillsLower.any((s) => ['postgresql', 'python', 'fastapi', 'docker', 'supabase', 'redis', 'backend', 'systems'].contains(s)) ||
        summaryLower.contains('backend') || summaryLower.contains('systems')) {
      domains.add('Backend & Systems');
    }
    if (skillsLower.any((s) => ['pgvector', 'ai', 'rag', 'ml', 'pytorch', 'langchain'].contains(s)) ||
        summaryLower.contains('ai') || summaryLower.contains('vector')) {
      domains.add('AI & Data Platforms');
    }
    if (domains.isEmpty) domains.add('Full-Stack');

    // 2. Company Stages
    final stages = <String>{};
    if (summaryLower.contains('startup') || summaryLower.contains('founding') || summaryLower.contains('seed') || summaryLower.contains('fast-paced')) {
      stages.addAll(['🚀 Early Startup (0→1)', '⚡ Growth Scaleup']);
    } else if (summaryLower.contains('enterprise') || summaryLower.contains('corporate') || summaryLower.contains('distributed platform')) {
      stages.add('🏢 Enterprise Scale');
    } else {
      stages.addAll(['🚀 Early Startup (0→1)', '⚡ Growth Scaleup']);
    }

    // 3. Seniority & Experience Spectrum (Intern to Lead)
    final seniorities = <String>{};
    final isInternProfile = summaryLower.contains('intern') || summaryLower.contains('student') || summaryLower.contains('apprentice');
    final isJuniorProfile = summaryLower.contains('junior') || summaryLower.contains('entry') || summaryLower.contains('0-2') || summaryLower.contains('bootcamp');
    final isLeadProfile = summaryLower.contains('lead') || summaryLower.contains('staff') || summaryLower.contains('principal') || summaryLower.contains('architect') || summaryLower.contains('head');

    if (isInternProfile) {
      seniorities.addAll(['🎓 Intern / Co-op', '🌱 Junior (0–2 yrs)']);
    } else if (isJuniorProfile) {
      seniorities.addAll(['🌱 Junior (0–2 yrs)', '⚡ Mid-Level (2–5 yrs)']);
    } else if (isLeadProfile) {
      seniorities.addAll(['🛠️ Senior (5+ yrs)', '👑 Lead / Staff / Architect']);
    } else {
      seniorities.addAll(['⚡ Mid-Level (2–5 yrs)', '🛠️ Senior (5+ yrs)']);
    }

    // 4. Inferred / Target Roles
    final detectedRoles = <String>[];
    if (isInternProfile) {
      detectedRoles.add('Software Engineer Intern');
      if (skillsLower.any((s) => ['python', 'backend'].contains(s))) detectedRoles.add('Backend Intern');
      if (skillsLower.any((s) => ['flutter', 'react', 'frontend'].contains(s))) detectedRoles.add('Frontend Intern');
    } else {
      if (domains.contains('Full-Stack')) detectedRoles.add('Full-Stack Developer');
      if (domains.contains('Frontend & Mobile')) detectedRoles.add('Mobile & Frontend Architect');
      if (domains.contains('Backend & Systems')) detectedRoles.add('Backend & Systems Engineer');
      if (domains.contains('AI & Data Platforms')) detectedRoles.add('AI Platform Engineer');
    }
    if (detectedRoles.isEmpty) detectedRoles.add('Software Engineer');

    // 5. Boost top 3 primary skills from candidate's resume
    final autoBoosted = event.skills.take(3).toSet();

    final biases = calculateBiases(
      skills: event.skills,
      summary: event.summary,
    );

    final newInsight = 'Calibrated career alignment for ${detectedRoles.join(", ")} from "${event.fileName}"';
    final updatedPreferences = List<String>.from(state.userProfile.learnedPreferences);
    updatedPreferences.insert(0, newInsight);
    if (updatedPreferences.length > 6) updatedPreferences.removeLast();

    emit(state.copyWith(
      targetRoles: detectedRoles,
      selectedDomains: domains,
      selectedCompanyStages: stages,
      selectedSeniorities: seniorities,
      boostedSkills: autoBoosted,
      techFocusBias: biases.techFocus,
      companyScaleBias: biases.companyScale,
      roleScopeBias: biases.roleScope,
      userProfile: state.userProfile.copyWith(
        resumeFileName: event.fileName,
        resumeUploadedAt: DateTime.now(),
        parsedSummary: event.summary,
        primarySkills: event.skills,
        learnedPreferences: updatedPreferences,
        vectorShiftMagnitude: (state.userProfile.vectorShiftMagnitude + 0.08).clamp(0.0, 1.0),
      ),
    ));
  }

  void _onSupabaseConfigured(
      SupabaseConfigured event, Emitter<JobState> emit) {
    emit(state.copyWith(
      supabaseUrl: event.url,
      supabaseAnonKey: event.anonKey,
      isSupabaseConnected: true,
    ));
  }

  // ──────────── Learning Loop ────────────

  void _learnFromPositive(JobModel job, String actionType, Emitter<JobState> emit) {
    final newInsight =
        'Learned affinity for ${job.tags.take(2).join(" & ")} in ${job.company} ($actionType)';
    final updatedList = List<String>.from(state.userProfile.learnedPreferences);
    if (!updatedList.contains(newInsight)) {
      updatedList.insert(0, newInsight);
      if (updatedList.length > 5) updatedList.removeLast();
    }
    emit(state.copyWith(
      userProfile: state.userProfile.copyWith(
        learnedPreferences: updatedList,
        vectorShiftMagnitude:
            (state.userProfile.vectorShiftMagnitude + 0.05).clamp(0.0, 1.0),
      ),
    ));
  }

  void _learnFromNegative(JobModel job, Emitter<JobState> emit) {
    final newInsight = 'Down-weighted similarity for "${job.title}" pattern';
    final updatedList = List<String>.from(state.userProfile.learnedPreferences);
    if (!updatedList.contains(newInsight)) {
      updatedList.insert(0, newInsight);
      if (updatedList.length > 5) updatedList.removeLast();
    }
    emit(state.copyWith(
      userProfile: state.userProfile.copyWith(
        learnedPreferences: updatedList,
        vectorShiftMagnitude:
            (state.userProfile.vectorShiftMagnitude + 0.03).clamp(0.0, 1.0),
      ),
    ));
  }

  // ──────────── Initial Seed Data ────────────

  static JobState _initialState() {
    return JobState(
      userProfile: UserProfile(
        id: 'user_001',
        fullName: 'Alex Vance',
        email: 'alex.vance@dev.io',
        resumeFileName: 'Alex_Vance_FullStack_Resume.pdf',
        resumeUploadedAt: DateTime.now().subtract(const Duration(hours: 2)),
        parsedSummary:
            'Full-Stack & Mobile Software Engineer with 4+ years shipping scalable apps using Flutter, TypeScript, React, Python, and Supabase / PostgreSQL. Specializes in real-time interfaces, RAG architectures, and cloud deployments.',
        yearsOfExperience: 4,
        primarySkills: [
          'Flutter',
          'Dart',
          'TypeScript',
          'React',
          'Supabase',
          'PostgreSQL',
          'Python',
          'FastAPI',
          'Docker',
          'REST & GraphQL',
          'pgvector',
        ],
        targetRoles: [
          'Senior Flutter Engineer',
          'Full Stack Product Engineer',
          'AI / RAG Application Developer',
        ],
        preferredLocations: [
          'Remote (US / Global)',
          'San Francisco, CA',
          'New York, NY',
        ],
        minDesiredSalary: 130000,
        remoteOnly: true,
        learnedPreferences: [
          'Shifted +24% preference toward AI & Developer Tool startups',
          'Learned strong affinity for remote-first work cultures',
          'Prioritized Postgres/Supabase backend stacks over enterprise Java/C#',
        ],
        vectorShiftMagnitude: 0.35,
      ),
      allJobs: [
        JobModel(
          id: 'job_01',
          title: 'Senior / Staff Fullstack Engineer',
          company: 'Linear',
          location: 'San Francisco, CA (Remote)',
          isRemote: true,
          salaryMin: 160000,
          salaryMax: 210000,
          tags: ['TypeScript', 'React', 'Node.js', 'PostgreSQL', 'GraphQL'],
          matchScore: 96,
          whyItFits: [
            'Direct 1:1 match with your 4+ yrs full-stack product engineering.',
            'Values high craftsmanship and real-time reactive sync architectures.',
            'Target salary (\$160k–\$210k) exceeds your \$130k baseline.',
          ],
          skillGaps: [
            'Deep focus on web performance and local-first SQLite/IndexedDB patterns.',
          ],
          tailoredPitch:
              'Hi Linear team! I have built real-time collaborative interfaces and high-performance reactive applications. I admire Linear’s focus on speed and polish and would love to bring my full-stack background to the team.',
          recruiterMessage:
              'Subject: Alex Vance — Senior / Staff Fullstack Engineer\n\nDear Linear Team,\n\nI have followed Linear’s product journey and craftsmanship closely. With 4+ years building production full-stack systems and reactive web interfaces, I would love to contribute to your core web platform.\n\nBest,\nAlex Vance',
          fullDescription:
              'Linear is building the standard for modern software engineering tools. We are seeking a Senior / Staff Fullstack Engineer to own core product workflows, design resilient APIs, and deliver blazing fast user experiences.',
          postedTimeAgo: 'Just now',
          applicationUrl: 'https://jobs.ashbyhq.com/linear/d3bc1ced-3ce4-4086-a050-555055dbb1ff',
        ),
        JobModel(
          id: 'job_02',
          title: 'AI Engineer (Generative AI & LLM Systems)',
          company: 'GitLab',
          location: 'Remote (Worldwide)',
          isRemote: true,
          salaryMin: 145000,
          salaryMax: 190000,
          tags: ['Python', 'FastAPI', 'pgvector', 'Docker', 'AI Systems'],
          matchScore: 93,
          whyItFits: [
            'Extensive match on Python FastAPI and vector embeddings with pgvector.',
            'Focus on developer-facing AI integrations and intelligent assistants.',
            '100% remote asynchronous culture worldwide.',
          ],
          skillGaps: [
            'Experience with large-scale evaluation benchmarks across multi-model inference.',
          ],
          tailoredPitch:
              'Hey GitLab team! Having built RAG and semantic search systems with pgvector and Python microservices, I am excited about GitLab’s developer-first AI tools.',
          recruiterMessage:
              'Subject: Alex Vance — AI Engineer\n\nHi GitLab Recruiting,\n\nI love your open core approach to developer tools and AI assistants.\n\nBest regards,\nAlex',
          fullDescription:
              'GitLab is hiring an AI Engineer to build next-generation developer productivity tools. You will work with LLM APIs, embedding vectors, and scalable inference backends.',
          postedTimeAgo: 'Live',
          applicationUrl: 'https://job-boards.greenhouse.io/gitlab/jobs/8556658002',
        ),
        JobModel(
          id: 'job_03',
          title: 'Senior / Staff Product Engineer, AI',
          company: 'Linear',
          location: 'San Francisco, CA (Remote)',
          isRemote: true,
          salaryMin: 165000,
          salaryMax: 220000,
          tags: ['TypeScript', 'React', 'Python', 'LLMs', 'UI/UX'],
          matchScore: 91,
          whyItFits: [
            'Combines product engineering with applied AI feature development.',
            'Matches your full-stack capabilities across TypeScript and Python APIs.',
            'Top-tier equity and compensation package.',
          ],
          skillGaps: [
            'Fine-tuning prompt evaluations for domain-specific issue tracking.',
          ],
          tailoredPitch:
              'Hi Linear! I enjoy bridging interactive UI design with intelligent agentic backend services to make AI feel effortless to end users.',
          recruiterMessage:
              'Subject: Application: Senior Product Engineer, AI — Alex Vance\n\nHello Linear Team,\n\nWarmly,\nAlex Vance',
          fullDescription:
              'We are looking for a Product Engineer specialized in AI to pioneer intelligent workflows within Linear. You will build end-to-end features from UI interactions to backend model integrations.',
          postedTimeAgo: 'Active',
          applicationUrl: 'https://jobs.ashbyhq.com/linear/b4a7764e-c680-4bdf-9956-dc78f2ca94d5',
        ),
        JobModel(
          id: 'job_04',
          title: 'Backend Engineer (Duo Chat & Systems)',
          company: 'GitLab',
          location: 'Remote (US & Global)',
          isRemote: true,
          salaryMin: 140000,
          salaryMax: 185000,
          tags: ['Python', 'PostgreSQL', 'Docker', 'REST & GraphQL'],
          matchScore: 87,
          whyItFits: [
            'Solid overlap with your backend API design and PostgreSQL optimization.',
            'Focus on high-availability distributed systems.',
          ],
          skillGaps: [
            'Ruby on Rails microservice integration experience.',
          ],
          tailoredPitch:
              'Hi GitLab! Having engineered reliable backend APIs backed by Postgres and containerized deployments, I appreciate high-throughput architecture.',
          recruiterMessage:
              'Subject: Backend Engineer — Alex Vance\n\nDear GitLab Team,\n\nBest,\nAlex',
          fullDescription:
              'The Duo Chat team at GitLab builds conversational intelligence into the developer workflow. We are looking for a Backend Engineer to scale our services.',
          postedTimeAgo: 'Recent',
          applicationUrl: 'https://job-boards.greenhouse.io/gitlab/jobs/8698314002',
        ),
        JobModel(
          id: 'job_05',
          title: 'Analytics Engineer Intern',
          company: 'Coinbase',
          location: 'Remote (US)',
          isRemote: true,
          salaryMin: 90000,
          salaryMax: 120000,
          tags: ['Python', 'SQL', 'PostgreSQL', 'Data Pipelines'],
          matchScore: 82,
          whyItFits: [
            'Perfect entry point for students, interns, or junior engineers.',
            'Direct overlap with SQL and Python data querying skills.',
          ],
          skillGaps: [
            'Snowflake data warehouse modeling.',
          ],
          tailoredPitch:
              'Hello Coinbase! Passionate about crypto and financial infrastructure, I have solid foundations in SQL and backend data pipelines.',
          recruiterMessage:
              'Subject: Analytics Engineer Intern — Alex Vance\n\nHi Coinbase Team,\n\nCheers,\nAlex',
          fullDescription:
              'Coinbase is offering an Analytics Engineer Internship. You will work alongside senior engineers building data pipelines and metrics analytics.',
          postedTimeAgo: 'Live',
          applicationUrl: 'https://www.coinbase.com/careers/positions/8175471?gh_jid=8175471',
        ),
        JobModel(
          id: 'job_06',
          title: 'Enterprise & Solutions Engineer',
          company: 'Figma',
          location: 'San Francisco, CA (Hybrid / Remote)',
          isRemote: true,
          salaryMin: 155000,
          salaryMax: 200000,
          tags: ['TypeScript', 'Design Systems', 'Web Tech', 'APIs'],
          matchScore: 78,
          whyItFits: [
            'Aligns with your web UI engineering and developer tooling experience.',
            'Top design-tech ecosystem.',
          ],
          skillGaps: [
            'Direct enterprise customer advisory experience.',
          ],
          tailoredPitch:
              'Hi Figma! With my deep appreciation for design tools and frontend architecture, I love helping teams adopt modern web technology.',
          recruiterMessage:
              'Subject: Solutions Engineer Inquiry — Alex Vance\n\nDear Figma Team,\n\nRegards,\nAlex',
          fullDescription:
              'Figma is growing its technical solutions team to help organizations design, prototype, and build production web and mobile software.',
          postedTimeAgo: 'Active',
          applicationUrl: 'https://boards.greenhouse.io/figma/jobs/5426468004?gh_jid=5426468004',
        ),
      ],
      supabaseUrl: 'https://apezpfkigivawkufnurw.supabase.co',
      supabaseAnonKey: 'sb_publishable_Ij8knuo7DgZPtfw9Zv0F3A_BSUOYJZY',
      isSupabaseConnected: true,
    );
  }

  // ══════════════════════════════════════════════════
  // Auto-Apply Engine Handlers
  // ══════════════════════════════════════════════════

  static const String _backendUrl = 'http://localhost:8000';

  void _onAutoApplyJob(AutoApplyJob event, Emitter<JobState> emit) async {
    // Set initial pending status
    final statuses = Map<String, AutoApplyStatus>.from(state.autoApplyStatuses);
    statuses[event.jobId] = AutoApplyStatus(
      jobId: event.jobId,
      status: 'running',
      message: 'Launching auto-apply engine...',
    );
    emit(state.copyWith(autoApplyStatuses: statuses));

    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auto-apply'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'job_url': event.jobUrl,
          'job_title': event.jobTitle,
          'job_company': event.jobCompany,
          'job_description': event.jobDescription,
          'headless': true,
        }),
      );

      final data = jsonDecode(response.body);
      final updatedStatuses = Map<String, AutoApplyStatus>.from(state.autoApplyStatuses);

      if (response.statusCode == 200 && data['status'] == 'success') {
        updatedStatuses[event.jobId] = AutoApplyStatus(
          jobId: event.jobId,
          status: 'success',
          message: 'Application filled! ${data['fields_filled']} fields completed in ${data['duration_seconds']}s',
          fieldsFilled: data['fields_filled'] ?? 0,
          log: List<String>.from(data['log'] ?? []),
        );

        // Also mark the job as applied
        final updatedJobs = state.allJobs.map((j) {
          if (j.id == event.jobId) return j.copyWith(isApplied: true);
          return j;
        }).toList();

        emit(state.copyWith(
          autoApplyStatuses: updatedStatuses,
          allJobs: updatedJobs,
        ));
      } else {
        updatedStatuses[event.jobId] = AutoApplyStatus(
          jobId: event.jobId,
          status: 'error',
          message: data['error'] ?? data['detail'] ?? 'Unknown error',
          log: List<String>.from(data['log'] ?? []),
        );
        emit(state.copyWith(autoApplyStatuses: updatedStatuses));
      }
    } catch (e) {
      final updatedStatuses = Map<String, AutoApplyStatus>.from(state.autoApplyStatuses);
      updatedStatuses[event.jobId] = AutoApplyStatus(
        jobId: event.jobId,
        status: 'error',
        message: 'Connection failed: $e. Is the backend running on localhost:8000?',
      );
      emit(state.copyWith(autoApplyStatuses: updatedStatuses));
    }
  }

  void _onAutoApplyStatusUpdate(AutoApplyStatusUpdate event, Emitter<JobState> emit) {
    final statuses = Map<String, AutoApplyStatus>.from(state.autoApplyStatuses);
    statuses[event.jobId] = AutoApplyStatus(
      jobId: event.jobId,
      status: event.status,
      message: event.message,
      fieldsFilled: event.fieldsFilled,
      log: event.log,
    );
    emit(state.copyWith(autoApplyStatuses: statuses));
  }
}
