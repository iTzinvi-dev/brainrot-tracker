import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/sign_in_form.dart';
import '../widgets/sign_up_form.dart';
import '../widgets/social_auth_buttons.dart';

/// Cyber-themed authentication portal for Brainrot Tracker Pro.
/// Features dual-tab navigation between Sign In and Sign Up with full security controls.
class AuthScreen extends StatefulWidget {
  final int initialTabIndex;

  const AuthScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Branding & Logo
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surfaceLight,
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.psychology_rounded,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'BRAINROT TRACKER PRO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Anti-Doomscroll Defense Protocol',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Cyber Tab Bar
                  Container(
                    height: 48,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: AppColors.background,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.8,
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(
                          key: Key('auth_tab_sign_in'),
                          text: 'SIGN IN',
                        ),
                        Tab(
                          key: Key('auth_tab_sign_up'),
                          text: 'SIGN UP',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Animated Form View
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      return IndexedStack(
                        index: _tabController.index,
                        children: const [
                          SignInForm(),
                          SignUpForm(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const SocialAuthButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
