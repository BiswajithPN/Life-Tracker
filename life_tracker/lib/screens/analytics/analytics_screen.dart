import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/floating_glass_card.dart';
import '../../state/transaction_provider.dart';
import '../../state/user_provider.dart';
import '../../services/invoice_service.dart';
import '../../models/transaction_model.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _isGeneratingPdf = false;

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final notifier = ref.read(transactionProvider.notifier);
    final user = ref.watch(userProvider);
    final totalIncome = notifier.totalIncome;
    final totalExpense = notifier.totalExpense;
    final balance = totalIncome - totalExpense;

    // Build category breakdown for expenses and income
    final Map<String, Map<String, double>> expenseByCategoryAndItem = {};
    final Map<String, Map<String, double>> incomeByCategoryAndItem = {};
    for (final tx in transactions) {
      if (tx.type == 'expense') {
        expenseByCategoryAndItem.putIfAbsent(tx.category, () => {});
        expenseByCategoryAndItem[tx.category]![tx.title] =
            (expenseByCategoryAndItem[tx.category]![tx.title] ?? 0) + tx.amount;
      } else {
        incomeByCategoryAndItem.putIfAbsent(tx.category, () => {});
        incomeByCategoryAndItem[tx.category]![tx.title] =
            (incomeByCategoryAndItem[tx.category]![tx.title] ?? 0) + tx.amount;
      }
    }

    // Daily spending for the current month
    final now = DateTime.now();
    final thisMonthTx = transactions.where(
        (t) => t.date.month == now.month && t.date.year == now.year).toList();
    final Map<int, double> dailyExpense = {};
    final Map<int, double> dailyIncome = {};
    for (final tx in thisMonthTx) {
      if (tx.type == 'expense') {
        dailyExpense[tx.date.day] = (dailyExpense[tx.date.day] ?? 0) + tx.amount;
      } else {
        dailyIncome[tx.date.day] = (dailyIncome[tx.date.day] ?? 0) + tx.amount;
      }
    }

    // Monthly totals for the year
    final Map<int, double> monthlyExpense = {};
    final Map<int, double> monthlyIncome = {};
    for (final tx in transactions) {
      if (tx.date.year == now.year) {
        if (tx.type == 'expense') {
          monthlyExpense[tx.date.month] = (monthlyExpense[tx.date.month] ?? 0) + tx.amount;
        } else {
          monthlyIncome[tx.date.month] = (monthlyIncome[tx.date.month] ?? 0) + tx.amount;
        }
      }
    }

    // Top spenders
    final Map<String, double> spenderMap = {};
    for (final tx in transactions.where((t) => t.type == 'expense')) {
      spenderMap[tx.title] = (spenderMap[tx.title] ?? 0) + tx.amount;
    }
    final topSpenders = spenderMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Average daily spending
    final Set<String> daysWithExpense = {};
    for (final tx in transactions.where((t) => t.type == 'expense')) {
      daysWithExpense.add('${tx.date.year}-${tx.date.month}-${tx.date.day}');
    }
    final avgDailySpend = daysWithExpense.isNotEmpty
        ? totalExpense / daysWithExpense.length
        : 0.0;

    // Saving rate
    final savingRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome * 100) : 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ANALYTICS',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          if (transactions.isNotEmpty)
            IconButton(
              icon: _isGeneratingPdf
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentCyan),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.accentCyan),
              tooltip: 'Download PDF Invoice',
              onPressed: _isGeneratingPdf ? null : () => _showMonthPicker(context, transactions, user?.username ?? 'User'),
            ),
        ],
      ),
      body: transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart, size: 64, color: AppTheme.accentPurple.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No data yet',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5), fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add some transactions to see analytics',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3), fontSize: 13),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PDF Download Banner
                  GestureDetector(
                    onTap: () => _showMonthPicker(context, transactions, user?.username ?? 'User'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accentCyan.withValues(alpha: 0.15),
                            AppTheme.accentPurple.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.accentCyan.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.picture_as_pdf, color: AppTheme.accentCyan, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Download Monthly Invoice',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 2),
                                Text('Generate PDF report of your transactions',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                                    )),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.accentCyan),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Stats Row
                  _sectionHeader(context, 'QUICK STATS'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _quickStatCard(context, 'Saving Rate',
                          '${savingRate.toStringAsFixed(1)}%',
                          savingRate >= 20 ? AppTheme.accentCyan : AppTheme.glowingRed,
                          savingRate >= 20 ? Icons.trending_up : Icons.trending_down)),
                      const SizedBox(width: 12),
                      Expanded(child: _quickStatCard(context, 'Avg Daily Spend',
                          '₹${avgDailySpend.toStringAsFixed(0)}',
                          AppTheme.accentMagenta, Icons.calendar_today)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _quickStatCard(context, 'Total Logs',
                          '${transactions.length}',
                          AppTheme.accentPurple, Icons.receipt_long)),
                      const SizedBox(width: 12),
                      Expanded(child: _quickStatCard(context, 'This Month',
                          '${thisMonthTx.length} logs',
                          AppTheme.accentCyan, Icons.date_range)),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Income vs Expense Overview
                  _sectionHeader(context, 'INCOME vs EXPENSE'),
                  const SizedBox(height: 16),
                  FloatingGlassCard(
                    glowColor: AppTheme.accentPurple,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statColumn(context, 'INCOME', '₹${totalIncome.toStringAsFixed(0)}', AppTheme.accentCyan),
                            Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                            _statColumn(context, 'EXPENSE', '₹${totalExpense.toStringAsFixed(0)}', AppTheme.glowingRed),
                            Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
                            _statColumn(context, 'BALANCE', '₹${balance.toStringAsFixed(0)}',
                                balance >= 0 ? AppTheme.accentCyan : AppTheme.glowingRed),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                show: true,
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      switch (value.toInt()) {
                                        case 0:
                                          return const Text('Income', style: TextStyle(fontSize: 11));
                                        case 1:
                                          return const Text('Expense', style: TextStyle(fontSize: 11));
                                        default:
                                          return const Text('');
                                      }
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                BarChartGroupData(x: 0, barRods: [
                                  BarChartRodData(
                                    toY: totalIncome,
                                    color: AppTheme.accentCyan,
                                    width: 40,
                                    borderRadius: BorderRadius.circular(8),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: totalIncome == 0 && totalExpense == 0 ? 100 : (totalIncome > totalExpense ? totalIncome : totalExpense) * 1.2,
                                      color: AppTheme.accentCyan.withValues(alpha: 0.05),
                                    ),
                                  ),
                                ]),
                                BarChartGroupData(x: 1, barRods: [
                                  BarChartRodData(
                                    toY: totalExpense,
                                    color: AppTheme.glowingRed,
                                    width: 40,
                                    borderRadius: BorderRadius.circular(8),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: totalIncome == 0 && totalExpense == 0 ? 100 : (totalIncome > totalExpense ? totalIncome : totalExpense) * 1.2,
                                      color: AppTheme.glowingRed.withValues(alpha: 0.05),
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Monthly Trend Chart
                  if (monthlyExpense.isNotEmpty || monthlyIncome.isNotEmpty) ...[
                    _sectionHeader(context, 'MONTHLY TREND (${now.year})'),
                    const SizedBox(height: 16),
                    FloatingGlassCard(
                      glowColor: AppTheme.accentCyan,
                      child: SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: _getMaxMonthly(monthlyIncome, monthlyExpense) / 4,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.white.withValues(alpha: 0.05),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                                    if (value.toInt() >= 1 && value.toInt() <= 12) {
                                      return Text(months[value.toInt() - 1],
                                          style: const TextStyle(fontSize: 10));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 1,
                            maxX: 12,
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(12, (i) {
                                  final m = i + 1;
                                  return FlSpot(m.toDouble(), monthlyIncome[m] ?? 0);
                                }),
                                isCurved: true,
                                color: AppTheme.accentCyan,
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppTheme.accentCyan.withValues(alpha: 0.08),
                                ),
                              ),
                              LineChartBarData(
                                spots: List.generate(12, (i) {
                                  final m = i + 1;
                                  return FlSpot(m.toDouble(), monthlyExpense[m] ?? 0);
                                }),
                                isCurved: true,
                                color: AppTheme.glowingRed,
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppTheme.glowingRed.withValues(alpha: 0.08),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legendDot(AppTheme.accentCyan, 'Income'),
                          const SizedBox(width: 16),
                          _legendDot(AppTheme.glowingRed, 'Expense'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Day of Week Spending
                  if (transactions.any((t) => t.type == 'expense')) ...[
                    _sectionHeader(context, 'SPENDING BY DAY OF WEEK'),
                    const SizedBox(height: 16),
                    FloatingGlassCard(
                      glowColor: AppTheme.accentPurple,
                      child: SizedBox(
                        height: 200,
                        child: _DayOfWeekChart(transactions: transactions),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Expense Breakdown
                  if (expenseByCategoryAndItem.isNotEmpty && totalExpense > 0) ...[
                    _sectionHeader(context, 'SPENDING BREAKDOWN'),
                    const SizedBox(height: 16),
                    FloatingGlassCard(
                      glowColor: AppTheme.glowingRed,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 3,
                                centerSpaceRadius: 40,
                                sections: _buildPieSections(
                                  expenseByCategoryAndItem.map(
                                    (k, v) => MapEntry(k, v.values.fold(0.0, (s, a) => s + a)),
                                  ),
                                  totalExpense,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...expenseByCategoryAndItem.entries.map((catEntry) {
                            final catName = catEntry.key;
                            final catTotal = catEntry.value.values.fold(0.0, (s, a) => s + a);
                            final percent = totalExpense > 0 ? (catTotal / totalExpense * 100) : 0;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _getCategoryColor(catName),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(catName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
                                      Text('₹${catTotal.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Text('${percent.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...catEntry.value.entries.map((itemEntry) {
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 24, top: 2, bottom: 2),
                                      child: Row(
                                        children: [
                                          Icon(Icons.subdirectory_arrow_right, size: 14, color: Colors.white.withValues(alpha: 0.3)),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(itemEntry.key, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13))),
                                          Text('₹${itemEntry.value.toStringAsFixed(0)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                                        ],
                                      ),
                                    );
                                  }),
                                  const Divider(color: Colors.white10, height: 16),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Top Spenders
                  if (topSpenders.isNotEmpty) ...[
                    _sectionHeader(context, 'TOP EXPENSES'),
                    const SizedBox(height: 12),
                    ...topSpenders.take(5).map((entry) {
                      final percent = totalExpense > 0 ? (entry.value / totalExpense) : 0.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: FloatingGlassCard(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(entry.key,
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Text('₹${entry.value.toStringAsFixed(0)}',
                                      style: const TextStyle(color: AppTheme.glowingRed, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                                  color: AppTheme.glowingRed,
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 28),

                  // Income Breakdown
                  if (incomeByCategoryAndItem.isNotEmpty) ...[
                    _sectionHeader(context, 'INCOME SOURCES'),
                    const SizedBox(height: 16),
                    ...incomeByCategoryAndItem.entries.map((catEntry) {
                      final catName = catEntry.key;
                      final catTotal = catEntry.value.values.fold(0.0, (s, a) => s + a);
                      final percent = totalIncome > 0 ? (catTotal / totalIncome) : 0.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: FloatingGlassCard(
                          glowColor: AppTheme.accentCyan,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(catName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text('₹${catTotal.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: (percent * 100).toInt().clamp(1, 100),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentCyan,
                                          borderRadius: BorderRadius.circular(4),
                                          boxShadow: AppTheme.getNeonGlow(color: AppTheme.accentCyan, intensity: 0.6),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: (100 - (percent * 100).toInt()).clamp(0, 99),
                                      child: const SizedBox(),
                                    ),
                                  ],
                                ),
                              ),
                              if (catEntry.value.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                ...catEntry.value.entries.map((itemEntry) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.subdirectory_arrow_right, size: 14, color: AppTheme.accentCyan.withValues(alpha: 0.5)),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(itemEntry.key, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13))),
                                        Text('₹${itemEntry.value.toStringAsFixed(0)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  double _getMaxMonthly(Map<int, double> income, Map<int, double> expense) {
    double max = 1;
    for (final v in income.values) {
      if (v > max) max = v;
    }
    for (final v in expense.values) {
      if (v > max) max = v;
    }
    return max;
  }

  void _showMonthPicker(BuildContext context, List transactions, String username) {
    final now = DateTime.now();
    int selectedMonth = now.month;
    int selectedYear = now.year;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Generate PDF Invoice', style: TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select month and year for the invoice:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedMonth,
                      decoration: InputDecoration(
                        labelText: 'Month',
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: List.generate(12, (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(DateFormat('MMM').format(DateTime(2024, i + 1)),
                            style: const TextStyle(fontSize: 14)),
                      )),
                      onChanged: (v) => setDialogState(() => selectedMonth = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedYear,
                      decoration: InputDecoration(
                        labelText: 'Year',
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: List.generate(5, (i) => DropdownMenuItem(
                        value: now.year - 2 + i,
                        child: Text('${now.year - 2 + i}', style: const TextStyle(fontSize: 14)),
                      )),
                      onChanged: (v) => setDialogState(() => selectedYear = v!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _generatePdf(transactions, username, selectedMonth, selectedYear);
              },
              child: const Text('GENERATE', style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePdf(List transactions, String username, int month, int year) async {
    setState(() => _isGeneratingPdf = true);

    try {
      final file = await InvoiceService.generateMonthlyInvoice(
        username: username,
        transactions: transactions.cast(),
        month: month,
        year: year,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ PDF Generated! Opening...'),
            backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.8),
          ),
        );
      }

      await InvoiceService.openPdf(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppTheme.glowingRed.withValues(alpha: 0.8),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Widget _quickStatCard(BuildContext context, String label, String value, Color color, IconData icon) {
    return FloatingGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _statColumn(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(Map<String, double> data, double total) {
    return data.entries.map((e) {
      final percent = total > 0 ? (e.value / total * 100) : 0.0;
      return PieChartSectionData(
        color: _getCategoryColor(e.key),
        value: e.value,
        title: '${percent.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      );
    }).toList();
  }

  static final _colorPalette = [
    AppTheme.glowingRed,
    AppTheme.accentCyan,
    AppTheme.accentMagenta,
    AppTheme.accentPurple,
    const Color(0xFFFFB347),
    const Color(0xFF77DD77),
    const Color(0xFF6EB5FF),
    const Color(0xFFFFD700),
  ];

  Color _getCategoryColor(String category) {
    final index = category.hashCode.abs() % _colorPalette.length;
    return _colorPalette[index];
  }
}

class _DayOfWeekChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const _DayOfWeekChart({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final Map<int, double> dowSpend = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    double maxVal = 100;

    for (var tx in transactions.where((t) => t.type == 'expense')) {
      dowSpend[tx.date.weekday] = (dowSpend[tx.date.weekday] ?? 0) + tx.amount;
    }

    for (var val in dowSpend.values) {
      if (val > maxVal) maxVal = val;
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.2,
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                if (value >= 1 && value <= 7) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(days[value.toInt() - 1], style: const TextStyle(fontSize: 11)),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal / 3,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.05),
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (int i = 1; i <= 7; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: dowSpend[i] ?? 0,
                  color: AppTheme.accentPurple,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxVal * 1.2,
                    color: AppTheme.accentPurple.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

