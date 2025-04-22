import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'state/app_state.dart';
import 'presentation/pages/login/login_page.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/pages/user_managment/user_management_page.dart';
import 'localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LocalizedApp(
      LocalizedApp.of(context)?.delegate ?? LocalizationDelegate.empty(),
      MaterialApp(
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
        home: Consumer<AppState>(
          builder: (context, appState, child) {
            if (!appState.isLoggedIn) {
              return const LoginPage();
            }
            return const HomePage();
          },
        ),
        routes: {'/users': (context) => const UserManagementPage()},
      ),
    );
  }
}
