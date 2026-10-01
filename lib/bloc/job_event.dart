import 'package:flutter/foundation.dart';
import '../models/job_model.dart';
import '../models/local_credential.dart';


// ──────────────────── Events ────────────────────

@immutable
sealed class JobEvent {}

class SearchQueryChanged extends JobEvent {
  final String query;
  SearchQueryChanged(this.query);
}

class FilterRemoteOnlyToggled extends JobEvent {}

class MinMatchScoreChanged extends JobEvent {
  final int score;
  MinMatchScoreChanged(this.score);
}

class MinSalaryChanged extends JobEvent {
  final int salary;
  MinSalaryChanged(this.salary);
}

class CategoryChanged extends JobEvent {
  final String category;
  CategoryChanged(this.category);
}

class ToggleSaveJob extends JobEvent {
  final String jobId;
  ToggleSaveJob(this.jobId);
}

class MarkJobApplied extends JobEvent {
  final String jobId;
  MarkJobApplied(this.jobId);
}

class DismissJob extends JobEvent {
  final String jobId;
  DismissJob(this.jobId);
}

class ResumeUploaded extends JobEvent {
  final String fileName;
  final String summary;
  final List<String> skills;

  ResumeUploaded({
    required this.fileName,
    required this.summary,
    required this.skills,
  });
}

class SupabaseConfigured extends JobEvent {
  final String url;
  final String anonKey;

  SupabaseConfigured({required this.url, required this.anonKey});
}

class SimulateVectorShift extends JobEvent {
  final double delta;
  final String insight;
  SimulateVectorShift({required this.delta, required this.insight});
}

class ResetVectorShift extends JobEvent {}

class SteeringBiasChanged extends JobEvent {
  final double? techFocus;
  final double? companyScale;
  final double? roleScope;

  SteeringBiasChanged({this.techFocus, this.companyScale, this.roleScope});
}

class ResetSteeringBiases extends JobEvent {}

class SyncSteeringToResume extends JobEvent {}

class ToggleDomainFilter extends JobEvent {
  final String domain;
  ToggleDomainFilter(this.domain);
}

class ToggleCompanyStageFilter extends JobEvent {
  final String stage;
  ToggleCompanyStageFilter(this.stage);
}

class ToggleSeniorityFilter extends JobEvent {
  final String seniority;
  ToggleSeniorityFilter(this.seniority);
}

class ToggleSkillBoost extends JobEvent {
  final String skill;
  ToggleSkillBoost(this.skill);
}

class ResetCareerAlignment extends JobEvent {}

class AddTargetRole extends JobEvent {
  final String role;
  AddTargetRole(this.role);
}

class RemoveTargetRole extends JobEvent {
  final String role;
  RemoveTargetRole(this.role);
}

class AddScrapedJobs extends JobEvent {
  final List<JobModel> jobs;
  AddScrapedJobs(this.jobs);
}

class ImportLocalCredentials extends JobEvent {
  final List<LocalCredential> credentials;
  ImportLocalCredentials(this.credentials);
}

class DeleteLocalCredential extends JobEvent {
  final int index;
  DeleteLocalCredential(this.index);
}

class ClearLocalCredentials extends JobEvent {}

class AutoApplyJob extends JobEvent {
  final String jobId;
  final String jobUrl;
  final String jobTitle;
  final String jobCompany;
  final String jobDescription;
  AutoApplyJob({
    required this.jobId,
    required this.jobUrl,
    this.jobTitle = '',
    this.jobCompany = '',
    this.jobDescription = '',
  });
}

class AutoApplyStatusUpdate extends JobEvent {
  final String jobId;
  final String status; // 'pending', 'running', 'success', 'error'
  final String message;
  final int fieldsFilled;
  final List<String> log;
  AutoApplyStatusUpdate({
    required this.jobId,
    required this.status,
    this.message = '',
    this.fieldsFilled = 0,
    this.log = const [],
  });
}

