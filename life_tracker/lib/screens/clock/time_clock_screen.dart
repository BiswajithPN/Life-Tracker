import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/floating_glass_card.dart';

class TimeClockScreen extends StatefulWidget {
  const TimeClockScreen({super.key});

  @override
  State<TimeClockScreen> createState() => _TimeClockScreenState();
}

class _TimeClockScreenState extends State<TimeClockScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _currentTime = '';

  // Lap tracking
  final List<Duration> _laps = [];

  @override
  void initState() {
    super.initState();
    _updateCurrentTime();
    Timer.periodic(const Duration(seconds: 1), (_) => _updateCurrentTime());
  }

  void _updateCurrentTime() {
    if (!mounted) return;
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
  }

  void _startStop() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _timer?.cancel();
      } else {
        _stopwatch.start();
        _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  void _reset() {
    setState(() {
      _stopwatch.stop();
      _stopwatch.reset();
      _timer?.cancel();
      _laps.clear();
    });
  }

  void _addLap() {
    if (_stopwatch.isRunning) {
      setState(() {
        _laps.add(_stopwatch.elapsed);
      });
    }
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    final millis = ((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds.$millis';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _stopwatch.elapsed;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'TIME CLOCK',
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
          children: [
            // Current Time Display
            FloatingGlassCard(
              glowColor: AppTheme.accentCyan,
              child: Column(
                children: [
                  Text(
                    'CURRENT TIME',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppTheme.accentCyan, AppTheme.accentMagenta],
                    ).createShader(bounds),
                    child: Text(
                      _currentTime,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getDateString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Stopwatch
            FloatingGlassCard(
              glowColor: AppTheme.accentPurple,
              child: Column(
                children: [
                  Text(
                    'STOPWATCH',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatDuration(elapsed),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w300,
                      color: _stopwatch.isRunning ? AppTheme.accentCyan : Theme.of(context).textTheme.displayLarge?.color,
                      letterSpacing: 4,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset
                      _circleButton(
                        icon: Icons.refresh,
                        color: AppTheme.glowingRed,
                        onTap: _reset,
                      ),
                      const SizedBox(width: 20),
                      // Start/Stop
                      _circleButton(
                        icon: _stopwatch.isRunning ? Icons.pause : Icons.play_arrow,
                        color: _stopwatch.isRunning ? AppTheme.accentMagenta : AppTheme.accentCyan,
                        onTap: _startStop,
                        large: true,
                      ),
                      const SizedBox(width: 20),
                      // Lap
                      _circleButton(
                        icon: Icons.flag,
                        color: AppTheme.accentPurple,
                        onTap: _addLap,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Laps
            if (_laps.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'LAPS',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: 3),
              ),
              const SizedBox(height: 12),
              ...List.generate(_laps.length, (index) {
                final lapIndex = _laps.length - 1 - index;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Lap ${lapIndex + 1}', style: Theme.of(context).textTheme.bodyMedium),
                      Text(
                        _formatDuration(_laps[lapIndex]),
                        style: TextStyle(
                          color: AppTheme.accentCyan,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _getDateString() {
    final now = DateTime.now();
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool large = false,
  }) {
    final size = large ? 60.0 : 44.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color, width: 2),
          boxShadow: large ? AppTheme.getNeonGlow(color: color, intensity: 0.5) : [],
        ),
        child: Icon(icon, color: color, size: large ? 28 : 20),
      ),
    );
  }
}
