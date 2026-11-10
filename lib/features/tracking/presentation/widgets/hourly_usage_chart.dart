import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:brainrot_tracker_pro/core/constants/app_colors.dart';

/// Interactive 24-hour bar chart displaying doomscroll usage distribution across the day.
class HourlyUsageChart extends StatelessWidget {
  final List<int> hourlyBuckets; // 24 buckets (hours 0..23)

  const HourlyUsageChart({
    super.key,
    required this.hourlyBuckets,
  });

  @override
  Widget build(BuildContext context) {
    final List<int> safeBuckets = hourlyBuckets.length == 24
        ? hourlyBuckets
        : List.generate(24, (i) => i < hourlyBuckets.length ? hourlyBuckets[i] : 0);

    final int maxCount = safeBuckets.fold(0, (max, c) => c > max ? c : max);
    final double maxY = maxCount > 0 ? (maxCount * 1.25).ceilToDouble() : 10.0;

    int peakHour = -1;
    int peakValue = 0;
    for (int i = 0; i < 24; i++) {
      if (safeBuckets[i] > peakValue) {
        peakValue = safeBuckets[i];
        peakHour = i;
      }
    }

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '24-HOUR SCROLL PATTERN',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                if (peakValue > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accentNeon.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accentNeon.withOpacity(0.4)),
                    ),
                    child: Text(
                      'Peak: ${_formatHour(peakHour)} ($peakValue)',
                      style: const TextStyle(
                        color: AppColors.accentNeon,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Bar Chart
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.surfaceElevated,
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final hour = group.x;
                        final count = rod.toY.toInt();
                        return BarTooltipItem(
                          '${_formatHour(hour)}\n$count reels',
                          const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: maxY > 20 ? (maxY / 4).roundToDouble() : 5,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == maxY) return const SizedBox.shrink();
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final int hour = value.toInt();
                          if (hour % 4 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                _formatHourSimple(hour),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 20 ? (maxY / 4).roundToDouble() : 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.border.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(24, (hour) {
                    final int count = safeBuckets[hour];
                    final bool isPeak = hour == peakHour && peakValue > 0;

                    return BarChartGroupData(
                      x: hour,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          width: 8,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: isPeak
                                ? [AppColors.accentNeon.withOpacity(0.6), AppColors.accentNeon]
                                : count > 0
                                    ? [AppColors.primaryDark, AppColors.primary]
                                    : [AppColors.surfaceLight, AppColors.surfaceLight],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatHour(int hour) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final ampm = hour < 12 ? 'AM' : 'PM';
    return '$h $ampm';
  }

  static String _formatHourSimple(int hour) {
    return '${hour.toString().padLeft(2, '0')}:00';
  }
}
