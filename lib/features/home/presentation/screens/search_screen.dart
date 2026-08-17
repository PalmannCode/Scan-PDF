import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/widgets/app_background.dart';
import 'package:scanpdf/core/widgets/empty_state.dart';
import 'package:scanpdf/core/widgets/paper_sheet_illustration.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/core/widgets/staggered_column.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/folders_provider.dart';
import 'package:scanpdf/features/home/presentation/widgets/document_actions.dart';
import 'package:scanpdf/features/home/presentation/widgets/document_tile.dart';
import 'package:scanpdf/shared/models/scan_document.dart';

/// Search by title, folder name, and recognized OCR text (Jira §9).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<ScanDocument> _results() {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return const [];
    final docs = ref.watch(activeDocumentsProvider);
    final folders = ref.watch(foldersProvider);
    final matchingFolderIds = folders
        .where((f) => f.name.toLowerCase().contains(query))
        .map((f) => f.id)
        .toSet();
    return docs.where((doc) {
      if (doc.title.toLowerCase().contains(query)) return true;
      if (doc.folderId != null && matchingFolderIds.contains(doc.folderId)) {
        return true;
      }
      return doc.ocrText.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasAnyDocs = ref.watch(activeDocumentsProvider).isNotEmpty;
    final results = _results();

    return Scaffold(
      backgroundColor: colors.shellBg,
      body: AppBackground(
        treatment: BackgroundTreatment.shell,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          color: colors.shellElevated,
                          borderRadius: AppShapes.pillRadius,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: colors.onShellMuted,
                              semanticLabel: 'Search',
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextField(
                                controller: _controller,
                                autofocus: true,
                                style: AppTypography.body(colors.onShell),
                                cursorColor: colors.accent,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  hintText: 'Search by title or text',
                                  hintStyle: AppTypography.body(
                                    colors.onShellMuted,
                                  ),
                                ),
                                onChanged: (value) =>
                                    setState(() => _query = value),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    PressableTap(
                      style: PressStyle.dim,
                      onTap: () => context.pop(),
                      child: Text(
                        'Done',
                        style: AppTypography.bodyMedium(colors.onShell),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody(hasAnyDocs, results)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool hasAnyDocs, List<ScanDocument> results) {
    if (!hasAnyDocs) {
      return const EmptyState(
        onShell: true,
        illustration: PaperSheetIllustration(size: 110),
        title: 'First create documents',
        subtitle:
            'Please, add documents to search among them and by their content.',
      );
    }
    if (_query.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    if (results.isEmpty) {
      return const EmptyState(
        onShell: true,
        illustration: PaperSheetIllustration(size: 110),
        title: 'No results found',
        subtitle: 'Try searching by title or recognized text.',
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final doc = results[index];
        return DocumentRow(
          document: doc,
          onTap: () => context.push('/document/${doc.id}'),
          onLongPress: () => showDocumentActions(context, ref, doc),
        ).staggered(index);
      },
    );
  }
}
