import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/core/constants/app_constants.dart';

/// Operational CPU & battery modes.
enum OperationalMode {
  batterySaver(AppConstants.modeBatterySaver, 'Battery Saver', '300ms debounce, particles disabled for maximum battery life.'),
  balanced(AppConstants.modeBalanced, 'Balanced', '80ms debounce, standard animations and lightweight particles.'),
  performance(AppConstants.modePerformance, 'Performance', '40ms instant debounce, full particle physics and dynamic effects.');

  const OperationalMode(this.id, this.title, this.description);

  final String id;
  final String title;
  final String description;

  static OperationalMode fromId(String id) {
    return OperationalMode.values.firstWhere(
      (m) => m.id == id,
      orElse: () => OperationalMode.balanced,
    );
  }
}

/// State for operational settings.
class OperationalSettingsState {
  final OperationalMode currentMode;
  final bool isBatteryOptimizationIgnored;

  const OperationalSettingsState({
    this.currentMode = OperationalMode.balanced,
    this.isBatteryOptimizationIgnored = false,
  });

  OperationalSettingsState copyWith({
    OperationalMode? currentMode,
    bool? isBatteryOptimizationIgnored,
  }) {
    return OperationalSettingsState(
      currentMode: currentMode ?? this.currentMode,
      isBatteryOptimizationIgnored: isBatteryOptimizationIgnored ?? this.isBatteryOptimizationIgnored,
    );
  }
}

/// Notifier for operational settings.
class OperationalSettingsNotifier extends StateNotifier<OperationalSettingsState> {
  OperationalSettingsNotifier() : super(const OperationalSettingsState());

  void setMode(OperationalMode mode) {
    state = state.copyWith(currentMode: mode);
  }

  void setBatteryOptimizationIgnored(bool ignored) {
    state = state.copyWith(isBatteryOptimizationIgnored: ignored);
  }
}

/// Provider for operational settings.
final operationalSettingsProvider =
    StateNotifierProvider<OperationalSettingsNotifier, OperationalSettingsState>((ref) {
  return OperationalSettingsNotifier();
});
