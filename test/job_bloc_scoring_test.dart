import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:job_searcher/bloc/job_bloc.dart';
import 'package:job_searcher/bloc/job_event.dart';
import 'package:job_searcher/models/job_model.dart';
import 'package:job_searcher/services/job_persistence_service.dart';

JobModel _makeScrapedJob({
  String id = 'scraped_1',
  String title = 'Senior Python AI Engineer',
  String company = 'Acme AI',
  String description = 'Build RAG pipelines with Python, FastAPI, and pgvector.',
  String url = 'https://jobs.example.com/acme-ai-1',
  List<String> tags = const ['Python', 'FastAPI', 'pgvector'],
}) {
  return JobModel(
    id: id,
    title: title,
    company: company,
    location: 'Remote',
    isRemote: true,
    salaryMin: 120000,
    salaryMax: 160000,
    tags: tags,
    matchScore: 85,
    whyItFits: const ['Live extracted'],
    skillGaps: const ['Review live job posting requirements'],
    tailoredPitch: 'Default pitch',
    recruiterMessage: 'Default recruiter message',
    fullDescription: description,
    postedTimeAgo: 'Live API',
    applicationUrl: url,
  );
}

void main() {
  group('JobBloc Backend URL Resolution', () {
    test('falls back to http://localhost:8000 when override is empty', () {
      expect(JobBloc.resolveBackendUrl(''), 'http://localhost:8000');
      expect(JobBloc.resolveBackendUrl('   '), 'http://localhost:8000');
      expect(JobBloc.resolveBackendUrl('https://api.example.com/'), 'https://api.example.com');
      expect(JobBloc.backendUrl, 'http://localhost:8000');
    });
  });

  group('JobBloc /api/score-jobs Scoring & Fallback', () {
    late JobPersistenceService persistence;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      persistence = JobPersistenceService(prefs);
    });

    test('scores scraped jobs via Python /api/score-jobs and labels whyItFits', () async {
      late Map<String, dynamic> capturedPayload;
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), 'http://localhost:8000/api/score-jobs');
        capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'scoring_mode': 'llm_plus_embeddings',
            'results': [
              {
                'id': 'scraped_ai_1',
                'match_score': 94,
                'cosine_similarity': 0.87,
                'why_it_fits': [
                  'Strong Python FastAPI & pgvector RAG match',
                  'Remote engineering alignment',
                ],
                'skill_gaps': ['Kubernetes multi-region scaling'],
                'tailored_pitch': 'Custom LLM tailored pitch for Acme AI.',
                'recruiter_message': 'Hi Acme AI team, custom outreach message.',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final bloc = JobBloc(
        persistence: persistence,
        httpClient: mockClient,
        backendUrlOverride: '',
        isHttpsWebOriginOverride: false,
      );
      addTearDown(bloc.close);

      final scraped = _makeScrapedJob(id: 'scraped_ai_1');
      bloc.add(AddScrapedJobs([scraped]));
      await pumpEventQueue();

      expect(capturedPayload['resume_text'], isNotEmpty);
      expect(capturedPayload['jobs'], hasLength(1));
      expect(capturedPayload['jobs'][0]['id'], 'scraped_ai_1');
      expect(capturedPayload['jobs'][0]['title'], 'Senior Python AI Engineer');
      expect(capturedPayload['jobs'][0]['company'], 'Acme AI');
      expect(capturedPayload['jobs'][0]['description'], scraped.fullDescription);

      final added = bloc.state.allJobs.firstWhere((j) => j.id == 'scraped_ai_1');
      expect(added.matchScore, 94);
      expect(added.whyItFits.first, contains('Python LLM + FastEmbed'));
      expect(added.whyItFits.first, contains('Cosine 87%'));
      expect(added.whyItFits, contains('Strong Python FastAPI & pgvector RAG match'));
      expect(added.skillGaps, ['Kubernetes multi-region scaling']);
      expect(added.tailoredPitch, 'Custom LLM tailored pitch for Acme AI.');
      expect(added.recruiterMessage, 'Hi Acme AI team, custom outreach message.');
    });

    test('falls back to offline keyword scoring when backend is unreachable', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final bloc = JobBloc(
        persistence: persistence,
        httpClient: mockClient,
        backendUrlOverride: 'http://localhost:8000',
        isHttpsWebOriginOverride: false,
      );
      addTearDown(bloc.close);

      final scraped = _makeScrapedJob(id: 'scraped_offline_1');
      bloc.add(AddScrapedJobs([scraped]));
      await pumpEventQueue();

      final added = bloc.state.allJobs.firstWhere((j) => j.id == 'scraped_offline_1');
      expect(added.matchScore, greaterThanOrEqualTo(72));
      expect(added.whyItFits.first, contains('Offline keyword fallback'));
      expect(added.whyItFits.first, contains('unreachable'));
    });

    test('skips HTTP backend on HTTPS web origin without HTTPS BACKEND_URL', () async {
      bool called = false;
      final mockClient = MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      });

      final bloc = JobBloc(
        persistence: persistence,
        httpClient: mockClient,
        backendUrlOverride: 'http://localhost:8000',
        isHttpsWebOriginOverride: true,
      );
      addTearDown(bloc.close);

      final scraped = _makeScrapedJob(id: 'scraped_https_blocked');
      bloc.add(AddScrapedJobs([scraped]));
      await pumpEventQueue();

      expect(called, isFalse);
      final added = bloc.state.allJobs.firstWhere((j) => j.id == 'scraped_https_blocked');
      expect(added.whyItFits.first, contains('Offline keyword fallback'));
      expect(added.whyItFits.first, contains('HTTPS'));
    });

    test('calls HTTPS BACKEND_URL even on HTTPS web origin', () async {
      late Uri calledUri;
      final mockClient = MockClient((request) async {
        calledUri = request.url;
        return http.Response(
          jsonEncode({
            'scoring_mode': 'llm_plus_embeddings',
            'results': [
              {
                'id': 'scraped_https_ok',
                'match_score': 91,
                'cosine_similarity': 0.81,
                'why_it_fits': ['Verified HTTPS scoring'],
                'skill_gaps': [],
                'tailored_pitch': 'HTTPS pitch',
                'recruiter_message': 'HTTPS message',
              },
            ],
          }),
          200,
        );
      });

      final bloc = JobBloc(
        persistence: persistence,
        httpClient: mockClient,
        backendUrlOverride: 'https://job-searcher-api.onrender.com/',
        isHttpsWebOriginOverride: true,
      );
      addTearDown(bloc.close);

      bloc.add(AddScrapedJobs([_makeScrapedJob(id: 'scraped_https_ok')]));
      await pumpEventQueue();

      expect(calledUri.toString(), 'https://job-searcher-api.onrender.com/api/score-jobs');
      final added = bloc.state.allJobs.firstWhere((j) => j.id == 'scraped_https_ok');
      expect(added.matchScore, 91);
      expect(added.whyItFits.first, contains('Python LLM + FastEmbed'));
    });

    test('preserves concurrent state updates made while /api/score-jobs is in flight', () async {
      final requestStarted = Completer<void>();
      final releaseResponse = Completer<void>();

      final mockClient = MockClient((request) async {
        requestStarted.complete();
        await releaseResponse.future;
        return http.Response(
          jsonEncode({
            'scoring_mode': 'llm_plus_embeddings',
            'results': [
              {
                'id': 'scraped_async_1',
                'match_score': 89,
                'cosine_similarity': 0.78,
                'why_it_fits': ['Async match'],
                'skill_gaps': [],
                'tailored_pitch': 'Async pitch',
                'recruiter_message': 'Async msg',
              },
            ],
          }),
          200,
        );
      });

      final bloc = JobBloc(
        persistence: persistence,
        httpClient: mockClient,
        isHttpsWebOriginOverride: false,
      );
      addTearDown(bloc.close);

      bloc.add(AddScrapedJobs([_makeScrapedJob(id: 'scraped_async_1')]));
      await requestStarted.future;

      // Dispatch another event while the HTTP call is awaiting
      bloc.add(SearchQueryChanged('Flutter'));
      await pumpEventQueue();
      expect(bloc.state.searchQuery, 'Flutter');

      // Now finish the HTTP response
      releaseResponse.complete();
      await pumpEventQueue();

      // Both the concurrent state change AND the newly scored job must exist
      expect(bloc.state.searchQuery, 'Flutter');
      expect(bloc.state.allJobs.any((j) => j.id == 'scraped_async_1'), isTrue);
    });
  });
}
