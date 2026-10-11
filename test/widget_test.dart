import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:job_searcher/main.dart';
import 'package:job_searcher/services/job_persistence_service.dart';

void main() {
  testWidgets('JOB SeArCh desktop smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistence = JobPersistenceService(prefs);

    // Configure standard desktop viewport for Flutter Web
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(JobSearchApp(persistence: persistence));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify key UI elements render cleanly
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('JOB'), findsWidgets);
    expect(find.text('SeArCh'), findsWidgets);
  });
}
