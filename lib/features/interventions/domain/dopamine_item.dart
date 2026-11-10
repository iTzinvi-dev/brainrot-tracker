/// Categories for the healthy Dopamine Menu.
enum DopamineCategory {
  starters('Starters', 'Quick 1-2 min somatic resets', 5),
  mains('Mains', '5-15 min intentional breaks', 10),
  desserts('Desserts', 'Social & creative restorative activities', 15);

  const DopamineCategory(this.title, this.subtitle, this.healthBonusPercent);

  final String title;
  final String subtitle;
  final int healthBonusPercent;
}

/// An actionable restorative micro-activity in the Dopamine Menu.
class DopamineItem {
  final String id;
  final String title;
  final String description;
  final DopamineCategory category;
  final int healthRecoveryBonus; // percentage points
  final int estimatedMinutes;
  final bool isCompleted;

  /// Compatibility getter for test suite asserting `recoveryPoints`
  int get recoveryPoints => healthRecoveryBonus;

  const DopamineItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    int? healthRecoveryBonus,
    int? recoveryPoints,
    this.estimatedMinutes = 5,
    this.isCompleted = false,
  }) : healthRecoveryBonus = healthRecoveryBonus ?? recoveryPoints ?? 5;

  DopamineItem copyWith({
    String? id,
    String? title,
    String? description,
    DopamineCategory? category,
    int? healthRecoveryBonus,
    int? recoveryPoints,
    int? estimatedMinutes,
    bool? isCompleted,
  }) {
    return DopamineItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      healthRecoveryBonus: healthRecoveryBonus ?? recoveryPoints ?? this.healthRecoveryBonus,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// Default curated Dopamine Menu items delegating to DopamineCatalog.
  static List<DopamineItem> get defaultItems => DopamineCatalog.defaultItems;
}

/// Curated catalog and query provider for Dopamine Menu items.
class DopamineCatalog {
  DopamineCatalog._();

  static const List<DopamineItem> defaultItems = [
    // Starters (1-3 minutes, +5% health recovery)
    DopamineItem(
      id: 'starter_water',
      title: 'Drink a cold glass of water',
      description: 'Hydrate your body and break the dopamine autopilot loop.',
      category: DopamineCategory.starters,
      healthRecoveryBonus: 5,
      estimatedMinutes: 1,
    ),
    DopamineItem(
      id: 'starter_stretch',
      title: '5 Shoulder rolls & arm stretch',
      description: 'Release physical tension accumulated from tech neck posture.',
      category: DopamineCategory.starters,
      healthRecoveryBonus: 5,
      estimatedMinutes: 2,
    ),
    DopamineItem(
      id: 'starter_eyes_20_20',
      title: '20-20-20 Eye break',
      description: 'Look at an object 20 feet away for 20 seconds to relax ciliary muscles.',
      category: DopamineCategory.starters,
      healthRecoveryBonus: 5,
      estimatedMinutes: 1,
    ),

    // Mains (5-15 minutes, +10% health recovery)
    DopamineItem(
      id: 'main_sunlight',
      title: 'Step outside for natural sunlight',
      description: 'Sunlight on retinas stimulates dopamine and regulates circadian rhythm.',
      category: DopamineCategory.mains,
      healthRecoveryBonus: 10,
      estimatedMinutes: 10,
    ),
    DopamineItem(
      id: 'main_reading',
      title: 'Read 5 pages of a physical book',
      description: 'Train sustained linear attention without hyper-stimulative cuts.',
      category: DopamineCategory.mains,
      healthRecoveryBonus: 10,
      estimatedMinutes: 12,
    ),
    DopamineItem(
      id: 'main_movement',
      title: 'Quick 10 pushups or squats',
      description: 'Boost endorphins and blood circulation naturally.',
      category: DopamineCategory.mains,
      healthRecoveryBonus: 10,
      estimatedMinutes: 5,
    ),

    // Desserts (restorative activities, +15% health recovery)
    DopamineItem(
      id: 'dessert_friend_voice_note',
      title: 'Send a genuine voice note to a friend',
      description: 'Cultivate authentic human connection instead of parasocial consumption.',
      category: DopamineCategory.desserts,
      healthRecoveryBonus: 15,
      estimatedMinutes: 5,
    ),
    DopamineItem(
      id: 'dessert_mindful_music',
      title: 'Listen to 1 full track with eyes closed',
      description: 'Deep auditory immersion without competing visual stimulation.',
      category: DopamineCategory.desserts,
      healthRecoveryBonus: 15,
      estimatedMinutes: 4,
    ),
    DopamineItem(
      id: 'dessert_tea_ritual',
      title: 'Mindful herbal tea brewing',
      description: 'Slow sensory ritual focusing on aroma and warmth.',
      category: DopamineCategory.desserts,
      healthRecoveryBonus: 15,
      estimatedMinutes: 8,
    ),
  ];

  /// Filters items by the specified [category].
  static List<DopamineItem> getItemsByCategory(DopamineCategory category) {
    return defaultItems.where((item) => item.category == category).toList();
  }

  /// Finds an item by its unique [id], or returns null if not found.
  static DopamineItem? findById(String id) {
    try {
      return defaultItems.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }
}
