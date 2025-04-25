import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'state/app_state.dart';
import 'presentation/pages/login/login_page.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/pages/user_managment/user_management_page.dart';
import 'localization/app_localizations.dart';
import 'core/utils/logger.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    AppLogger.info('Flutter binding initialized');

    // Initialize logger first
    AppLogger.initialize();
    AppLogger.info('Starting application initialization');

    final delegate = await AppLocalizations.initialize();
    AppLogger.info('Localization initialized successfully');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppState()),
          ChangeNotifierProvider.value(
            value: AppLocalizations.languageNotifier,
          ),
        ],
        child: LocalizedApp(delegate, const MyApp()),
      ),
    );
    AppLogger.info('Application started successfully');
  } catch (e, stackTrace) {
    AppLogger.error('Failed to initialize application', e, stackTrace);
    // Show error UI instead of crashing
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Failed to initialize application: $e')),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      return MaterialApp(
        title: translate('app.title'),
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          LocalizedApp.of(context).delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('cs')],
        locale: _getCurrentLocale(context),
        home: const AppRouter(),
        routes: {'/users': (context) => const UserManagementPage()},
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error building MaterialApp', e, stackTrace);
      return MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error building application: $e')),
        ),
      );
    }
  }

  Locale _getCurrentLocale(BuildContext context) {
    try {
      return Locale(context.watch<LanguageNotifier>().currentLanguage);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting current locale', e, stackTrace);
      return const Locale('en'); // Fallback to English
    }
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      return Consumer<AppState>(
        builder: (context, appState, child) {
          // Use both isLoggedIn and currentLanguage to force rebuilds
          final isLoggedIn = appState.isLoggedIn;
          final currentLanguage = appState.currentLanguage;

          AppLogger.debug(
            'App state changed - isLoggedIn: $isLoggedIn, language: $currentLanguage',
          );

          if (!isLoggedIn) {
            return const LoginPage();
          }
          return const HomePage();
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error in AppRouter', e, stackTrace);
      return Scaffold(
        body: Center(child: Text('Error in application routing: $e')),
      );
    }
  }
}
