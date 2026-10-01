import 'package:flutter/foundation.dart';
import '../models/job_model.dart';
import '../models/user_profile.dart';
import '../models/local_credential.dart';

// ──────────────────── Auto-Apply Status ────────────────────

class AutoApplyStatus {
  final String jobId;
  final String status; // 'pending', 'running', 'success', 'error'
  final String message;
  final int fieldsFilled;
  final List<String> log;

  const AutoApplyStatus({
    required this.jobId,
    this.status = 'pending',
    this.message = '',
    this.fieldsFilled = 0,
    this.log = const [],
  });

  AutoApplyStatus copyWith({
    String? status,
    String? message,
    int? fieldsFilled,
    List<String>? log,
  }) {
    return AutoApplyStatus(
      jobId: jobId,
      status: status ?? this.status,
      message: message ?? this.message,
      fieldsFilled: fieldsFilled ?? this.fieldsFilled,
      log: log ?? this.log,
    );
  }

  bool get isRunning => status == 'running' || status == 'pending';
  bool get isSuccess => status == 'success';
  bool get isError => status == 'error';
}

// ──────────────────── State ────────────────────

@immutable
class JobState {
  final UserProfile userProfile;
  final List<JobModel> allJobs;
  final String searchQuery;
  final bool filterRemoteOnly;
  final int minMatchScore;
  final int minSalary;
  final String selectedCategory;
  final String? supabaseUrl;
  final String? supabaseAnonKey;
  final bool isSupabaseConnected;
  final double techFocusBias; // Legacy/Internal
  final double companyScaleBias; // Legacy/Internal
  final double roleScopeBias; // Legacy/Internal
  final Set<String> selectedDomains; // Legacy/Internal
  final Set<String> selectedCompanyStages; // e.g. {'🚀 Early Startup (0→1)', '⚡ Growth Scaleup'}
  final Set<String> selectedSeniorities; // e.g. {'🎓 Intern / Co-op', '🌱 Junior (0–2 yrs)'}
  final Set<String> boostedSkills; // e.g. {'PostgreSQL', 'TypeScript'}
  final List<String> targetRoles; // Freeform custom roles, e.g. ['Full-Stack Developer', 'DevOps Intern']
  final List<LocalCredential> localCredentials; // Zero-knowledge client-only credentials
  final Map<String, AutoApplyStatus> autoApplyStatuses; // Track auto-apply progress per job

  const JobState({
    required this.userProfile,
    required this.allJobs,
    this.searchQuery = '',
    this.filterRemoteOnly = false,
    this.minMatchScore = 70,
    this.minSalary = 100000,
    this.selectedCategory = 'All',
    this.supabaseUrl,
    this.supabaseAnonKey,
    this.isSupabaseConnected = false,
    this.techFocusBias = 0.15,
    this.companyScaleBias = -0.20,
    this.roleScopeBias = 0.25,
    this.selectedDomains = const {'Full-Stack', 'Backend & Systems'},
    this.selectedCompanyStages = const {'🚀 Early Startup (0→1)', '⚡ Growth Scaleup'},
    this.selectedSeniorities = const {'🌱 Junior (0–2 yrs)', '⚡ Mid-Level (2–5 yrs)'},
    this.boostedSkills = const {'PostgreSQL', 'Flutter'},
    this.targetRoles = const ['Full-Stack Developer', 'Mobile & Systems Engineer'],
    this.localCredentials = const [],
    this.autoApplyStatuses = const {},
  });

  // ── Steered Match Calculation (Universal Roles & Experience Spectrum) ──
  int computeSteeredScore(JobModel job) {
    double score = job.matchScore.toDouble();
    final titleLower = job.title.toLowerCase();
    final companyLower = job.company.toLowerCase();
    final descLower = job.fullDescription.toLowerCase();
    final tagsLower = job.tags.map((t) => t.toLowerCase()).toSet();

    // 1. Custom Target Roles Semantic Alignment (Unlimited Roles)
    if (targetRoles.isNotEmpty) {
      bool matchedAnyRole = false;
      for (final role in targetRoles) {
        final rLower = role.toLowerCase().trim();
        if (rLower.isEmpty) continue;
        if (titleLower.contains(rLower) || descLower.contains(rLower)) {
          score += 7.0;
          matchedAnyRole = true;
          break;
        }
        final roleWords = rLower.split(RegExp(r'\s+')).where((w) => w.length > 2);
        int wordHits = 0;
        for (final word in roleWords) {
          if (titleLower.contains(word) || tagsLower.contains(word)) {
            wordHits++;
          }
        }
        if (wordHits > 0) {
          score += wordHits * 2.5;
          matchedAnyRole = true;
        }
      }
      if (!matchedAnyRole) {
        score -= 2.0;
      }
    }

    // 2. Comprehensive Seniority & Experience Alignment (0-Exp to Lead)
    if (selectedSeniorities.isNotEmpty) {
      final isIntern = titleLower.contains('intern') ||
          titleLower.contains('co-op') ||
          descLower.contains('internship') ||
          descLower.contains('student');
      final isJunior = titleLower.contains('junior') ||
          titleLower.contains('entry') ||
          titleLower.contains('associate') ||
          descLower.contains('0-2 years') ||
          descLower.contains('0-1 year');
      final isLead = titleLower.contains('lead') ||
          titleLower.contains('staff') ||
          titleLower.contains('principal') ||
          titleLower.contains('architect');
      final isSenior = titleLower.contains('senior') || descLower.contains('5+ years');

      if (selectedSeniorities.contains('🎓 Intern / Co-op')) {
        if (isIntern) score += 9.0;
        if (isSenior || isLead) score -= 4.0;
      }
      if (selectedSeniorities.contains('🌱 Junior (0–2 yrs)')) {
        if (isJunior || isIntern) score += 7.0;
        if (isLead) score -= 3.0;
      }
      if (selectedSeniorities.contains('⚡ Mid-Level (2–5 yrs)')) {
        if (!isLead && !isIntern) score += 4.0;
      }
      if (selectedSeniorities.contains('🛠️ Senior (5+ yrs)')) {
        if (isSenior && !isLead) score += 6.0;
      }
      if (selectedSeniorities.contains('👑 Lead / Staff / Architect')) {
        if (isLead) score += 7.0;
      }
    }

    // 3. Company Stage & Environment Alignment
    if (selectedCompanyStages.isNotEmpty) {
      final isStartup = titleLower.contains('founding') ||
          companyLower.contains('synthetix') ||
          companyLower.contains('vektor');
      if (selectedCompanyStages.any((s) => s.contains('Startup')) && isStartup) {
        score += 5.0;
      }
      if (selectedCompanyStages.any((s) => s.contains('Scaleup')) && !titleLower.contains('architect')) {
        score += 3.0;
      }
      if (selectedCompanyStages.any((s) => s.contains('Enterprise')) && !isStartup) {
        score += 5.0;
      }
    }

    // 4. Boosted Skill Gravity (+4.0 for each boosted skill present)
    for (final skill in boostedSkills) {
      final s = skill.toLowerCase();
      if (tagsLower.contains(s) || descLower.contains(s) || titleLower.contains(s)) {
        score += 4.0;
      }
    }

    return score.round().clamp(50, 99);
  }

