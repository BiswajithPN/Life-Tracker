import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../screens/habits/habits_screen.dart';

class HabitReportService {
  static const _cyan = PdfColor(0, 1, 0.8);
  static const _red = PdfColor(1, 0.2, 0.4);
  static const _purple = PdfColor(0.54, 0.17, 0.89);
  static const _darkBg = PdfColor(0.043, 0.047, 0.063);
  static const _cardBg = PdfColor(0.082, 0.094, 0.122);
  static const _textMuted = PdfColor(0.63, 0.67, 0.7);
  static const _borderColor = PdfColor(0.15, 0.17, 0.2);

  static Future<File> generateHabitReport({
    required String username,
    required List<HabitItem> habits,
  }) async {
    final pdf = pw.Document();
    
    final completedCount = habits.where((h) => h.completedToday).length;
    final totalCount = habits.length;
    final completionRate = totalCount > 0 ? (completedCount / totalCount * 100) : 0.0;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.notoSansRegular(),
          bold: await PdfGoogleFonts.notoSansBold(),
        ),
        build: (context) => [
          // HEADER
          pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: _darkBg,
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('LIFE TRACKER', style: pw.TextStyle(
                      fontSize: 28, fontWeight: pw.FontWeight.bold, color: _purple,
                      letterSpacing: 3,
                    )),
                    pw.SizedBox(height: 6),
                    pw.Text('Habit Performance Report', style: pw.TextStyle(
                      fontSize: 13, color: _textMuted, letterSpacing: 1,
                    )),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now()), style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
                    )),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: _purple.flatten(background: _darkBg),
                        borderRadius: pw.BorderRadius.circular(20),
                      ),
                      child: pw.Text(username.toUpperCase(), style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold,
                        color: _darkBg, letterSpacing: 1,
                      )),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // SUMMARY
          pw.Row(
            children: [
              _summaryCard('TOTAL HABITS', '$totalCount', _cyan, ''),
              pw.SizedBox(width: 10),
              _summaryCard('COMPLETED TODAY', '$completedCount', _purple, ''),
              pw.SizedBox(width: 10),
              _summaryCard('COMPLETION RATE', '${completionRate.toStringAsFixed(1)}%',
                  completionRate >= 50 ? _cyan : _red, ''),
            ],
          ),
          pw.SizedBox(height: 20),

          // HABITS TABLE
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: _cardBg,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: _borderColor),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('YOUR HABITS', style: pw.TextStyle(
                  fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
                  letterSpacing: 2,
                )),
                pw.SizedBox(height: 14),

                if (habits.isEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(24),
                    child: pw.Center(
                      child: pw.Text('No habits recorded.', style: const pw.TextStyle(fontSize: 12, color: _textMuted)),
                    ),
                  )
                else ...[
                  // Header
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: _darkBg,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 3, child: pw.Text('HABIT TITLE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textMuted, letterSpacing: 1))),
                        pw.Expanded(flex: 2, child: pw.Text('REMINDER TIME', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textMuted, letterSpacing: 1))),
                        pw.Expanded(flex: 2, child: pw.Text('STREAK', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textMuted, letterSpacing: 1), textAlign: pw.TextAlign.center)),
                        pw.Expanded(flex: 2, child: pw.Text('STATUS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textMuted, letterSpacing: 1), textAlign: pw.TextAlign.right)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 4),

                  // Rows
                  ...habits.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final habit = entry.value;
                    final timeStr = '${habit.reminderTime.hour.toString().padLeft(2, '0')}:${habit.reminderTime.minute.toString().padLeft(2, '0')}';
                    final statusColor = habit.completedToday ? _cyan : _red;
                    final statusText = habit.completedToday ? 'DONE TODAY' : 'PENDING';

                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: pw.BoxDecoration(
                        color: idx % 2 == 0 ? const PdfColor(0.06, 0.07, 0.09) : const PdfColor(0, 0, 0, 0),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(flex: 3, child: pw.Text(habit.title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                          pw.Expanded(flex: 2, child: pw.Text(timeStr, style: const pw.TextStyle(fontSize: 9, color: _textMuted))),
                          pw.Expanded(flex: 2, child: pw.Text('${habit.streak} Days', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _purple), textAlign: pw.TextAlign.center)),
                          pw.Expanded(flex: 2, child: pw.Text(statusText, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: statusColor), textAlign: pw.TextAlign.right)),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // FOOTER
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(color: _darkBg, borderRadius: pw.BorderRadius.circular(8)),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Generated by Life Tracker App', style: const pw.TextStyle(fontSize: 9, color: _textMuted)),
                    pw.SizedBox(height: 2),
                    pw.Text('Developed by Biswajith - Vibe Coding Specialist', style: pw.TextStyle(fontSize: 8, color: _cyan)),
                  ],
                ),
                pw.Text(DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/HabitsReport_${username}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Expanded _summaryCard(String label, String value, PdfColor color, String subtitle) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: _cardBg,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: color, width: 1.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(fontSize: 8, color: color, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5)),
            pw.SizedBox(height: 6),
            pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
            if (subtitle.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              pw.Text(subtitle, style: const pw.TextStyle(fontSize: 8, color: _textMuted)),
            ]
          ],
        ),
      ),
    );
  }
}
