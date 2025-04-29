import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fve_installer_reminder/presentation/widgets/app_top_bar.dart';
import 'package:fve_installer_reminder/state/app_state.dart';
import 'package:fve_installer_reminder/presentation/widgets/language_selector.dart';
import 'package:fve_installer_reminder/data/models/user.dart';

/// A mock AppState class for testing that allows setting the current user
class MockAppState extends AppState {
  User? _mockCurrentUser;

  @override
  User? get currentUser => _mockCurrentUser;

  @override
  bool get isLoggedIn => _mockCurrentUser != null;

  @override
  bool get isPrivileged => _mockCurrentUser?.isPrivileged ?? false;

  @override
  int get currentUserPrivileges => _mockCurrentUser?.privileges ?? 0;

  void setCurrentUser(User? user) {
    _mockCurrentUser = user;
    notifyListeners();
  }
}

void main() {
  late MockAppState mockAppState;

  setUp(() {
    mockAppState = MockAppState();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<AppState>.value(
        value: mockAppState,
        child: const Scaffold(appBar: AppTopBar()),
      ),
    );
  }

  group('AppTopBar Widget Tests', () {
    testWidgets('renders basic app bar with title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(AppTopBar), findsOneWidget);
      expect(find.byType(LanguageSelector), findsOneWidget);
    });

    testWidgets('shows cloud status indicator with different states', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Test disconnected state
      mockAppState.updateCloudStatus(CloudStatus.disconnected);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);

      // Test connected state
      mockAppState.updateCloudStatus(CloudStatus.connected);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud), findsOneWidget);

      // Test syncing state
      mockAppState.updateCloudStatus(CloudStatus.syncing);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.cloud), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows admin buttons when user is admin', (
      WidgetTester tester,
    ) async {
      // Create a mock user with admin privileges
      final mockUser = User(
        id: 1,
        username: 'admin',
        password: 'password',
        privileges: 3, // Admin privilege level
        active: true,
      );
      mockAppState.setCurrentUser(mockUser);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.text('required_images.management.title'), findsOneWidget);
    });

    testWidgets('hides admin buttons when user is not admin', (
      WidgetTester tester,
    ) async {
      // Create a mock user without admin privileges
      final mockUser = User(
        id: 1,
        username: 'user',
        password: 'password',
        privileges: 1, // Builder privilege level
        active: true,
      );
      mockAppState.setCurrentUser(mockUser);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.people), findsNothing);
      expect(find.text('required_images.management.title'), findsNothing);
    });

    testWidgets('shows logout button when user is logged in', (
      WidgetTester tester,
    ) async {
      // Create a mock logged in user
      final mockUser = User(
        id: 1,
        username: 'user',
        password: 'password',
        privileges: 1,
        active: true,
      );
      mockAppState.setCurrentUser(mockUser);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('hides logout button when user is not logged in', (
      WidgetTester tester,
    ) async {
      mockAppState.setCurrentUser(null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout), findsNothing);
    });

    testWidgets('shows logout confirmation dialog when logout is pressed', (
      WidgetTester tester,
    ) async {
      // Create a mock logged in user
      final mockUser = User(
        id: 1,
        username: 'user',
        password: 'password',
        privileges: 1,
        active: true,
      );
      mockAppState.setCurrentUser(mockUser);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('logout.confirm'), findsOneWidget);
      expect(find.text('logout.message'), findsOneWidget);
      expect(find.text('common.cancel'), findsOneWidget);
      expect(find.text('common.confirm'), findsOneWidget);
    });

    testWidgets('performs logout when confirmed', (WidgetTester tester) async {
      // Create a mock logged in user
      final mockUser = User(
        id: 1,
        username: 'user',
        password: 'password',
        privileges: 1,
        active: true,
      );
      mockAppState.setCurrentUser(mockUser);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      await tester.tap(find.text('common.confirm'));
      await tester.pumpAndSettle();

      expect(mockAppState.isLoggedIn, false);
    });
  });
}
