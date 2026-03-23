import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/floating_glass_card.dart';
import '../../state/user_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SETTINGS',
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
            _sectionHeader(context, 'APPEARANCE'),
            const SizedBox(height: 12),

            // Theme Toggle
            FloatingGlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: isDark ? AppTheme.accentPurple : Colors.amber,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDark ? 'Dark Mode' : 'Light Mode',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isDark ? 'Deep space dark theme' : 'Clean and bright interface',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isDark,
                    onChanged: (val) {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                    activeTrackColor: AppTheme.accentCyan.withValues(alpha: 0.4),
                    activeThumbColor: AppTheme.accentCyan,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            _sectionHeader(context, 'NOTIFICATIONS'),
            const SizedBox(height: 12),

            _settingsTile(
              context,
              icon: Icons.notifications_active,
              title: 'Habit Reminders',
              subtitle: 'Daily reminders for your habits',
              color: AppTheme.accentMagenta,
            ),
            _settingsTile(
              context,
              icon: Icons.warning_amber,
              title: 'Spending Alerts',
              subtitle: 'Alert when expenses exceed 50% of income',
              color: AppTheme.glowingRed,
            ),

            const SizedBox(height: 32),
            _sectionHeader(context, 'ACCOUNT'),
            const SizedBox(height: 12),

            _settingsTile(
              context,
              icon: Icons.person_outline,
              title: user?.username ?? 'Guest',
              subtitle: user?.email ?? 'Not logged in',
              color: AppTheme.accentCyan,
            ),

            const SizedBox(height: 32),
            _sectionHeader(context, 'ABOUT'),
            const SizedBox(height: 12),
            _settingsTile(
              context,
              icon: Icons.info_outline,
              title: 'Life Tracker',
              subtitle: 'Version 1.0.0',
              color: AppTheme.accentCyan,
            ),
            _settingsTile(
              context,
              icon: Icons.developer_mode,
              title: 'Developed by Biswajith',
              subtitle: 'Vibe Coding Specialist',
              color: AppTheme.accentPurple,
            ),

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
                label: const Text(
                  'LOG OUT',
                  style: TextStyle(color: AppTheme.glowingRed, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.glowingRed),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
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
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _settingsTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color color = AppTheme.accentCyan,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
