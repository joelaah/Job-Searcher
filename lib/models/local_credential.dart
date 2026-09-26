class LocalCredential {
  final String platform;
  final String loginUrl;
  final String usernameOrEmail;
  final String password;
  final String resumePath;
  final String notes;

  const LocalCredential({
    required this.platform,
    required this.loginUrl,
    required this.usernameOrEmail,
    required this.password,
    this.resumePath = '',
    this.notes = '',
  });

  LocalCredential copyWith({
    String? platform,
    String? loginUrl,
    String? usernameOrEmail,
    String? password,
    String? resumePath,
    String? notes,
  }) {
    return LocalCredential(
      platform: platform ?? this.platform,
      loginUrl: loginUrl ?? this.loginUrl,
      usernameOrEmail: usernameOrEmail ?? this.usernameOrEmail,
      password: password ?? this.password,
      resumePath: resumePath ?? this.resumePath,
      notes: notes ?? this.notes,
    );
  }

  factory LocalCredential.fromMap(Map<String, String> map) {
    return LocalCredential(
      platform: map['platform'] ?? map['site'] ?? map['portal'] ?? 'General',
      loginUrl: map['url'] ?? map['login_url'] ?? '',
      usernameOrEmail: map['username'] ?? map['email'] ?? map['user'] ?? '',
      password: map['password'] ?? map['pass'] ?? '',
      resumePath: map['resume'] ?? map['resume_path'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}
