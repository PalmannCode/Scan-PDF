import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:scanpdf/app/theme/app_shapes.dart';
import 'package:scanpdf/app/theme/app_spacing.dart';
import 'package:scanpdf/app/theme/app_typography.dart';
import 'package:scanpdf/core/constants/url_constants.dart';
import 'package:scanpdf/core/extensions/context_extensions.dart';
import 'package:scanpdf/core/utils/responsive.dart';
import 'package:scanpdf/core/widgets/adaptive_dialog.dart';
import 'package:scanpdf/core/widgets/app_background.dart';
import 'package:scanpdf/core/widgets/empty_state.dart';
import 'package:scanpdf/core/widgets/paper_sheet_illustration.dart';
import 'package:scanpdf/core/widgets/pressable_tap.dart';
import 'package:scanpdf/core/widgets/signature/scan_pulse_frame.dart';
import 'package:scanpdf/core/widgets/staggered_column.dart';
import 'package:scanpdf/features/event/presentation/widgets/event_banner.dart';
import 'package:scanpdf/features/home/presentation/providers/documents_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/folders_provider.dart';
import 'package:scanpdf/features/home/presentation/providers/import_provider.dart';
import 'package:scanpdf/features/home/presentation/widgets/document_actions.dart';
import 'package:scanpdf/features/home/presentation/widgets/document_tile.dart';
import 'package:scanpdf/features/home/presentation/widgets/folder_card.dart';
import 'package:scanpdf/features/home/presentation/widgets/library_stats_strip.dart';
import 'package:scanpdf/features/home/presentation/widgets/scan_dock.dart';
import 'package:scanpdf/features/settings/presentation/providers/settings_provider.dart';
import 'package:scanpdf/shared/models/enums.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/models/scan_folder.dart';

class MyScansScreen extends ConsumerWidget {
  const MyScansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final documents = ref.watch(activeDocumentsProvider);
    final folders = ref.watch(foldersProvider);
    final rootDocs = sortDocuments(
      documents.where((d) => d.folderId == null).toList(),
      ref.watch(settingsProvider).sortMode,
    );
    final isEmpty = documents.isEmpty && folders.isEmpty;

    return Scaffold(
      backgroundColor: colors.shellBg,
      body: AppBackground(
        treatment: BackgroundTreatment.shell,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _HomeHeader(),
              const _HomeSearchBar(),
              const EventBanner(),
              if (documents.isNotEmpty)
                LibraryStatsStrip(
                  documentCount: documents.length,
                  pageCount: documents.fold(0, (sum, d) => sum + d.pageCount),
                ),
              Expanded(
                child: isEmpty
                    ? const _ScansEmptyState()
                    : _LibraryContent(
                        folders: folders,
                        documents: documents,
                        rootDocs: rootDocs,
                      ),
              ),
              const ScanDock(),
              SizedBox(height: context.padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          PressableTap(
            style: PressStyle.dim,
            onTap: () => context.push('/settings'),
            child: Icon(
              Icons.settings_outlined,
              color: colors.onShell,
              semanticLabel: 'Settings',
            ),
          ),
          Expanded(
            child: Text(
              'My Scans',
              textAlign: TextAlign.center,
              style: AppTypography.headline(colors.onShell),
            ),
          ),
          const _MoreMenu(),
        ],
      ),
    );
  }
}

class _MoreMenu extends ConsumerWidget {
  const _MoreMenu();

  Future<void> _newFolder(BuildContext context, WidgetRef ref) async {
    final name = await AdaptiveDialog.prompt(
      context,
      title: 'New folder',
      placeholder: 'Folder name',
      confirmLabel: 'Create',
    );
    if (name != null) {
      await ref.read(foldersProvider.notifier).create(name);
    }
  }

