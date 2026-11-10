import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/core/constants/app_colors.dart';
import 'package:brainrot_tracker_pro/core/database/database_helper.dart';
import 'package:brainrot_tracker_pro/core/firebase/firebase_service.dart';
import 'package:brainrot_tracker_pro/core/platform_bridge/accessibility_channel_bridge.dart';
import 'package:brainrot_tracker_pro/features/auth/presentation/controllers/auth_controller.dart';
import 'package:brainrot_tracker_pro/features/auth/presentation/screens/auth_screen.dart';
import 'package:brainrot_tracker_pro/features/auth/presentation/widgets/guest_upgrade_dialog.dart';
import 'package:brainrot_tracker_pro/features/interventions/presentation/screens/dopamine_menu_screen.dart';
import 'package:brainrot_tracker_pro/features/pet/presentation/screens/pet_screen.dart';
import 'package:brainrot_tracker_pro/features/tracking/presentation/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive dark status bar and system navigation colors
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize SQLite database instance
  await DatabaseHelper().database;

  // Initialize Firebase with offline persistence and mock fallback
  await FirebaseService.initializeOfflineFirebase();

  runApp(
    const ProviderScope(
      child: BrainrotTrackerApp(),
    ),
  );
}

/// Root application widget configuring dark cyber theme and reactive auth gating.
class BrainrotTrackerApp extends StatelessWidget {
  const BrainrotTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brainrot Tracker Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          error: AppColors.healthDanger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
        cardTheme: CardTheme(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textInverse,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Dynamic routing gate directing unauthenticated users to [AuthScreen]
/// and authenticated or guest users to [MainNavigationShell].
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (authState.isAuthenticated) {
      return const MainNavigationShell();
    }

    return const AuthScreen();
  }
}

/// Navigation Shell hosting Bottom Navigation Bar across Dashboard, Neural Pet, and Dopamine Menu.
class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    PetScreen(),
    DopamineMenuScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Connect Accessibility Bridge EventChannel listeners to Riverpod state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AccessibilityChannelBridge().initializeBridgeListeners(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authControllerProvider).user;
    final isGuest = authUser?.isGuest ?? false;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40),
        child: Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Icon(
                  isGuest ? Icons.visibility_off_outlined : Icons.verified_user_outlined,
                  size: 16,
                  color: isGuest ? AppColors.secondary : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  isGuest ? 'GUEST OPERATIVE' : (authUser?.displayName?.toUpperCase() ?? 'OPERATIVE'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isGuest ? AppColors.secondary : AppColors.primary,
                  ),
                ),
                const Spacer(),
                if (isGuest)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                    ),
                    icon: const Icon(Icons.upgrade, size: 14, color: AppColors.primary),
                    label: const Text(
                      'UPGRADE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const GuestUpgradeDialog(),
                      );
                    },
                  ),
                IconButton(
                  tooltip: 'Sign Out',
                  icon: const Icon(Icons.logout_rounded, size: 16, color: AppColors.textMuted),
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withOpacity(0.2),
        elevation: 0,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.speed_outlined, color: AppColors.textMuted),
            selectedIcon: Icon(Icons.speed, color: AppColors.primary),
            label: 'Tracking',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined, color: AppColors.textMuted),
            selectedIcon: Icon(Icons.psychology, color: AppColors.primary),
            label: 'Neural Pet',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined, color: AppColors.textMuted),
            selectedIcon: Icon(Icons.restaurant_menu, color: AppColors.primary),
            label: 'Dopamine',
          ),
        ],
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
