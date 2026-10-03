import 'package:flutter_test/flutter_test.dart';
import 'package:roadedge_ai/main.dart';

void main() {
  testWidgets('RoadEdge AI app smoke test', (WidgetTester tester) async {
    // Build RoadEdgeApp
    await tester.pumpWidget(const RoadEdgeApp());

    // Verify brand header is present
    expect(find.text('ROAD EDGE AI'), findsWidgets);
    expect(find.text('START DRIVE'), findsOneWidget);
  });
}
