import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:brainrot_tracker_pro/core/constants/app_colors.dart';
import 'package:brainrot_tracker_pro/features/interventions/domain/dopamine_item.dart';
import 'package:brainrot_tracker_pro/features/pet/presentation/controllers/pet_controller.dart';

/// Interactive healthy micro-reward menu offering behavioral alternatives to doomscrolling.
class DopamineMenuScreen extends ConsumerStatefulWidget {
  const DopamineMenuScreen({super.key});

  @override
  ConsumerState<DopamineMenuScreen> createState() => _DopamineMenuScreenState();
}

class _DopamineMenuScreenState extends ConsumerState<DopamineMenuScreen> {
  late List<DopamineItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(DopamineItem.defaultItems);
  }

  void _completeItem(DopamineItem item) {
    if (item.isCompleted) return;

    setState(() {
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        _items[index] = item.copyWith(isCompleted: true);
      }
    });

    // Apply healing bonus to brain pet
    ref.read(petProvider.notifier).applyMindfulRecovery(item.healthRecoveryBonus);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.healthFresh),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.healthFresh, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Completed! Brain health restored +${item.healthRecoveryBonus}%',
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _categoryColor(DopamineCategory cat) {
    switch (cat) {
      case DopamineCategory.starters:
        return AppColors.dopamineStarter;
      case DopamineCategory.mains:
        return AppColors.dopamineMain;
      case DopamineCategory.desserts:
        return AppColors.dopamineDessert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final petState = ref.watch(petProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dopamine Menu'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.healthFresh.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.healthFresh),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, color: AppColors.healthFresh, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${petState.petHealth}% HP',
                  style: const TextStyle(
                    color: AppColors.healthFresh,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Banner description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.spa, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Replace passive doomscrolling with conscious somatic rewards. Completing items heals your neural pet.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Categories
          ...DopamineCategory.values.map((cat) {
            final catItems = _items.where((i) => i.category == cat).toList();
            final catColor = _categoryColor(cat);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: catColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat.title.toUpperCase(),
                      style: TextStyle(
                        color: catColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${cat.subtitle}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...catItems.map((item) {
                  return Card(
                    color: item.isCompleted ? AppColors.surfaceLight.withOpacity(0.5) : AppColors.surface,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: item.isCompleted ? AppColors.healthFresh.withOpacity(0.4) : AppColors.border,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: IconButton(
                        icon: Icon(
                          item.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: item.isCompleted ? AppColors.healthFresh : AppColors.textMuted,
                          size: 24,
                        ),
                        onPressed: () => _completeItem(item),
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: item.isCompleted ? AppColors.textMuted : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(
                        item.description,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+${item.healthRecoveryBonus}%',
                          style: TextStyle(
                            color: catColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      onTap: () => _completeItem(item),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],
            );
          }),
        ],
      ),
    );
  }
}
