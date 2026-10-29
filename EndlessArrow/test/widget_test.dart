import 'package:arrow_challenge/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads menu screen', (tester) async {
    await tester.pumpWidget(const ArrowChallengeApp());
    // Splash animates then fades to menu (~1.6s + transition).
    await tester.pump(const Duration(milliseconds: 1800));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ARROW'), findsWidgets);
    expect(find.text('CHALLENGE'), findsWidgets);
    expect(find.text('PLAY'), findsOneWidget);
  });
}
