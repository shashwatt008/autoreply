import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AutoReplyApp());
    expect(find.text('AutoReply.io'), findsOneWidget);
  });
}
