import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:fve_installer_reminder/localization/app_localizations.dart';
import 'package:fve_installer_reminder/state/app_state.dart';

void main() {
  late AppState mockAppState;
  late LanguageNotifier mockLanguageNotifier;
  late Widget testWidget;

  setUp(() async {
    // Set up SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});

    // Create mock AppState
    mockAppState = AppState();

    // Create mock LanguageNotifier
    mockLanguageNotifier = LanguageNotifier();

    // Create test widget with providers
    testWidget = MaterialApp(
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<AppState>.value(value: mockAppState),
          ChangeNotifierProvider<LanguageNotifier>.value(
            value: mockLanguageNotifier,
          ),
        ],
        child: const Scaffold(),
      ),
    );
  });

  group('AppLocalizations Initialization Tests', () {
    test('should initialize with default language', () async {
      final delegate = await AppLocalizations.initialize();
      expect(delegate, isNotNull);
      expect(AppLocalizations.languageNotifier.currentLanguage, 'cs');
    });

    test('should initialize with saved language', () async {
      // Set up SharedPreferences with a saved language
      SharedPreferences.setMockInitialValues({'language_code': 'en'});

      final delegate = await AppLocalizations.initialize();
      expect(delegate, isNotNull);
      expect(AppLocalizations.languageNotifier.currentLanguage, 'en');
    });

    test('should handle initialization errors gracefully', () async {
      // Set up SharedPreferences to throw an error
      SharedPreferences.setMockInitialValues({});

      expect(() => AppLocalizations.initialize(), throwsException);
    });
  });

  group('AppLocalizations Language Change Tests', () {
    testWidgets('should change language successfully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testWidget);
      await AppLocalizations.initialize();

      final context = tester.element(find.byType(Scaffold));
      await AppLocalizations.changeLanguage(context, 'en');

      expect(AppLocalizations.languageNotifier.currentLanguage, 'en');

      // Verify SharedPreferences was updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('language_code'), 'en');
    });

    testWidgets('should handle language change errors gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testWidget);
      await AppLocalizations.initialize();

      // Set up SharedPreferences to throw an error
      SharedPreferences.setMockInitialValues({});

      final context = tester.element(find.byType(Scaffold));
      expect(
        () => AppLocalizations.changeLanguage(context, 'en'),
        throwsException,
      );
    });

    testWidgets('should not update language if context is not mounted', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testWidget);
      await AppLocalizations.initialize();

      // Create a context that's not mounted
      final unmountedContext = tester.element(find.byType(Scaffold));
      await tester.pumpWidget(const SizedBox()); // Unmount the widget

      await AppLocalizations.changeLanguage(unmountedContext, 'en');
      // No exception should be thrown
    });
  });

  group('AppLocalizations Current Language Tests', () {
    testWidgets('should get current language from LanguageNotifier', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testWidget);

      mockLanguageNotifier.changeLanguage('en');
      final context = tester.element(find.byType(Scaffold));
      final language = AppLocalizations.getCurrentLanguage(context);
      expect(language, 'en');
    });

    testWidgets(
      'should return default language if LanguageNotifier is not available',
      (WidgetTester tester) async {
        // Create a widget without LanguageNotifier
        final widgetWithoutNotifier = MaterialApp(
          home: ChangeNotifierProvider<AppState>.value(
            value: mockAppState,
            child: const Scaffold(),
          ),
        );

        await tester.pumpWidget(widgetWithoutNotifier);
        final context = tester.element(find.byType(Scaffold));
        final language = AppLocalizations.getCurrentLanguage(context);
        expect(language, 'cs'); // Default language
      },
    );
  });

  group('LanguageNotifier Tests', () {
    test('should notify listeners when language changes', () {
      var notified = false;
      mockLanguageNotifier.addListener(() {
        notified = true;
      });

      mockLanguageNotifier.changeLanguage('en');
      expect(notified, true);
    });

    test('should update current language', () async {
      await mockLanguageNotifier.changeLanguage('en');
      expect(mockLanguageNotifier.currentLanguage, 'en');
    });
  });
}
