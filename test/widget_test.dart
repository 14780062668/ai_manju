import 'package:flutter_test/flutter_test.dart';

import 'package:ai_manju/app/manju_app.dart';

void main() {
  testWidgets('创作页能打开', (WidgetTester tester) async {
    await tester.pumpWidget(const ManjuApp());
    expect(find.text('AI漫剧'), findsOneWidget);
    expect(find.text('生成漫剧'), findsOneWidget);
  });
}
