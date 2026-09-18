import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_theme.dart';
import '../models/transaction.dart';

enum _Granularity { day, week, month }

enum FlowRange {
  week('7D', _Granularity.day, 7),
  month('1M', _Granularity.day, 30),
  threeMonths('3M', _Granularity.week, 13),
  sixMonths('6M', _Granularity.month, 6),
  year('1Y', _Granularity.month, 12),
  all('All', _Granularity.month, 24); // fallback count; recalculated for "all"

  final String label;
  final _Granularity granularity;
  final int count;
  const FlowRange(this.label, this.granularity, this.count);
}

/// Line chart comparing money in vs money out, with a switchable time
/// range (7 days / 1 month / 3 months / 6 months / 1 year / all time).
///
/// NOTE: this aggregates whatever is in [transactions] on the client.
/// For 6M/1Y/All to be accurate, the caller needs to supply a wide enough
/// transaction window (see AccountProvider) — ideally these longer ranges
/// would be served by a backend endpoint that aggregates by date instead
/// of shipping every raw row to the phone.
class AccountFlowChart extends StatefulWidget {
  final List<BankTransaction> transactions;

  const AccountFlowChart({super.key, required this.transactions});

  @override
  State<AccountFlowChart> createState() => _AccountFlowChartState();
}

class _AccountFlowChartState extends State<AccountFlowChart> {
  FlowRange _range = FlowRange.week;

  DateTime _truncate(DateTime d, _Granularity g) {
    switch (g) {
      case _Granularity.day:
        return DateTime(d.year, d.month, d.day);
      case _Granularity.week:
        final day = DateTime(d.year, d.month, d.day);
        return day.subtract(Duration(days: day.weekday - 1)); // Monday start
      case _Granularity.month:
        return DateTime(d.year, d.month, 1);
    }
  }

  DateTime _shift(DateTime d, _Granularity g, int n) {
    switch (g) {
      case _Granularity.day:
        return d.add(Duration(days: n));
      case _Granularity.week:
        return d.add(Duration(days: n * 7));
      case _Granularity.month:
        return DateTime(d.year, d.month + n, 1);
    }
  }

  int _effectiveCount() {
    if (_range != FlowRange.all) return _range.count;
    // "All": span from the earliest transaction's month to the current
    // month, capped so the chart doesn't try to render an unreasonable
    // number of points if there's years of history.
    final withDates = widget.transactions.where((t) => t.createdAt != null);
    if (withDates.isEmpty) return 12;
    final earliest = withDates
        .map((t) => t.createdAt!)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final now = DateTime.now();
    final months =
        (now.year - earliest.year) * 12 + (now.month - earliest.month) + 1;
    return months.clamp(1, 60);
  }

  List<_Bucket> _buildBuckets() {
    final granularity = _range.granularity;
    final count = _effectiveCount();
    final nowKey = _truncate(DateTime.now(), granularity);

    final buckets = <DateTime, _Bucket>{
      for (int i = count - 1; i >= 0; i--)
        _shift(nowKey, granularity, -i):
            _Bucket(_shift(nowKey, granularity, -i)),
    };

    for (final tx in widget.transactions) {
      final created = tx.createdAt;
      if (created == null) continue;
      final key = _truncate(created, granularity);
      final bucket = buckets[key];
      if (bucket == null) continue; // outside the window
      if (tx.isCredit) {
        bucket.credit += tx.amount;
      } else {
        bucket.debit += tx.amount;
      }
    }

    return buckets.values.toList();
  }

  String _labelFor(_Bucket bucket, int totalCount) {
    switch (_range.granularity) {
      case _Granularity.day:
        return totalCount <= 7
            ? const [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun'
              ][bucket.key.weekday - 1]
            : DateFormat('d/M').format(bucket.key);
      case _Granularity.week:
        return DateFormat('d/M').format(bucket.key);
      case _Granularity.month:
        return DateFormat('MMM').format(bucket.key);
    }
  }

  @override
  Widget build(BuildContext context) {
    final buckets = _buildBuckets();
    final hasActivity = buckets.any((b) => b.credit > 0 || b.debit > 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Account Overview',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              _LegendDot(color: AppColors.success, label: 'In'),
              const SizedBox(width: 14),
              _LegendDot(color: AppColors.danger, label: 'Out'),
            ],
          ),
          const SizedBox(height: 12),
          _RangeSelector(
            selected: _range,
            onChanged: (r) => setState(() => _range = r),
          ),
          const SizedBox(height: 16),
          if (!hasActivity)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No activity in this period',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: _buildChart(buckets),
            ),
        ],
      ),
    );
  }

  Widget _buildChart(List<_Bucket> buckets) {
    final maxVal = buckets
        .map((b) => b.credit > b.debit ? b.credit : b.debit)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final chartMaxY = maxVal <= 0 ? 10.0 : maxVal * 1.25;

    final creditSpots = <FlSpot>[
      for (int i = 0; i < buckets.length; i++)
        FlSpot(i.toDouble(), buckets[i].credit),
    ];
    final debitSpots = <FlSpot>[
      for (int i = 0; i < buckets.length; i++)
        FlSpot(i.toDouble(), buckets[i].debit),
    ];

    // Avoid overlapping x-axis labels when there are many points
    // (e.g. 30 daily buckets for the 1M view).
    final labelInterval = (buckets.length / 6).ceil().clamp(1, buckets.length);

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (buckets.length - 1).toDouble(),
        minY: 0,
        maxY: chartMaxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.textPrimary,
            getTooltipItems: (spots) {
              return spots.map((s) {
                final label = s.barIndex == 0 ? 'In' : 'Out';
                return LineTooltipItem(
                  '$label\n${s.y.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: chartMaxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: labelInterval.toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 ||
                    index >= buckets.length ||
                    index % labelInterval != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _labelFor(buckets[index], buckets.length),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: creditSpots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.success,
            barWidth: 2.5,
            dotData: FlDotData(show: buckets.length <= 14),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.success.withOpacity(0.08),
            ),
          ),
          LineChartBarData(
            spots: debitSpots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppColors.danger,
            barWidth: 2.5,
            dotData: FlDotData(show: buckets.length <= 14),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.danger.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bucket {
  final DateTime key;
  double credit = 0;
  double debit = 0;
  _Bucket(this.key);
}

class _RangeSelector extends StatelessWidget {
  final FlowRange selected;
  final ValueChanged<FlowRange> onChanged;

  const _RangeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final range in FlowRange.values) ...[
            _RangeChip(
              label: range.label,
              selected: range == selected,
              onTap: () => onChanged(range),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.skyTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
