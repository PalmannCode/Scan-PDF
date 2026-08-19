import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/errors/user_message.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/features/auth/presentation/providers/auth_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/paywall/presentation/providers/plus_provider.dart';
import 'package:scanpdf/features/scanner/presentation/providers/scan_saver_provider.dart';
import 'package:scanpdf/services/ai_provider.dart';
import 'package:scanpdf/services/ai_service.dart';
import 'package:scanpdf/services/expense_report_service.dart';
import 'package:scanpdf/shared/models/scan_document.dart';

class ExpenseReportScreen extends ConsumerStatefulWidget {
  const ExpenseReportScreen({super.key});

  @override
  ConsumerState<ExpenseReportScreen> createState() =>
      _ExpenseReportScreenState();
}

class _EditableExpense {
  _EditableExpense({
    required this.documentTitle,
    required this.merchant,
    required this.date,
    required this.total,
    required this.tax,
    required this.currency,
  });

  final String documentTitle;
  String merchant;
  String date;
  String total;
  String tax;
  String currency;

  ExpenseReportEntry toEntry() => ExpenseReportEntry(
    documentTitle: documentTitle,
    merchant: merchant,
    date: date,
    total: total,
    tax: tax,
    currency: currency,
  );
}

class _ExpenseReportScreenState extends ConsumerState<ExpenseReportScreen> {
  final Set<String> _selected = {};
  final List<_EditableExpense> _entries = [];
  bool _working = false;
  String? _error;

  Future<void> _extract() async {
    if (!ref.read(plusProvider).isActive) {
      context.push('/paywall');
      return;
    }
    final user = await ref.read(authUserProvider.future);
    if (!mounted) return;
    if (user == null) {
      context.push('/account');
      return;
    }
    if (_selected.isEmpty) return;
    final consent = await AdaptiveDialog.confirm(
      context,
      title: 'Process receipts with AI?',
      message:
          'Recognized receipt text will be sent to the configured AI service to extract merchant, date, amount, and tax. You can review every value before export.',
      confirmLabel: 'Continue',
    );
    if (!consent) return;
    setState(() {
      _working = true;
      _error = null;
      _entries.clear();
    });
    try {
      final failed = <String>[];
      for (final id in _selected) {
        var doc = ref.read(documentRepositoryProvider).getById(id);
        if (doc == null) continue;
        if (!doc.hasOcr) {
          await ref.read(scanSaverProvider).runOcr(doc.id);
          doc = ref.read(documentRepositoryProvider).getById(id);
        }
        if (doc == null || !doc.hasOcr) {
          failed.add(doc?.title ?? 'a receipt');
          continue;
        }
        try {
          final response = await ref
              .read(aiServiceProvider)
              .run(action: AiAction.extract, text: doc.ocrText);
          final result = response.result;
          _entries.add(
            _EditableExpense(
              documentTitle: doc.title,
              merchant: result['vendor_name']?.toString() ?? '',
              date: result['document_date']?.toString() ?? '',
              total: result['total_amount']?.toString() ?? '',
              tax: result['tax_amount']?.toString() ?? '',
              currency: result['currency']?.toString() ?? '',
            ),
          );
        } catch (_) {
          failed.add(doc.title);
          continue;
        }
        if (mounted) setState(() {});
      }
      if (failed.isNotEmpty && mounted) {
        setState(
          () => _error =
              '${failed.length} of ${_selected.length} receipt(s) could not '
              'be processed: ${failed.join(', ')}.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = userMessageFor(
            error,
            fallback:
                'Receipt extraction could not be completed. Check your connection and try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  List<ExpenseReportEntry> get _confirmed => [
    for (final entry in _entries) entry.toEntry(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final documents = ref.watch(activeDocumentsProvider);
    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        leading: PressableTap(
          onTap: () => context.pop(),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.textPrimary,
          ),
        ),
        title: Text(
          'Expense Report',
          style: AppTypography.title(colors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            _entries.isEmpty
                ? 'Select receipt scans'
                : 'Review extracted values',
            style: AppTypography.headline(colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_entries.isEmpty) ...[
            for (final ScanDocument document in documents)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _selected.contains(document.id),
                // The M3 default fills a checked box with colorScheme.primary
                // (deep indigo) and draws the tick in onPrimary. On the dark
                // paper background both land within ~1.2:1 of the surface, so
                // a selected receipt looks identical to an unselected one.
                activeColor: colors.textPrimary,
                checkColor: colors.paperBg,
                title: Text(document.title),
                subtitle: Text('${document.pageCount} page(s)'),
                onChanged: _working
                    ? null
                    : (value) => setState(() {
                        value == true
                            ? _selected.add(document.id)
                            : _selected.remove(document.id);
                      }),
              ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _working || _selected.isEmpty ? null : _extract,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(_working ? 'Extracting…' : 'Extract receipt data'),
            ),
          ] else ...[
            for (var index = 0; index < _entries.length; index++)
              _ExpenseCard(entry: _entries[index]),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _working
                        ? null
                        : () => ref
                              .read(expenseReportServiceProvider)
                              .shareCsv(_confirmed),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Export CSV'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _working
                        ? null
                        : () => ref
                              .read(expenseReportServiceProvider)
                              .sharePdf(_confirmed),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Export PDF'),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => setState(_entries.clear),
              child: const Text('Start over'),
            ),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Text(_error!, style: TextStyle(color: colors.danger)),
            ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({required this.entry});

  final _EditableExpense entry;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: AppSpacing.md),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            entry.documentTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          TextFormField(
            initialValue: entry.merchant,
            decoration: const InputDecoration(labelText: 'Merchant'),
            onChanged: (value) => entry.merchant = value,
          ),
          TextFormField(
            initialValue: entry.date,
            decoration: const InputDecoration(labelText: 'Date'),
            onChanged: (value) => entry.date = value,
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: entry.total,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Total'),
                  onChanged: (value) => entry.total = value,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  initialValue: entry.tax,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Tax'),
                  onChanged: (value) => entry.tax = value,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  initialValue: entry.currency,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  onChanged: (value) => entry.currency = value,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
