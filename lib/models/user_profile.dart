class UserProfile {
  final String id;
  final String fullName;
  final String email;
  final String? resumeFileName;
  final String? resumeUrl;
  final DateTime? resumeUploadedAt;
  final String parsedSummary;
  final int yearsOfExperience;
  final List<String> primarySkills;
  final List<String> targetRoles;
  final List<String> preferredLocations;
  final int minDesiredSalary;
  final bool remoteOnly;
  final List<String> learnedPreferences;
  final double vectorShiftMagnitude; // 0.0 to 1.0 indicating AI learning adaptation

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.resumeFileName,
    this.resumeUrl,
    this.resumeUploadedAt,
    required this.parsedSummary,
    required this.yearsOfExperience,
    required this.primarySkills,
    required this.targetRoles,
    required this.preferredLocations,
    required this.minDesiredSalary,
    this.remoteOnly = true,
    required this.learnedPreferences,
    this.vectorShiftMagnitude = 0.28,
  });

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? resumeFileName,
    String? resumeUrl,
    DateTime? resumeUploadedAt,
    String? parsedSummary,
    int? yearsOfExperience,
    List<String>? primarySkills,
    List<String>? targetRoles,
    List<String>? preferredLocations,
    int? minDesiredSalary,
    bool? remoteOnly,
    List<String>? learnedPreferences,
    double? vectorShiftMagnitude,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      resumeFileName: resumeFileName ?? this.resumeFileName,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      resumeUploadedAt: resumeUploadedAt ?? this.resumeUploadedAt,
      parsedSummary: parsedSummary ?? this.parsedSummary,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      primarySkills: primarySkills ?? this.primarySkills,
      targetRoles: targetRoles ?? this.targetRoles,
      preferredLocations: preferredLocations ?? this.preferredLocations,
      minDesiredSalary: minDesiredSalary ?? this.minDesiredSalary,
      remoteOnly: remoteOnly ?? this.remoteOnly,
      learnedPreferences: learnedPreferences ?? this.learnedPreferences,
      vectorShiftMagnitude: vectorShiftMagnitude ?? this.vectorShiftMagnitude,
    );
  }
}
