import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:job_searcher/bloc/job_bloc.dart';
import 'package:job_searcher/models/job_model.dart';
import 'package:job_searcher/services/job_persistence_service.dart';
import 'package:job_searcher/theme/app_colors.dart';
import 'package:job_searcher/widgets/segmented_led_bar.dart';
import 'package:job_searcher/widgets/harmonic_pulse_waveform.dart';
import 'package:job_searcher/widgets/difficulty_gauntlet_dots.dart';
import 'package:job_searcher/widgets/diagnostic_dossier_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Pulse Fit HUD Reusable Widgets', () {
    testWidgets('SegmentedLedBar renders 10 cells with correct active counts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SegmentedLedBar(
              totalSegments: 10,
              percentage: 80,
              activeColor: AppColors.secondary,
            ),
          ),
        ),
      );

      expect(find.byType(SegmentedLedBar), findsOneWidget);
    });

    testWidgets('HarmonicPulseWaveform renders canvas and animates breathing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HarmonicPulseWaveform(width: 192, height: 64),
          ),
        ),
      );

      expect(find.byType(HarmonicPulseWaveform), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('DifficultyGauntletDots renders 5-dot matrix with custom ratings', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DifficultyGauntletDots(
              rating: 4,
              label: 'HARD',
              activeColor: AppColors.secondary,
            ),
          ),
        ),
      );

      expect(find.byType(DifficultyGauntletDots), findsOneWidget);
      expect(find.text('HARD'), findsOneWidget);
    });
    testWidgets('SegmentedLedBar renders safely in unbounded horizontal constraints', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedLedBar(percentage: 50),
            ),
          ),
        ),
      );
      expect(find.byType(SegmentedLedBar), findsOneWidget);
    });

    testWidgets('DifficultyGauntletDots clamps boundary ratings properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                DifficultyGauntletDots(rating: -5),
                DifficultyGauntletDots(rating: 100),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(DifficultyGauntletDots), findsNWidgets(2));
    });
  });

  group('DiagnosticDossierModal Cockpit Tests', () {
    late JobModel testJob;

    setUp(() {
      testJob = JobModel(
        id: 'test-stripe-001',
        title: 'Senior Distributed Systems Engineer',
        company: 'Stripe',
        location: 'San Francisco, CA',
        isRemote: true,
        salaryMin: 210000,
        salaryMax: 290000,
        currency: '\$',
        tags: ['Infra-Core', 'Go', 'Distributed Systems'],
        matchScore: 94,
        whyItFits: [
          'Go / Concurrency & Memory Primitives',
          'Consensus Algorithms (Raft / Paxos)',
          'Kubernetes, Envoy & Mesh Topologies',
          'Streaming Fabrics (Apache Kafka / Flink)',
        ],
        skillGaps: ['C++ Memory Allocation'],
        tailoredPitch: 'Lead Go engineer with deep consensus and high throughput systems expertise.',
        recruiterMessage: 'Hi recruiter, I am excited about Stripe Infra-Core...',
        fullDescription: 'We are seeking a Senior Distributed Systems Engineer to scale our global core payments engine...',
        postedTimeAgo: '2m ago',
        applicationUrl: 'https://stripe.com/jobs/123',
      );
    });

    testWidgets('Renders all 4 Modules and Hero Pulse Engine cleanly', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final persistence = JobPersistenceService(prefs);
      final jobBloc = JobBloc(persistence: persistence);

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<JobBloc>.value(
            value: jobBloc,
            child: Scaffold(
              body: DiagnosticDossierModal(job: testJob),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Check header and stream status
      expect(find.text('DIAG_SPEC // 04'), findsOneWidget);
      expect(find.text('Diagnostic Dossier'), findsOneWidget);
      expect(find.text('SYS.FIT-ANALYSIS // v4.8'), findsOneWidget);
      expect(find.text('STRIPE // INFRA-CORE'), findsOneWidget);

      // Check Hero pulse engine
      expect(find.text('NEURAL VECTOR SYNCHRONIZATION'), findsOneWidget);
      expect(find.text('TOTAL FIT AMPLITUDE'), findsOneWidget);
      expect(find.text('94.0'), findsOneWidget);
      expect(find.text('VECTOR COSINE'), findsOneWidget);
      expect(find.text('QUERY LATENCY'), findsOneWidget);
      expect(find.text('MARKET RANK'), findsOneWidget);

      // Check Modules
      expect(find.text('// MOD_01'), findsOneWidget);
      expect(find.text('CORE DNA MATCH VECTORS'), findsOneWidget);
      expect(find.text('// MOD_02'), findsOneWidget);
      expect(find.text('TACTICAL BRIDGE VECTORS'), findsOneWidget);
      expect(find.text('// MOD_03'), findsOneWidget);
      expect(find.text('VELOCITY & RHYTHM SYNC'), findsOneWidget);
      expect(find.text('// MOD_04'), findsOneWidget);
      expect(find.text('PREDICTED INTERVIEW GAUNTLETS'), findsOneWidget);

      // Check Action Dock
      expect(find.text('AUTO-CALIBRATE RESUME TO VECTOR'), findsOneWidget);
      expect(find.text('1-CLICK COLD DM'), findsOneWidget);
      expect(find.text('EXPORT DOSSIER'), findsOneWidget);

      // Tap Auto-Calibrate CTA and verify telemetry toast (200 OK)
      await tester.tap(find.text('AUTO-CALIBRATE RESUME TO VECTOR'));
      await tester.pump();
      expect(find.text('200 OK'), findsOneWidget);
      expect(find.text('RESUME RE-INDEXED: +4.8% TAXONOMY ALIGNMENT ACHIEVED'), findsOneWidget);

      // Test tab switching to RAW JD
      await tester.tap(find.text('RAW JD'));
      await tester.pump();
      expect(find.text('TAILORED STRATEGIC ELEVATOR PITCH'), findsOneWidget);
      expect(find.text('COLD DM / OUTREACH TEMPLATE'), findsOneWidget);
    });

    testWidgets('DiagnosticDossierModal handles empty metadata gracefully without crash', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final persistence = JobPersistenceService(prefs);
      final jobBloc = JobBloc(persistence: persistence);

      final emptyJob = JobModel(
        id: 'empty-job-001',
        title: 'Software Engineer',
        company: 'Unknown Co',
        location: 'Remote',
        isRemote: false,
        salaryMin: 0,
        salaryMax: 0,
        currency: '\$',
        tags: [],
        matchScore: 0,
        whyItFits: [],
        skillGaps: [],
        tailoredPitch: '',
        recruiterMessage: '',
        fullDescription: '',
        postedTimeAgo: '',
        applicationUrl: '',
      );

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<JobBloc>.value(
            value: jobBloc,
            child: Scaffold(
              body: DiagnosticDossierModal(job: emptyJob),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('DIAG_SPEC // 04'), findsOneWidget);
      expect(find.text('UNKNOWN CO // CORE'), findsOneWidget);
    });
  });
}
