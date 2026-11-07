import 'package:flutter_test/flutter_test.dart';
import 'package:project_prm_1/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ConferenceApp());

    expect(find.text('Conference Management'), findsOneWidget);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
