/// 7 Distinct stages of Brain Rot progression.
enum BrainRotStage {
  fresh(0, 0, 'Fresh', 'Clean neural clarity. No doomscrolling detected.', 0xFF10B981),
  bruised(1, 10, 'Bruised', 'Initial short-form fatigue. Focus drifting.', 0xFF38BDF8),
  foggy(2, 25, 'Foggy', 'Neural fog thickening. Synaptic delay detected.', 0xFF818CF8),
  fried(3, 50, 'Fried', 'Dopamine circuits overheating. Surface cracking.', 0xFFF59E0B),
  mushy(4, 100, 'Mushy', 'Severe sensory overload. Toxic slime dripping.', 0xFF84CC16),
  rotting(5, 175, 'Rotting', 'Severe neural rot. Smoke rising continuously.', 0xFFEF4444),
  brainRot(6, 250, 'Brain rot', 'CRITICAL BRAIN ROT! Immediate intervention needed!', 0xFFB91C1C);

  const BrainRotStage(
    this.stageIndex,
    this.thresholdSwipes,
    this.label,
    this.description,
    this.colorHex,
  );

  final int stageIndex;
  final int thresholdSwipes;
  final String label;
  final String description;
  final int colorHex;

  String get assetPath => 'assets/images/brain_stage_$stageIndex.png';

  bool get isSlimy => stageIndex >= 4;
  bool get isSmoking => stageIndex >= 5;
  bool get isCritical => stageIndex >= 6;

  static BrainRotStage fromIndex(int index) {
    if (index < 0) return BrainRotStage.fresh;
    if (index >= BrainRotStage.values.length) return BrainRotStage.brainRot;
    return BrainRotStage.values[index];
  }

  static BrainRotStage fromSwipeCount(int count) {
    for (int i = BrainRotStage.values.length - 1; i >= 0; i--) {
      if (count >= BrainRotStage.values[i].thresholdSwipes) {
        return BrainRotStage.values[i];
      }
    }
    return BrainRotStage.fresh;
  }
}