  // ── Natural Language Alignment Summary ──
  String get activeAlignmentSummary {
    final rolesStr = targetRoles.isEmpty ? 'All Roles' : targetRoles.join(', ');
    final senioritiesStr = selectedSeniorities.isEmpty ? 'All Experience Levels' : selectedSeniorities.join(' & ');
    final skillsStr = boostedSkills.isEmpty
        ? 'Standard Skills'
        : 'prioritizing ${boostedSkills.take(3).join(', ')}';
    return 'Targeting $rolesStr for $senioritiesStr, $skillsStr.';
  }

  // ── Derived Getters ──

  List<JobModel> get filteredJobs {
    final list = allJobs.where((job) {
      if (job.isDismissed) return false;
      final effectiveScore = computeSteeredScore(job);
      if (effectiveScore < minMatchScore) return false;
      if (filterRemoteOnly && !job.isRemote) return false;
      if (job.salaryMax < minSalary) return false;

      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesTitle = job.title.toLowerCase().contains(query);
        final matchesCompany = job.company.toLowerCase().contains(query);
        final matchesTags = job.tags.any((t) => t.toLowerCase().contains(query));
        final matchesDesc = job.fullDescription.toLowerCase().contains(query);
        if (!matchesTitle && !matchesCompany && !matchesTags && !matchesDesc) {
          return false;
        }
      }

      if (selectedCategory != 'All') {
        if (selectedCategory == 'Saved' && !job.isSaved) return false;
        if (selectedCategory == 'Applied' && !job.isApplied) return false;
        if (selectedCategory == 'High Fit (90%+)' && effectiveScore < 90) return false;
      }

      return true;
    }).toList();

    list.sort((a, b) => computeSteeredScore(b).compareTo(computeSteeredScore(a)));
    return list;
  }

  int get totalSavedCount => allJobs.where((j) => j.isSaved).length;
  int get totalAppliedCount => allJobs.where((j) => j.isApplied).length;
  int get totalMatchesCount => filteredJobs.length;

  // ── CopyWith ──

  JobState copyWith({
    UserProfile? userProfile,
    List<JobModel>? allJobs,
    String? searchQuery,
    bool? filterRemoteOnly,
    int? minMatchScore,
    int? minSalary,
    String? selectedCategory,
    String? supabaseUrl,
    String? supabaseAnonKey,
    bool? isSupabaseConnected,
    double? techFocusBias,
    double? companyScaleBias,
    double? roleScopeBias,
    Set<String>? selectedDomains,
    Set<String>? selectedCompanyStages,
    Set<String>? selectedSeniorities,
    Set<String>? boostedSkills,
    List<String>? targetRoles,
    List<LocalCredential>? localCredentials,
    Map<String, AutoApplyStatus>? autoApplyStatuses,
  }) {
    return JobState(
      userProfile: userProfile ?? this.userProfile,
      allJobs: allJobs ?? this.allJobs,
      searchQuery: searchQuery ?? this.searchQuery,
      filterRemoteOnly: filterRemoteOnly ?? this.filterRemoteOnly,
      minMatchScore: minMatchScore ?? this.minMatchScore,
      minSalary: minSalary ?? this.minSalary,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      supabaseAnonKey: supabaseAnonKey ?? this.supabaseAnonKey,
      isSupabaseConnected: isSupabaseConnected ?? this.isSupabaseConnected,
      techFocusBias: techFocusBias ?? this.techFocusBias,
      companyScaleBias: companyScaleBias ?? this.companyScaleBias,
      roleScopeBias: roleScopeBias ?? this.roleScopeBias,
      selectedDomains: selectedDomains ?? this.selectedDomains,
      selectedCompanyStages: selectedCompanyStages ?? this.selectedCompanyStages,
      selectedSeniorities: selectedSeniorities ?? this.selectedSeniorities,
      boostedSkills: boostedSkills ?? this.boostedSkills,
      targetRoles: targetRoles ?? this.targetRoles,
      localCredentials: localCredentials ?? this.localCredentials,
      autoApplyStatuses: autoApplyStatuses ?? this.autoApplyStatuses,
    );
  }
}
