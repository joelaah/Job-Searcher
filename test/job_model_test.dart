import 'package:flutter_test/flutter_test.dart';
import 'package:job_searcher/models/job_model.dart';

void main() {
  group('JobModel Unit Tests', () {
    test('JobModel.formattedSalary formats ranges correctly', () {
      final job = JobModel(
        id: '1',
        title: 'Senior Flutter Developer',
        company: 'Nova Labs',
        location: 'Remote',
        isRemote: true,
        salaryMin: 140000,
        salaryMax: 180000,
        tags: ['Flutter', 'Dart'],
        matchScore: 95,
        whyItFits: ['Proven Flutter expertise'],
        skillGaps: [],
        tailoredPitch: 'Ready to scale the mobile and web client.',
        recruiterMessage: 'Hi!',
        fullDescription: 'Full job description...',
        postedTimeAgo: '2d ago',
        applicationUrl: 'https://example.com/apply',
      );

      expect(job.formattedSalary, '\$140k - \$180k / yr');
    });

    test('JobModel.formattedSalary returns "Competitive" when salaries are zero', () {
      final job = JobModel(
        id: '2',
        title: 'Founding Engineer',
        company: 'Stealth AI',
        location: 'San Francisco, CA',
        isRemote: false,
        salaryMin: 0,
        salaryMax: 0,
        tags: ['AI', 'Python'],
        matchScore: 92,
        whyItFits: ['Strong generalist'],
        skillGaps: [],
        tailoredPitch: 'Passionate about early-stage innovation.',
        recruiterMessage: 'Hello!',
        fullDescription: 'Early stage startup role.',
        postedTimeAgo: 'Just now',
        applicationUrl: 'https://example.com/stealth',
      );

      expect(job.formattedSalary, 'Competitive');
    });

    test('JobModel.copyWith correctly updates interaction flags', () {
      final original = JobModel(
        id: '3',
        title: 'Backend Engineer',
        company: 'Vercel',
        location: 'Remote',
        isRemote: true,
        salaryMin: 150000,
        salaryMax: 190000,
        tags: ['Next.js', 'Go'],
        matchScore: 89,
        whyItFits: ['High scale backend systems'],
        skillGaps: ['Rust'],
        tailoredPitch: 'Pitch...',
        recruiterMessage: 'Message...',
        fullDescription: 'Description...',
        postedTimeAgo: '1d ago',
        applicationUrl: 'https://vercel.com/careers',
        isSaved: false,
        isApplied: false,
        isDismissed: false,
      );

      final saved = original.copyWith(isSaved: true);
      expect(saved.isSaved, isTrue);
      expect(saved.isApplied, isFalse);
      expect(saved.isDismissed, isFalse);

      final applied = saved.copyWith(isApplied: true);
      expect(applied.isSaved, isTrue);
      expect(applied.isApplied, isTrue);

      final dismissed = original.copyWith(isDismissed: true);
      expect(dismissed.isDismissed, isTrue);
    });

    test('JobModel.fromScrapedJson parses live scraper payload accurately', () {
      final rawJson = {
        'title': 'Distributed Systems Architect',
        'company': 'Cloudflare',
        'location': 'Austin, TX (Remote)',
        'is_remote': true,
        'salary_min': 175000,
        'salary_max': 225000,
        'tags': ['Rust', 'Networking', 'Wasm'],
        'job_url': 'https://cloudflare.com/careers/12345',
        'description': 'Help build the global edge network.',
        'source': 'greenhouse',
        'posted_at': '2026-03-29',
      };

      final job = JobModel.fromScrapedJson(rawJson, matchScore: 96);

      expect(job.title, 'Distributed Systems Architect');
      expect(job.company, 'Cloudflare');
      expect(job.location, 'Austin, TX (Remote)');
      expect(job.isRemote, isTrue);
      expect(job.salaryMin, 175000);
      expect(job.salaryMax, 225000);
      expect(job.matchScore, 96);
      expect(job.tags, ['Rust', 'Networking', 'Wasm']);
      expect(job.applicationUrl, 'https://cloudflare.com/careers/12345');
      expect(job.postedTimeAgo, 'Recently');
      expect(job.fullDescription, 'Help build the global edge network.');
    });

    test('JobModel.fromScrapedJson provides graceful defaults for empty payload', () {
      final job = JobModel.fromScrapedJson({});

      expect(job.title, 'Unknown Position');
      expect(job.company, 'Target Company');
      expect(job.location, 'Remote');
      expect(job.isRemote, isTrue);
      expect(job.tags, ['Live Scraped']);
      expect(job.matchScore, 85);
      expect(job.formattedSalary, 'Competitive');
    });
  });
}
