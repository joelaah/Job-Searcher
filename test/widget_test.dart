import 'package:flutter_test/flutter_test.dart';
import 'package:job_searcher/main.dart';

void main() {
  testWidgets('JOB SeArCh smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JobSearchApp());
    await tester.pump();
    expect(find.text('JOB'), findsOneWidget);
  });
}
