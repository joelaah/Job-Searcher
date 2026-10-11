import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:job_searcher/services/job_persistence_service.dart';
import 'package:job_searcher/bloc/job_bloc.dart';
import 'package:job_searcher/bloc/job_event.dart';

void main() {
  group('JobPersistenceService Unit Tests', () {
    late SharedPreferences prefs;
    late JobPersistenceService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = JobPersistenceService(prefs);
    });

    test('Initial state returns empty configurations and interactions', () {
      expect(service.loadInteractions(), isEmpty);
      expect(service.loadCachedScrapedJobs(), isEmpty);
      expect(service.loadSupabaseConfig(), isNull);
    });

    test('Saves and retrieves Supabase config without leaks', () async {
      await service.saveSupabaseConfig(
        'https://custom-project.supabase.co',
        'custom-anon-key-12345',
      );

      final config = service.loadSupabaseConfig();
      expect(config, isNotNull);
      expect(config!['url'], 'https://custom-project.supabase.co');
      expect(config['anonKey'], 'custom-anon-key-12345');
    });

    test('clearAll wipes interactions, cache, and Supabase credentials', () async {
      await service.saveSupabaseConfig(
        'https://test.supabase.co',
        'anon-key',
      );
      await service.saveInteraction(
        'job_01',
        isSaved: true,
        isApplied: false,
        isDismissed: false,
      );

      expect(service.loadSupabaseConfig(), isNotNull);
      expect(service.loadInteractions(), isNotEmpty);

      await service.clearAll();

      expect(service.loadSupabaseConfig(), isNull);
      expect(service.loadInteractions(), isEmpty);
    });

    test('clearSupabaseConfig selectively clears credentials while retaining job interactions', () async {
      await service.saveSupabaseConfig(
        'https://selective.supabase.co',
        'selective-key',
      );
      await service.saveInteraction(
        'job_preserve',
        isSaved: true,
        isApplied: true,
        isDismissed: false,
      );

      await service.clearSupabaseConfig();

      expect(service.loadSupabaseConfig(), isNull);
      final interactions = service.loadInteractions();
      expect(interactions['job_preserve']?['saved'], isTrue);
      expect(interactions['job_preserve']?['applied'], isTrue);
    });
  });

  group('JobBloc Security & State Initialization', () {
    test('JobBloc defaults to unconfigured Supabase when environment is unset', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = JobPersistenceService(prefs);

      final bloc = JobBloc(persistence: service);
      expect(bloc.state.supabaseUrl, isNull);
      expect(bloc.state.supabaseAnonKey, isNull);
      expect(bloc.state.isSupabaseConnected, isFalse);

      bloc.close();
    });

    test('JobBloc restores persisted Supabase config on LoadPersistedState', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = JobPersistenceService(prefs);

      await service.saveSupabaseConfig(
        'https://persisted-db.supabase.co',
        'persisted-key-xyz',
      );

      final bloc = JobBloc(persistence: service);
      bloc.add(LoadPersistedState());
      await pumpEventQueue();

      expect(bloc.state.supabaseUrl, 'https://persisted-db.supabase.co');
      expect(bloc.state.supabaseAnonKey, 'persisted-key-xyz');
      expect(bloc.state.isSupabaseConnected, isTrue);

      bloc.close();
    });

    test('JobBloc handles SupabaseDisconnected by clearing state and persisted storage', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = JobPersistenceService(prefs);

      final bloc = JobBloc(persistence: service);
      bloc.add(SupabaseConfigured(url: 'https://live.supabase.co', anonKey: 'live-key'));
      await pumpEventQueue();

      expect(bloc.state.isSupabaseConnected, isTrue);
      expect(bloc.state.supabaseUrl, 'https://live.supabase.co');
      expect(service.loadSupabaseConfig(), isNotNull);

      bloc.add(SupabaseDisconnected());
      await pumpEventQueue();

      expect(bloc.state.isSupabaseConnected, isFalse);
      expect(bloc.state.supabaseUrl, isNull);
      expect(bloc.state.supabaseAnonKey, isNull);
      expect(service.loadSupabaseConfig(), isNull);

      bloc.close();
    });

    test('JobState.copyWith with clearSupabase cleanly resets connection fields', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = JobPersistenceService(prefs);
      final bloc = JobBloc(persistence: service);
      final configuredState = bloc.state.copyWith(
        supabaseUrl: 'https://test.supabase.co',
        supabaseAnonKey: 'key123',
        isSupabaseConnected: true,
      );
      expect(configuredState.isSupabaseConnected, isTrue);

      final clearedState = configuredState.copyWith(clearSupabase: true);
      expect(clearedState.supabaseUrl, isNull);
      expect(clearedState.supabaseAnonKey, isNull);
      expect(clearedState.isSupabaseConnected, isFalse);

      bloc.close();
    });
  });
}

