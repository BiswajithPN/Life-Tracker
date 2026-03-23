import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/data/quotes.dart';
import '../../widgets/floating_glass_card.dart';
import '../../state/transaction_provider.dart';
import '../../state/user_provider.dart';
import '../../services/notification_service.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/edit_transaction_screen.dart';
import '../analytics/analytics_screen.dart';
import '../habits/habits_screen.dart';
import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _spendingAlertSent = false;

  void _checkSpendingAlert() {
    final notifier = ref.read(transactionProvider.notifier);
    final totalIncome = notifier.totalIncome;
    final totalExpense = notifier.totalExpense;

    if (totalIncome > 0 && !_spendingAlertSent) {
      final percentage = (totalExpense / totalIncome) * 100;
      if (percentage >= 50) {
        _spendingAlertSent = true;
        NotificationService.showSpendingAlert(percentage);
      }
    }
  }

  void _confirmDelete(BuildContext context, String transactionId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Transaction', style: TextStyle(fontSize: 16)),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(transactionProvider.notifier).deleteTransaction(transactionId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('🗑️ Transaction deleted'),
                  backgroundColor: AppTheme.glowingRed.withValues(alpha: 0.8),
                ),
              );
            },
            child: const Text('DELETE', style: TextStyle(color: AppTheme.glowingRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(transactionProvider);
    final notifier = ref.read(transactionProvider.notifier);
    final user = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quote = QuotesData.getQuoteOfTheDay();

    // Check spending alert whenever transactions change
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSpendingAlert());

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Welcome back,', style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          letterSpacing: 1.2
                        )),
                        const SizedBox(height: 2),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppTheme.accentCyan, AppTheme.accentPurple],
                          ).createShader(bounds),
                          child: Text(
                            user?.username ?? "User",
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                          ),
                          child: Icon(Icons.settings_outlined, size: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileScreen()),
                        ),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppTheme.accentCyan, AppTheme.accentPurple],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              (user?.username ?? 'U')[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable area with FADE effect
            Expanded(
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent, Colors.transparent, Colors.black],
                  stops: const [0.0, 0.05, 0.90, 1.0],
                ).createShader(bounds),
                blendMode: BlendMode.dstOut,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [


            // Motivational Quote of the Day
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentPurple.withValues(alpha: 0.15),
                        AppTheme.accentMagenta.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          quote,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Balance + Income/Expense Summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FloatingGlassCard(
                  glowColor: AppTheme.accentCyan,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL BALANCE',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppTheme.accentCyan, Colors.white],
                        ).createShader(bounds),
                        child: Text(
                          '₹${notifier.totalBalance.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Spending alert banner
                      if (notifier.totalIncome > 0 && (notifier.totalExpense / notifier.totalIncome) >= 0.5)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.glowingRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.glowingRed.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber, color: AppTheme.glowingRed, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '⚠️ You\'ve spent ${((notifier.totalExpense / notifier.totalIncome) * 100).toStringAsFixed(0)}% of your income!',
                                  style: const TextStyle(color: AppTheme.glowingRed, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                      Row(
                        children: [
                          Expanded(
                            child: _summaryChip(context, 'INCOME', '₹${notifier.totalIncome.toStringAsFixed(0)}', AppTheme.accentCyan, Icons.trending_up),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _summaryChip(context, 'EXPENSE', '₹${notifier.totalExpense.toStringAsFixed(0)}', AppTheme.glowingRed, Icons.trending_down),
                          ),
                        ],
                      ),
                      if (transactions.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 60,
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: const FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: (transactions.length - 1).toDouble().clamp(1, 10),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _buildSpots(transactions),
                                  isCurved: true,
                                  color: AppTheme.accentCyan,
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppTheme.accentCyan.withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Recent logs header with hint
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECENT LOGS',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(letterSpacing: 2),
                    ),
                    if (transactions.isNotEmpty)
                      Flexible(
                        child: Text(
                          'Tap to edit • Swipe to delete',
                          style: TextStyle(
                            fontSize: 9,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.4),
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Empty state or transaction list
            if (transactions.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: AppTheme.accentCyan.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text('No transactions yet',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5), fontSize: 16)),
                      const SizedBox(height: 6),
                      Text('Tap + to add your first log',
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.3), fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = transactions[index];
                      final isIncome = tx.type == 'income';
                      return Dismissible(
                        key: Key(tx.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          _confirmDelete(context, tx.id, tx.title);
                          return false; // Don't auto-dismiss, dialog handles it
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.glowingRed.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.glowingRed.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text('DELETE', style: TextStyle(color: AppTheme.glowingRed, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(width: 8),
                              const Icon(Icons.delete_outline, color: AppTheme.glowingRed, size: 22),
                            ],
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => EditTransactionModal(transaction: tx),
                            );
                          },
                          onLongPress: () {
                            _showTransactionOptions(context, tx);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isIncome
                                        ? AppTheme.accentCyan.withValues(alpha: 0.1)
                                        : AppTheme.glowingRed.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isIncome ? Icons.trending_up : Icons.trending_down,
                                    color: isIncome ? AppTheme.accentCyan : AppTheme.glowingRed,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(tx.title,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(tx.category, style: Theme.of(context).textTheme.bodySmall),
                                      const SizedBox(height: 1),
                                      Text(
                                        '${tx.date.day}/${tx.date.month}/${tx.date.year} ${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isIncome ? '+' : '-'}Rs ${tx.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: isIncome ? AppTheme.accentCyan : AppTheme.glowingRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.3),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: transactions.length,
                  ),
                ),
              ),

                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Floating Bottom Navigation
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: (isDark ? AppTheme.surface : Colors.white).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
          boxShadow: AppTheme.getNeonGlow(color: AppTheme.accentCyan, intensity: 0.15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(context, Icons.home, 'Home', AppTheme.accentCyan, active: true, onTap: () {}),
            _navIcon(context, Icons.pie_chart_outline, 'Analytics', null, onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
            }),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppTheme.getNeonGlow(color: AppTheme.accentMagenta, intensity: 0.5),
              ),
              child: FloatingActionButton(
                mini: true,
                backgroundColor: AppTheme.accentMagenta,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddTransactionModal(),
                  );
                },
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ),
            _navIcon(context, Icons.track_changes, 'Habits', null, onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HabitsScreen()));
            }),
          ],
        ),
      ),
    );
  }

  void _showTransactionOptions(BuildContext context, dynamic tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tx.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${tx.type == 'income' ? '+' : '-'}Rs ${tx.amount.toStringAsFixed(2)} • ${tx.category}',
              style: TextStyle(color: tx.type == 'income' ? AppTheme.accentCyan : AppTheme.glowingRed, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_outlined, color: AppTheme.accentCyan, size: 20),
              ),
              title: const Text('Edit Transaction'),
              subtitle: const Text('Modify title, amount, or category', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => EditTransactionModal(transaction: tx),
                );
              },
            ),
            const Divider(height: 1, color: Colors.white10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.glowingRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: AppTheme.glowingRed, size: 20),
              ),
              title: const Text('Delete Transaction', style: TextStyle(color: AppTheme.glowingRed)),
              subtitle: const Text('Remove this transaction permanently', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, tx.id, tx.title);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(BuildContext context, IconData icon, String label, Color? activeColor, {bool active = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? (activeColor ?? AppTheme.accentCyan) : Theme.of(context).textTheme.bodyMedium?.color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9, color: active ? activeColor : Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(BuildContext context, String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildSpots(List transactions) {
    double runningBalance = 0;
    final spots = <FlSpot>[];
    final reversedTx = transactions.reversed.toList();
    for (int i = 0; i < reversedTx.length && i < 10; i++) {
      runningBalance += reversedTx[i].type == 'income' ? reversedTx[i].amount : -reversedTx[i].amount;
      spots.add(FlSpot(i.toDouble(), runningBalance));
    }
    return spots;
  }
}