  Future<void> _importFiles(BuildContext context, WidgetRef ref) async {
    final added = await ref.read(importControllerProvider).importFiles();
    if (added > 0 && context.mounted) context.push('/review');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final settings = ref.watch(settingsProvider);

    MenuItemButton item(
      String label, {
      VoidCallback? onPressed,
      bool checked = false,
    }) => MenuItemButton(
      onPressed: onPressed,
      trailingIcon: checked
          ? Icon(Icons.check_rounded, size: 18, color: colors.accent)
          : null,
      child: Text(label, style: AppTypography.bodyMedium(colors.textPrimary)),
    );

    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(colors.paperCard),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppShapes.cardRadius),
        ),
      ),
      menuChildren: [
        item('New Folder', onPressed: () => _newFolder(context, ref)),
        item('Import Files', onPressed: () => _importFiles(context, ref)),
        const Divider(),
        item(
          'Grid',
          checked: settings.viewMode == LibraryViewMode.grid,
          onPressed: () => ref
              .read(settingsProvider.notifier)
              .update((s) => s.copyWith(viewMode: LibraryViewMode.grid)),
        ),
        item(
          'List',
          checked: settings.viewMode == LibraryViewMode.list,
          onPressed: () => ref
              .read(settingsProvider.notifier)
              .update((s) => s.copyWith(viewMode: LibraryViewMode.list)),
        ),
        const Divider(),
        for (final mode in LibrarySortMode.values)
          item(
            mode.label,
            checked: settings.sortMode == mode,
            onPressed: () => ref
                .read(settingsProvider.notifier)
                .update((s) => s.copyWith(sortMode: mode)),
          ),
        const Divider(),
        item(
          'Priority Support',
          onPressed: () => launchUrl(
            Uri.parse(UrlConstants.support),
            mode: LaunchMode.externalApplication,
          ),
        ),
        item('Trash Bin', onPressed: () => context.push('/trash')),
      ],
      builder: (context, controller, _) => PressableTap(
        style: PressStyle.dim,
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        child: Icon(
          Icons.more_horiz_rounded,
          color: colors.onShell,
          semanticLabel: 'More options',
        ),
      ),
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: PressableTap(
        style: PressStyle.dim,
        onTap: () => context.push('/search'),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
              Text(
                'Search by title or text',
                style: AppTypography.body(colors.onShellMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScansEmptyState extends StatelessWidget {
  const _ScansEmptyState();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      onShell: true,
      illustration: SizedBox(
        width: 190,
        height: 220,
        child: ScanPulseFrame(
          inset: 20,
          child: Center(child: PaperSheetIllustration(size: 140)),
        ),
      ),
      title: 'No scans yet',
      subtitle: 'Tap the camera button to create your first scan.',
    );
  }
}

class _LibraryContent extends ConsumerWidget {
  const _LibraryContent({
    required this.folders,
    required this.documents,
    required this.rootDocs,
  });

  final List<ScanFolder> folders;
  final List<ScanDocument> documents;
  final List<ScanDocument> rootDocs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(settingsProvider.select((s) => s.viewMode));
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (folders.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 108,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  final count = documents
                      .where((d) => d.folderId == folder.id)
                      .length;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: FolderCard(
                      folder: folder,
                      documentCount: count,
                      onTap: () => context.push('/folder/${folder.id}'),
                    ).staggered(index),
                  );
                },
              ),
            ),
          ),
        if (rootDocs.isEmpty && folders.isNotEmpty)
          const SliverToBoxAdapter(child: SizedBox.shrink())
        else
          _DocumentsSliver(documents: rootDocs, viewMode: viewMode),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      ],
    );
  }
}

class _DocumentsSliver extends ConsumerWidget {
  const _DocumentsSliver({required this.documents, required this.viewMode});

  final List<ScanDocument> documents;
  final LibraryViewMode viewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (viewMode == LibraryViewMode.list) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverList.builder(
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            return DocumentRow(
              document: doc,
              onTap: () => context.push('/document/${doc.id}'),
              onLongPress: () => showDocumentActions(context, ref, doc),
            ).staggered(index);
          },
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.gridColumns(context),
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: 0.68,
        ),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final doc = documents[index];
          return DocumentTile(
            document: doc,
            onTap: () => context.push('/document/${doc.id}'),
            onLongPress: () => showDocumentActions(context, ref, doc),
          ).staggered(index);
        },
      ),
    );
  }
}
