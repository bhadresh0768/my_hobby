import 'package:flutter_test/flutter_test.dart';
import 'package:my_hobby/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BusinessDiaryApp());

    // Verify that the app title is present
    expect(find.text('Business Diary'), findsOneWidget);
  });
}
