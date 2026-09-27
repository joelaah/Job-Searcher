import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_searcher/main.dart';

void main() {
  testWidgets('JOB SeArCh desktop smoke test', (WidgetTester tester) async {
    // Configure standard desktop viewport for Flutter Web
    tester.view.physicalSize = const Size(1440, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const JobSearchApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify key UI elements render cleanly
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('JOB'), findsWidgets);
    expect(find.text('SeArCh'), findsWidgets);
  });
}
