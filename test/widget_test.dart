// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wifi_chat/main.dart';
import 'package:wifi_chat/services/profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final profileService = ProfileService();

  testWidgets('Shows login when profile not set', (WidgetTester tester) async {
    await tester.pumpWidget(WiFiChatApp(
      profileService: profileService,
      hasProfile: false,
    ));

    await tester.pumpAndSettle();

    expect(find.text('Set Up Profile'), findsOneWidget);
    expect(find.text('Save and Continue'), findsOneWidget);
  });
}
