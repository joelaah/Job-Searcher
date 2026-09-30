import 'package:flutter_test/flutter_test.dart';
import 'package:job_searcher/models/local_credential.dart';

void main() {
  group('LocalCredential Unit Tests', () {
    test('LocalCredential initializes correctly with provided values', () {
      const cred = LocalCredential(
        platform: 'Greenhouse',
        loginUrl: 'https://boards.greenhouse.io',
        usernameOrEmail: 'applicant@example.com',
        password: 'secure_password_123',
        resumePath: 'resumes/swe_2026.pdf',
        notes: 'Targeting infra roles',
      );

      expect(cred.platform, 'Greenhouse');
      expect(cred.loginUrl, 'https://boards.greenhouse.io');
      expect(cred.usernameOrEmail, 'applicant@example.com');
      expect(cred.password, 'secure_password_123');
      expect(cred.resumePath, 'resumes/swe_2026.pdf');
      expect(cred.notes, 'Targeting infra roles');
    });

    test('LocalCredential.fromMap handles standard CSV headers', () {
      final map = {
        'platform': 'Lever',
        'url': 'https://jobs.lever.co/company',
        'username': 'dev_user',
        'password': 'vault_password!',
        'resume': 'resume.pdf',
        'notes': 'Preferred location: NYC',
      };

      final cred = LocalCredential.fromMap(map);
      expect(cred.platform, 'Lever');
      expect(cred.loginUrl, 'https://jobs.lever.co/company');
      expect(cred.usernameOrEmail, 'dev_user');
      expect(cred.password, 'vault_password!');
      expect(cred.resumePath, 'resume.pdf');
      expect(cred.notes, 'Preferred location: NYC');
    });

    test('LocalCredential.fromMap handles alias column keys gracefully', () {
      final map = {
        'site': 'Ashby',
        'login_url': 'https://jobs.ashbyhq.com/startup',
        'email': 'job_seeker@gmail.com',
        'pass': 'super_secret',
        'resume_path': 'cv.pdf',
      };

      final cred = LocalCredential.fromMap(map);
      expect(cred.platform, 'Ashby');
      expect(cred.loginUrl, 'https://jobs.ashbyhq.com/startup');
      expect(cred.usernameOrEmail, 'job_seeker@gmail.com');
      expect(cred.password, 'super_secret');
      expect(cred.resumePath, 'cv.pdf');
      expect(cred.notes, '');
    });

    test('LocalCredential.copyWith updates specific properties without mutation', () {
      const initial = LocalCredential(
        platform: 'General',
        loginUrl: '',
        usernameOrEmail: 'user1',
        password: 'pass1',
      );

      final updated = initial.copyWith(
        platform: 'Workday',
        loginUrl: 'https://myworkdayjobs.com',
      );

      expect(updated.platform, 'Workday');
      expect(updated.loginUrl, 'https://myworkdayjobs.com');
      expect(updated.usernameOrEmail, 'user1');
      expect(updated.password, 'pass1');
      expect(initial.platform, 'General');
    });
  });
}
