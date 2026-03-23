import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/floating_glass_card.dart';
import '../../state/user_provider.dart';
import '../../state/category_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final categories = ref.watch(categoryProvider);
    final expenseCategories = categories.where((c) => c.type == 'expense').toList();
    final incomeCategories = categories.where((c) => c.type == 'income').toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'PROFILE',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Card
            FloatingGlassCard(
              glowColor: AppTheme.accentPurple,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentPurple.withValues(alpha: 0.2),
                    ),
                    child: const Icon(Icons.person, size: 32, color: AppTheme.accentPurple),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.username ?? 'Guest',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Manage Categories Section
            _sectionHeader(context, 'EXPENSE CATEGORIES'),
            const SizedBox(height: 12),
            ...expenseCategories.map((cat) => _categoryTile(context, ref, cat.id, cat.name, AppTheme.glowingRed)),
            _addCategoryButton(context, ref, 'expense'),

            const SizedBox(height: 32),
            _sectionHeader(context, 'INCOME CATEGORIES'),
            const SizedBox(height: 12),
            ...incomeCategories.map((cat) => _categoryTile(context, ref, cat.id, cat.name, AppTheme.accentCyan)),
            _addCategoryButton(context, ref, 'income'),

            const SizedBox(height: 40),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(userProvider.notifier).logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout, color: AppTheme.glowingRed),
                label: const Text('LOG OUT', style: TextStyle(color: AppTheme.glowingRed, fontWeight: FontWeight.bold, letterSpacing: 2)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.glowingRed),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        letterSpacing: 2,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _categoryTile(BuildContext context, WidgetRef ref, String id, String name, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: const TextStyle(color: Colors.white)),
          ),
          GestureDetector(
            onTap: () {
              ref.read(categoryProvider.notifier).removeCategory(id);
            },
            child: Icon(Icons.close, size: 18, color: Colors.white.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _addCategoryButton(BuildContext context, WidgetRef ref, String type) {
    return GestureDetector(
      onTap: () => _showAddCategoryDialog(context, ref, type),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (type == 'expense' ? AppTheme.glowingRed : AppTheme.accentCyan).withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 18, color: type == 'expense' ? AppTheme.glowingRed : AppTheme.accentCyan),
            const SizedBox(width: 8),
            Text(
              'ADD ${type.toUpperCase()} CATEGORY',
              style: TextStyle(
                color: type == 'expense' ? AppTheme.glowingRed : AppTheme.accentCyan,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref, String type) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add ${type == "expense" ? "Expense" : "Income"} Category',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Category name',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(categoryProvider.notifier).addCategory(controller.text, type);
                Navigator.pop(ctx);
              }
            },
            child: Text(
              'ADD',
              style: TextStyle(
                color: type == 'expense' ? AppTheme.glowingRed : AppTheme.accentCyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
