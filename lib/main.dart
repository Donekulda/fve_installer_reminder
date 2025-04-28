import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'state/app_state.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/user_management_page.dart';
import 'presentation/pages/required_image_model_page.dart';
import 'localization/app_localizations.dart';
import 'core/utils/logger.dart';

/// The main entry point of the application.
/// Initializes the Flutter binding, logger, and localization before running the app.
void main() async {
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize logger first for proper error tracking
    await AppLogger.initialize();
    final logger = AppLogger('main');
    logger.info('Flutter binding initialized');
    logger.info('Starting application initialization');

    // Initialize localization
    final delegate = await AppLocalizations.initialize();
    logger.info('Localization initialized successfully');

    // Run the application with providers for state management
    runApp(
      MultiProvider(
        providers: [
          // Provide AppState for global state management
          ChangeNotifierProvider(create: (_) => AppState()),
          // Provide language notifier for localization
          ChangeNotifierProvider.value(
            value: AppLocalizations.languageNotifier,
          ),
        ],
        child: LocalizedApp(delegate, const MyApp()),
      ),
    );
    logger.info('Application started successfully');

    // Set up logger disposal when app is closing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WidgetsBinding.instance.addObserver(_AppLifecycleObserver(logger));
    });
  } catch (e, stackTrace) {
    // Handle initialization errors gracefully
    final logger = AppLogger('main');
    logger.error('Failed to initialize application', e, stackTrace);
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

/// Observer to handle app lifecycle events and logger disposal
class _AppLifecycleObserver with WidgetsBindingObserver {
  final AppLogger _logger;

  _AppLifecycleObserver(this._logger);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached) {
      _logger.info('Application is closing, disposing logger...');
      await AppLogger.dispose();
    }
  }
}

/// The root widget of the application.
/// Sets up the MaterialApp with theme, localization, and routing.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = AppLogger('MyApp');
    try {
      return MaterialApp(
        title: translate('app.title'),
        // Configure app theme
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        // Set up localization delegates
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          LocalizedApp.of(context).delegate,
        ],
        // Define supported locales
        supportedLocales: const [Locale('en'), Locale('cs')],
        // Get current locale from language notifier
        locale: _getCurrentLocale(context),
        // Set up initial route and routing
        home: const AppRouter(),
        routes: {
          '/users': (context) => const UserManagementPage(),
          '/required-image-managment':
              (context) => const RequiredImageModelPage(),
        },
      );
    } catch (e, stackTrace) {
      logger.error('Error building MaterialApp', e, stackTrace);
      return MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error building application: $e')),
        ),
      );
    }
  }

  /// Gets the current locale from the language notifier
  ///
  /// [context] - The build context
  /// Returns the current locale, defaults to English if there's an error
  Locale _getCurrentLocale(BuildContext context) {
    final logger = AppLogger('MyApp');
    try {
      return Locale(context.watch<LanguageNotifier>().currentLanguage);
    } catch (e, stackTrace) {
      logger.error('Error getting current locale', e, stackTrace);
      return const Locale('en'); // Fallback to English
    }
  }
}

/// Handles application routing based on authentication state.
/// Routes to LoginPage if user is not logged in, otherwise to HomePage.
class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = AppLogger('AppRouter');
    try {
      return Consumer<AppState>(
        builder: (context, appState, child) {
          // Use both isLoggedIn and currentLanguage to force rebuilds
          final isLoggedIn = appState.isLoggedIn;
          final currentLanguage = appState.currentLanguage;

          logger.debug(
            'App state changed - isLoggedIn: $isLoggedIn, language: $currentLanguage',
          );

          // Route based on authentication state
          if (!isLoggedIn) {
            return const LoginPage();
          }
          return const HomePage();
        },
      );
    } catch (e, stackTrace) {
      logger.error('Error in AppRouter', e, stackTrace);
      return Scaffold(
        body: Center(child: Text('Error in application routing: $e')),
      );
    }
  }
}
