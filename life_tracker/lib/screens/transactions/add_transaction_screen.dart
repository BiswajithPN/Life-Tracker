import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/neon_button.dart';
import '../../state/transaction_provider.dart';
import '../../state/category_provider.dart';
import '../../models/transaction_model.dart';

class AddTransactionModal extends ConsumerStatefulWidget {
  const AddTransactionModal({super.key});

  @override
  ConsumerState<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends ConsumerState<AddTransactionModal> {
  bool isExpense = true;
  String? selectedCategory;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  void _saveTransaction() {
    if (_amountController.text.isEmpty || _titleController.text.isEmpty || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          backgroundColor: AppTheme.glowingRed.withValues(alpha: 0.8),
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Enter a valid amount'),
          backgroundColor: AppTheme.glowingRed.withValues(alpha: 0.8),
        ),
      );
      return;
    }

    final newTransaction = TransactionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      amount: amount,
      category: selectedCategory!,
      type: isExpense ? 'expense' : 'income',
      date: DateTime.now(),
    );

    ref.read(transactionProvider.notifier).addTransaction(newTransaction);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = ref.watch(categoryProvider);
    final type = isExpense ? 'expense' : 'income';
    final filteredCategories = allCategories.where((c) => c.type == type).toList();

    // Reset selected category if type changes and current selection is invalid
    if (selectedCategory != null &&
        !filteredCategories.any((c) => c.name == selectedCategory)) {
      selectedCategory = null;
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
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
          const SizedBox(height: 24),

          // Type Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isExpense = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isExpense ? AppTheme.glowingRed.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: isExpense ? AppTheme.getNeonGlow(color: AppTheme.glowingRed, intensity: 0.5) : [],
                      ),
                      child: Text(
                        'EXPENSE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isExpense ? AppTheme.glowingRed : Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isExpense = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isExpense ? AppTheme.accentCyan.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: !isExpense ? AppTheme.getNeonGlow(color: AppTheme.accentCyan, intensity: 0.5) : [],
                      ),
                      child: Text(
                        'INCOME',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !isExpense ? AppTheme.accentCyan : Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Amount Input
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white54,
                    fontSize: 40,
                  ),
                ),
                const SizedBox(width: 8),
                IntrinsicWidth(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 48),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      hintStyle: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white24,
                        fontSize: 48,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Title Input
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'What was this for?',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Dynamic Categories from Provider
          if (filteredCategories.isEmpty)
            Text(
              'No $type categories. Add in Profile →',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
              textAlign: TextAlign.center,
            )
          else
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filteredCategories.length,
                itemBuilder: (context, index) {
                  final category = filteredCategories[index];
                  final isSelected = category.name == selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => selectedCategory = category.name),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isExpense ? AppTheme.glowingRed.withValues(alpha: 0.2) : AppTheme.accentCyan.withValues(alpha: 0.2))
                            : Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? (isExpense ? AppTheme.glowingRed : AppTheme.accentCyan)
                              : Colors.white12,
                        ),
                      ),
                      child: Text(
                        category.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 28),

          NeonButton(
            onPressed: _saveTransaction,
            text: 'ADD LOG',
            glowColor: isExpense ? AppTheme.glowingRed : AppTheme.accentCyan,
          ),
        ],
      ),
    );
  }
}
