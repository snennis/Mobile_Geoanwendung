import 'package:flutter_test/flutter_test.dart';
import 'package:travel_buddy/main.dart';

void main() {
  testWidgets('App starts and shows input screen', (tester) async {
    await tester.pumpWidget(const TravelBuddyApp(hasSeenOnboarding: true));
    expect(find.text('TravelBuddy'), findsOneWidget);
    expect(find.text('Plane deine Reise'), findsOneWidget);
  });
}
