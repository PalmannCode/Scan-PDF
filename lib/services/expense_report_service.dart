import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ExpenseReportEntry {
  const ExpenseReportEntry({
    required this.documentTitle,
    required this.merchant,
    required this.date,
    required this.total,
    required this.tax,
    required this.currency,
  });

  final String documentTitle;
  final String merchant;
  final String date;
  final String total;
  final String tax;
  final String currency;
}

class ExpenseReportService {
  const ExpenseReportService();

  String _csvCell(String value) {
    var safe = value;
    if (safe.isNotEmpty && '=+-@'.contains(safe[0])) safe = "'$safe";
    return '"${safe.replaceAll('"', '""')}"';
  }

  Future<Directory> _directory() async {
    final temp = await getTemporaryDirectory();
    final dir = Directory('${temp.path}/exports');
    await dir.create(recursive: true);
    return dir;
  }

  Future<void> shareCsv(List<ExpenseReportEntry> entries) async {
    final rows = <String>[
      'Document,Merchant,Date,Total,Tax,Currency',
      for (final entry in entries)
        [
          entry.documentTitle,
          entry.merchant,
          entry.date,
          entry.total,
          entry.tax,
          entry.currency,
        ].map(_csvCell).join(','),
    ];
    final dir = await _directory();
    final file = File('${dir.path}/Scan_PDF_Expense_Report.csv');
    await file.writeAsString(rows.join('\r\n'), flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Expense Report'),
    );
  }

  Future<void> sharePdf(List<ExpenseReportEntry> entries) async {
    final document = pw.Document();
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/Archivo.ttf'));
    final theme = pw.ThemeData.withFont(base: font, bold: font);
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Text(
            'Expense Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: const ['Merchant', 'Date', 'Total', 'Tax', 'Currency'],
            data: [
              for (final entry in entries)
                [
                  entry.merchant,
                  entry.date,
                  entry.total,
                  entry.tax,
                  entry.currency,
                ],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: const pw.TextStyle(fontSize: 9),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Review all AI-extracted values against the original receipts before submitting this report.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ],
      ),
    );
    final dir = await _directory();
    final file = File('${dir.path}/Scan_PDF_Expense_Report.pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Expense Report'),
    );
  }
}

final expenseReportServiceProvider = Provider<ExpenseReportService>(
  (ref) => const ExpenseReportService(),
);
