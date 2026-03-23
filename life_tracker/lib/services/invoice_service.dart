import 'dart:io';
import 'dart:math';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../models/transaction_model.dart';

class InvoiceService {
  // Colors
  static const _cyan = PdfColor(0, 1, 0.8);
  static const _red = PdfColor(1, 0.2, 0.4);
  static const _purple = PdfColor(0.54, 0.17, 0.89);
  static const _magenta = PdfColor(1, 0, 1);
  static const _darkBg = PdfColor(0.043, 0.047, 0.063);
  static const _cardBg = PdfColor(0.082, 0.094, 0.122);
  static const _textMuted = PdfColor(0.63, 0.67, 0.7);
  static const _borderColor = PdfColor(0.15, 0.17, 0.2);

  static Future<File> generateMonthlyInvoice({
    required String username,
    required List<TransactionModel> transactions,
    required int month,
    required int year,
  }) async {
    final pdf = pw.Document();

    final monthName = DateFormat('MMMM').format(DateTime(year, month));
    final monthTransactions = transactions.where((t) =>
        t.date.month == month && t.date.year == year).toList();

    monthTransactions.sort((a, b) => a.date.compareTo(b.date));

    final totalIncome = monthTransactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = monthTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final balance = totalIncome - totalExpense;

    // Category breakdowns
    final Map<String, double> expenseByCategory = {};
    final Map<String, double> incomeByCategory = {};
    for (final tx in monthTransactions) {
      if (tx.type == 'expense') {
        expenseByCategory[tx.category] =
            (expenseByCategory[tx.category] ?? 0) + tx.amount;
      } else {
        incomeByCategory[tx.category] =
            (incomeByCategory[tx.category] ?? 0) + tx.amount;
      }
    }

    // Daily spending data
    final Map<int, double> dailyExpense = {};
    final Map<int, double> dailyIncome = {};
    for (final tx in monthTransactions) {
      if (tx.type == 'expense') {
        dailyExpense[tx.date.day] = (dailyExpense[tx.date.day] ?? 0) + tx.amount;
      } else {
        dailyIncome[tx.date.day] = (dailyIncome[tx.date.day] ?? 0) + tx.amount;
      }
    }

    final daysInMonth = DateTime(year, month + 1, 0).day;
    final savingRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome * 100) : 0.0;
    final expenseCount = monthTransactions.where((t) => t.type == 'expense').length;
    final incomeCount = monthTransactions.where((t) => t.type == 'income').length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.notoSansRegular(),
          bold: await PdfGoogleFonts.notoSansBold(),
        ),
        build: (context) => [
          // ============ HEADER ============
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
                      fontSize: 28, fontWeight: pw.FontWeight.bold, color: _cyan,
                      letterSpacing: 3,
                    )),
                    pw.SizedBox(height: 6),
                    pw.Text('Monthly Financial Report', style: pw.TextStyle(
                      fontSize: 13, color: _textMuted, letterSpacing: 1,
                    )),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('$monthName $year', style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
                    )),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: _cyan.flatten(background: _darkBg),
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

          // ============ SUMMARY CARDS ============
          pw.Row(
            children: [
              _summaryCard('TOTAL INCOME', 'Rs ${totalIncome.toStringAsFixed(2)}', _cyan, '$incomeCount entries'),
              pw.SizedBox(width: 10),
              _summaryCard('TOTAL EXPENSE', 'Rs ${totalExpense.toStringAsFixed(2)}', _red, '$expenseCount entries'),
              pw.SizedBox(width: 10),
              _summaryCard('NET BALANCE', 'Rs ${balance.toStringAsFixed(2)}',
                  balance >= 0 ? _cyan : _red, 'Saving: ${savingRate.toStringAsFixed(1)}%'),
            ],
          ),

          pw.SizedBox(height: 20),

          // ============ DAILY SPENDING BAR CHART ============
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
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('DAILY SPENDING CHART', style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
                      letterSpacing: 2,
                    )),
                    pw.Row(children: [
                      pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(color: _cyan, borderRadius: pw.BorderRadius.circular(2))),
                      pw.SizedBox(width: 4),
                      pw.Text('Income', style: const pw.TextStyle(fontSize: 9, color: _textMuted)),
                      pw.SizedBox(width: 10),
                      pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(color: _red, borderRadius: pw.BorderRadius.circular(2))),
                      pw.SizedBox(width: 4),
                      pw.Text('Expense', style: const pw.TextStyle(fontSize: 9, color: _textMuted)),
                    ]),
                  ],
                ),
                pw.SizedBox(height: 16),
                _buildDailyChart(dailyExpense, dailyIncome, daysInMonth),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ============ CATEGORY BREAKDOWN VISUAL ============
          if (expenseByCategory.isNotEmpty) ...[
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
                  pw.Text('EXPENSE BREAKDOWN BY CATEGORY', style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold, color: _red,
                    letterSpacing: 2,
                  )),
                  pw.SizedBox(height: 16),
                  ...expenseByCategory.entries.toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final catName = entry.value.key;
                    final catAmount = entry.value.value;
                    final percent = totalExpense > 0 ? (catAmount / totalExpense * 100) : 0.0;
                    final barColor = _getCategoryPdfColor(idx);

                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Row(children: [
                                pw.Container(width: 10, height: 10, decoration: pw.BoxDecoration(color: barColor, shape: pw.BoxShape.circle)),
                                pw.SizedBox(width: 8),
                                pw.Text(catName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                              ]),
                              pw.Text('Rs ${catAmount.toStringAsFixed(2)}  (${percent.toStringAsFixed(1)}%)',
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            height: 8,
                            decoration: pw.BoxDecoration(
                              color: const PdfColor(0.1, 0.1, 0.15),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  flex: percent.round().clamp(1, 100),
                                  child: pw.Container(
                                    decoration: pw.BoxDecoration(
                                      color: barColor,
                                      borderRadius: pw.BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                pw.Expanded(
                                  flex: (100 - percent.round()).clamp(0, 99),
                                  child: pw.SizedBox(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // ============ INCOME SOURCES ============
          if (incomeByCategory.isNotEmpty) ...[
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
                  pw.Text('INCOME SOURCES', style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold, color: _cyan,
                    letterSpacing: 2,
                  )),
                  pw.SizedBox(height: 16),
                  ...incomeByCategory.entries.map((entry) {
                    final percent = totalIncome > 0 ? (entry.value / totalIncome * 100) : 0.0;
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(entry.key, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                              pw.Text('Rs ${entry.value.toStringAsFixed(2)}  (${percent.toStringAsFixed(1)}%)',
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _cyan)),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Container(
                            height: 8,
                            decoration: pw.BoxDecoration(
                              color: const PdfColor(0.1, 0.1, 0.15),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Row(
                              children: [
                                pw.Expanded(
                                  flex: percent.round().clamp(1, 100),
                                  child: pw.Container(
                                    decoration: pw.BoxDecoration(color: _cyan, borderRadius: pw.BorderRadius.circular(4)),
                                  ),
                                ),
                                pw.Expanded(
                                  flex: (100 - percent.round()).clamp(0, 99),
                                  child: pw.SizedBox(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // ============ TRANSACTION TABLE ============
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
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('ALL TRANSACTIONS', style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
                      letterSpacing: 2,
                    )),
                    pw.Text('${monthTransactions.length} entries', style: const pw.TextStyle(
                      fontSize: 10, color: _textMuted,
                    )),
                  ],
                ),
                pw.SizedBox(height: 14),

                if (monthTransactions.isEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(24),
                    child: pw.Center(
                      child: pw.Text('No transactions recorded for this month.',
                          style: const pw.TextStyle(fontSize: 12, color: _textMuted)),
                    ),
                  )
                else ...[
                  // Table Header
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: _darkBg,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(flex: 3, child: pw.Text('DATE & TIME', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textMuted, letterSpacing: 1))),
                        pw.Expanded(flex: 3, child: pw.Text('TITLE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textMuted, letterSpacing: 1))),
                        pw.Expanded(flex: 2, child: pw.Text('CATEGORY', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textMuted, letterSpacing: 1))),
                        pw.Expanded(flex: 2, child: pw.Text('AMOUNT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _textMuted, letterSpacing: 1), textAlign: pw.TextAlign.right)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 4),

                  // Table Rows
                  ...monthTransactions.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final tx = entry.value;
                    final isIncome = tx.type == 'income';
                    final dateStr = DateFormat('dd MMM, HH:mm').format(tx.date);

                    return pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: pw.BoxDecoration(
                        color: idx % 2 == 0 ? const PdfColor(0.06, 0.07, 0.09) : const PdfColor(0, 0, 0, 0),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(flex: 3, child: pw.Text(dateStr, style: const pw.TextStyle(fontSize: 9, color: _textMuted))),
                          pw.Expanded(flex: 3, child: pw.Text(tx.title, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white))),
                          pw.Expanded(flex: 2, child: pw.Text(tx.category, style: const pw.TextStyle(fontSize: 9, color: _textMuted))),
                          pw.Expanded(flex: 2, child: pw.Text(
                            '${isIncome ? '+' : '-'}Rs ${tx.amount.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: isIncome ? _cyan : _red),
                            textAlign: pw.TextAlign.right,
                          )),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ============ FOOTER ============
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _darkBg,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Generated by Life Tracker App', style: const pw.TextStyle(fontSize: 9, color: _textMuted)),
                    pw.SizedBox(height: 2),
                    pw.Text('Developed by Biswajith - Vibe Coding Specialist',
                        style: pw.TextStyle(fontSize: 8, color: _purple)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Report Generated:', style: const pw.TextStyle(fontSize: 8, color: _textMuted)),
                    pw.Text(DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now()),
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/LifeTracker_${username}_${monthName}_$year.pdf');
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
            pw.Text(label, style: pw.TextStyle(
              fontSize: 8, color: color, fontWeight: pw.FontWeight.bold, letterSpacing: 1.5,
            )),
            pw.SizedBox(height: 6),
            pw.Text(value, style: pw.TextStyle(
              fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.white,
            )),
            pw.SizedBox(height: 4),
            pw.Text(subtitle, style: const pw.TextStyle(fontSize: 8, color: _textMuted)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildDailyChart(Map<int, double> expense, Map<int, double> income, int daysInMonth) {
    final allValues = [
      ...expense.values,
      ...income.values,
    ];
    final maxVal = allValues.isEmpty ? 100.0 : allValues.reduce(max).toDouble();
    final chartHeight = 80.0;

    // Show every other day for readability
    return pw.Column(
      children: [
        pw.Container(
          height: chartHeight,
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: List.generate(daysInMonth, (i) {
              final day = i + 1;
              final expVal = expense[day] ?? 0;
              final incVal = income[day] ?? 0;
              final expHeight = maxVal > 0 ? (expVal / maxVal * chartHeight) : 0.0;
              final incHeight = maxVal > 0 ? (incVal / maxVal * chartHeight) : 0.0;

              return pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 0.5),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Expanded(
                        child: pw.Container(
                          height: max(incHeight, 1.0),
                          decoration: pw.BoxDecoration(
                            color: incVal > 0 ? _cyan : const PdfColor(0.1, 0.1, 0.15),
                            borderRadius: pw.BorderRadius.circular(1),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Container(
                          height: max(expHeight, 1.0),
                          decoration: pw.BoxDecoration(
                            color: expVal > 0 ? _red : const PdfColor(0.1, 0.1, 0.15),
                            borderRadius: pw.BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        pw.SizedBox(height: 4),
        // Day labels
        pw.Row(
          children: List.generate(daysInMonth, (i) {
            final day = i + 1;
            final showLabel = day == 1 || day % 5 == 0 || day == daysInMonth;
            return pw.Expanded(
              child: showLabel
                  ? pw.Text('$day', style: const pw.TextStyle(fontSize: 6, color: _textMuted), textAlign: pw.TextAlign.center)
                  : pw.SizedBox(),
            );
          }),
        ),
      ],
    );
  }

  static const _categoryColors = [
    _red,
    _cyan,
    _magenta,
    _purple,
    PdfColor(1, 0.7, 0.28),   // orange
    PdfColor(0.47, 0.87, 0.47), // green
    PdfColor(0.43, 0.71, 1),   // blue
    PdfColor(1, 0.84, 0),       // gold
  ];

  static PdfColor _getCategoryPdfColor(int index) {
    return _categoryColors[index % _categoryColors.length];
  }

  static Future<void> openPdf(File file) async {
    await OpenFile.open(file.path);
  }
}
