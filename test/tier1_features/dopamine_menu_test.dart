import 'package:flutter_test/flutter_test.dart';
import 'package:brainrot_tracker_pro/features/interventions/domain/dopamine_item.dart';

void main() {
  group('Tier 1: Dopamine Menu Items & Recovery Point Rewards', () {
    test('1. Default dopamine catalog provides all three categories', () {
      final catalog = DopamineCatalog.defaultItems;

      expect(catalog.isNotEmpty, isTrue);
      final categories = catalog.map((item) => item.category).toSet();
      expect(categories, contains(DopamineCategory.starters));
      expect(categories, contains(DopamineCategory.mains));
      expect(categories, contains(DopamineCategory.desserts));
    });

    test('2. Starters category provides quick +5% health recovery items', () {
      final starters = DopamineCatalog.getItemsByCategory(DopamineCategory.starters);
      expect(starters.length, greaterThanOrEqualTo(3));

      for (final item in starters) {
        expect(item.recoveryPoints, equals(5));
        expect(item.estimatedMinutes, inInclusiveRange(1, 3));
        expect(item.title.isNotEmpty, isTrue);
      }
    });

    test('3. Mains category provides medium-effort +10% health recovery items', () {
      final mains = DopamineCatalog.getItemsByCategory(DopamineCategory.mains);
      expect(mains.length, greaterThanOrEqualTo(3));

      for (final item in mains) {
        expect(item.recoveryPoints, equals(10));
        expect(item.estimatedMinutes, inInclusiveRange(5, 15));
      }
    });

    test('4. Desserts category provides restorative +15% health recovery items', () {
      final desserts = DopamineCatalog.getItemsByCategory(DopamineCategory.desserts);
      expect(desserts.length, greaterThanOrEqualTo(3));

      for (final item in desserts) {
        expect(item.recoveryPoints, equals(15));
        expect(item.title.isNotEmpty, isTrue);
      }
    });

    test('5. Item completion toggles isCompleted status', () {
      final item = DopamineItem(
        id: 'starter_water',
        category: DopamineCategory.starters,
        title: 'Drink a cold glass of water',
        description: 'Hydrate your body and mind',
        recoveryPoints: 5,
        estimatedMinutes: 1,
      );

      expect(item.isCompleted, isFalse);
      final completed = item.copyWith(isCompleted: true);
      expect(completed.isCompleted, isTrue);
      expect(completed.id, equals(item.id));
      expect(completed.recoveryPoints, equals(5));
    });

    test('6. Finding items by ID returns valid immutable instances', () {
      final item = DopamineCatalog.findById('starter_water');
      expect(item, isNotNull);
      expect(item!.category, equals(DopamineCategory.starters));

      final nonexistent = DopamineCatalog.findById('non_existent_id');
      expect(nonexistent, isNull);
    });
  });
}
