import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/core/constants/app_colors.dart';
import 'package:brainrot_tracker_pro/core/platform_bridge/accessibility_channel_bridge.dart';
import 'package:brainrot_tracker_pro/features/banking/presentation/widgets/banking_mode_toggle_card.dart';
import 'package:brainrot_tracker_pro/features/interventions/presentation/controllers/intervention_controller.dart';
import 'package:brainrot_tracker_pro/features/interventions/presentation/screens/breathe_screen.dart';
import 'package:brainrot_tracker_pro/features/interventions/presentation/screens/dopamine_menu_screen.dart';
import 'package:brainrot_tracker_pro/features/interventions/presentation/widgets/velocity_warning_banner.dart';
import 'package:brainrot_tracker_pro/features/pet/presentation/controllers/pet_controller.dart';
import 'package:brainrot_tracker_pro/features/pet/presentation/screens/pet_screen.dart';
import 'package:brainrot_tracker_pro/features/tracking/presentation/controllers/daily_limit_controller.dart';
import 'package:brainrot_tracker_pro/features/tracking/presentation/controllers/operational_settings_controller.dart';
import 'package:brainrot_tracker_pro/features/tracking/presentation/controllers/tracking_controller.dart';
import 'package:brainrot_tracker_pro/features/tracking/presentation/widgets/hourly_usage_chart.dart';
import 'package:brainrot_tracker_pro/features/tracking/presentation/widgets/platform_breakdown_card.dart';
import 'package:brainrot_tracker_pro/features/tracking/presentation/widgets/swipe_counter_card.dart';

/// Main Dashboard Screen providing comprehensive tracking metrics, pet overview, and intervention controls.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isServiceEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkAccessibilityStatus();
  }

  Future<void> _checkAccessibilityStatus() async {
    final enabled = await AccessibilityChannelBridge().isAccessibilityServiceEnabled();
    if (mounted) {
      setState(() => _isServiceEnabled = enabled);
    }
  }

  void _showModeSelectionDialog() {
    final currentMode = ref.read(operationalSettingsProvider).currentMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'OPERATIONAL CPU & BATTERY MODE',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              ...OperationalMode.values.map((mode) {
                final isSelected = mode == currentMode;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    mode == OperationalMode.batterySaver
                        ? Icons.battery_saver
                        : mode == OperationalMode.balanced
                            ? Icons.balance
                            : Icons.offline_bolt,
                    color: isSelected ? AppColors.primary : AppColors.textMuted,
                  ),
                  title: Text(
                    mode.title,
                    style: TextStyle(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    mode.description,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                      : null,
                  onTap: () async {
                    ref.read(operationalSettingsProvider.notifier).setMode(mode);
                    await AccessibilityChannelBridge().setOperationalMode(mode);
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);
    final limitState = ref.watch(dailyLimitProvider);
    final petState = ref.watch(petProvider);
    final interventionState = ref.watch(interventionProvider);
    final operationalState = ref.watch(operationalSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Brainrot Tracker Pro'),
        actions: [
          // Operational Mode Chip Button
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _showModeSelectionDialog,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    operationalState.currentMode == OperationalMode.batterySaver
                        ? Icons.battery_saver
                        : operationalState.currentMode == OperationalMode.balanced
                            ? Icons.balance
                            : Icons.offline_bolt,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    operationalState.currentMode.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async {
          await ref.read(trackingProvider.notifier).refreshStats();
          await _checkAccessibilityStatus();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // Accessibility Service Warning if disabled
            if (!_isServiceEnabled)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.healthDanger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.healthDanger),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.healthDanger, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Accessibility Service Inactive',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Enable Brainrot Accessibility Service to track doomscrolling.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => AccessibilityChannelBridge().openAccessibilitySettings(),
                      child: const Text('ENABLE'),
                    ),
                  ],
                ),
              ),

            // Live Velocity Warning Banner if triggered
            if (interventionState.isVelocityWarningVisible)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: VelocityWarningBanner(
                  currentVelocity: interventionState.currentVelocity,
                  onDismiss: () => ref.read(interventionProvider.notifier).dismissVelocityWarning(),
                  onBreathePressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BreatheScreen(
                          onResume: () => Navigator.of(context).pop(),
                          onExitToMenu: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const DopamineMenuScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Neural Pet Quick Status Banner
            Card(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Color(petState.stage.colorHex).withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const PetScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Color(petState.stage.colorHex).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${petState.stageIndex}',
                            style: TextStyle(
                              color: Color(petState.stage.colorHex),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'NEURAL PET: ${petState.stageLabel.toUpperCase()}',
                                  style: TextStyle(
                                    color: Color(petState.stage.colorHex),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  '${petState.petHealth}% HP',
                                  style: TextStyle(
                                    color: Color(petState.stage.colorHex),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: petState.petHealth / 100.0,
                                minHeight: 6,
                                backgroundColor: AppColors.surfaceLight,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(petState.stage.colorHex)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Today's Cumulative Swipes & Speed
            SwipeCounterCard(
              totalSwipes: trackingState.totalToday,
              currentVelocity: trackingState.currentVelocitySwipesPerMin,
              targetLimit: limitState.targetLimit,
            ),
            const SizedBox(height: 16),

            // Banking Mode Toggle Card
            const BankingModeToggleCard(),
            const SizedBox(height: 16),

            // Platform Breakdown Card
            PlatformBreakdownCard(
              platformCounts: trackingState.platformCounts,
            ),
            const SizedBox(height: 16),

            // 24-Hour Usage Bar Chart
            HourlyUsageChart(
              hourlyBuckets: trackingState.hourlyBuckets,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
