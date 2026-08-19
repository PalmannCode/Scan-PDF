import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

import 'package:scanpdf/app/app.dart';

import 'ocr_fixture.dart';
import 'package:scanpdf/shared/models/scan_document.dart';
import 'package:scanpdf/shared/models/scan_page.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

/// End-to-end flows against the real widget tree, Hive boxes and router.
///
/// Run with:
///   flutter test integration_test/app_flows_test.dart -d DEVICE_ID
///
/// The simulator has no camera, so capture itself is out of scope; every flow
/// that does not need hardware is driven through the real UI.
///
/// NOTE: never use `pumpAndSettle` here. The home empty state, camera overlay
/// and event illustration all render a `ScanPulseFrame`, whose controller calls
/// `repeat()` — the tree never reaches quiescence, so `pumpAndSettle` spins
/// until it times out. `settle()` below advances the clock instead.
/// A real 8x8 JPEG. Hand-rolled byte arrays are not decodable, and Flutter
/// throws "Invalid image data" out of the image resource service, failing any
/// test that renders a page thumbnail.
final Uint8List _tinyJpeg = base64Decode(
  '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAA0JCgsKCA0LCgsODg0PEyAVExISEyccHhcgLikxMC4pLSwzOko+MzZGNywtQFdBRkxOUlNSMj5aYVpQYEpRUk//2wBDAQ4ODhMREyYVFSZPNS01T09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0//wAARCAAIAAgDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAP/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFAEBAAAAAAAAAAAAAAAAAAAABf/EABQRAQAAAAAAAAAAAAAAAAAAAAD/2gAMAwEAAhEDEQA/AKAATb//2Q==',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory docsDir;
  late Box<String> documentsBox;
  late Box<String> foldersBox;
  late Box<String> prefsBox;

  /// Advances frames without requiring the tree to go idle.
  Future<void> settle(
    WidgetTester tester, [
    Duration duration = const Duration(milliseconds: 700),
  ]) async {
    await tester.pump();
    await tester.pump(duration);
    await tester.pump(const Duration(milliseconds: 300));
  }

  setUp(() async {
    docsDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter();
    // Plaintext boxes: the encrypted wrapper needs the Keychain, which is not
    // what these flows exercise.
    documentsBox = await Hive.openBox<String>(HiveBoxes.documents);
    foldersBox = await Hive.openBox<String>(HiveBoxes.folders);
    prefsBox = await Hive.openBox<String>(HiveBoxes.prefs);
    await documentsBox.clear();
    await foldersBox.clear();
    await prefsBox.clear();
    // The router sends every route to /onboarding until this flag is set, so
    // a cleared prefs box would park all of these flows on the intro screens.
    await prefsBox.put('onboarding_done', 'true');
  });

  tearDown(() async {
    await documentsBox.clear();
    await foldersBox.clear();
    await prefsBox.clear();
  });

  /// Writes a one-page document into Hive plus its page images, so viewer and
  /// export flows have real content without needing the camera.
  Future<void> seedDocument({
    String id = 'itest-doc',
    String title = 'Quarterly invoice',
  }) async {
    final now = DateTime.now();
    final document = ScanDocument(
      id: id,
      title: title,
      createdAt: now,
      modifiedAt: now,
      pages: [ScanPage(id: '$id-page')],
    );
    final jpeg = _tinyJpeg;
    final pages = Directory('${docsDir.path}/pages');
    await pages.create(recursive: true);
    await File('${pages.path}/$id-page.jpg').writeAsBytes(jpeg, flush: true);
    await File(
      '${pages.path}/$id-page_orig.jpg',
    ).writeAsBytes(jpeg, flush: true);
    await documentsBox.put(id, jsonEncode(document.toJson()));
  }

  Future<void> launchApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageDirProvider.overrideWithValue(docsDir.path)],
        child: const ScanPdfApp(),
      ),
    );
    await settle(tester, const Duration(seconds: 2));
  }

  Future<void> openSettings(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.settings_outlined).first);
    await settle(tester);
  }

  testWidgets('a fresh install is routed to onboarding', (tester) async {
    await prefsBox.delete('onboarding_done');
    await launchApp(tester);
    expect(find.text('My Scans'), findsNothing);
  });

  testWidgets('app boots to the library shell', (tester) async {
    await launchApp(tester);
    expect(find.text('My Scans'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Photos'), findsOneWidget);
  });

  testWidgets('library counts use singular nouns for one document', (
    tester,
  ) async {
    await seedDocument();
    await launchApp(tester);
    // Regression: this strip rendered "1 documents · 1 pages".
    expect(find.text(' document · '), findsOneWidget);
    expect(find.text(' page'), findsOneWidget);
    expect(find.text(' documents · '), findsNothing);
    expect(find.text(' pages'), findsNothing);
  });

  testWidgets('tools sheet opens and exposes every section', (tester) async {
    await launchApp(tester);
    await tester.tap(find.text('Tools'));
    await settle(tester);

    expect(find.text('SCAN'), findsOneWidget);
    expect(find.text('Document'), findsOneWidget);
    expect(find.text('QR Code'), findsOneWidget);
    expect(find.text('CREATE'), findsOneWidget);
    expect(find.text('IMPORT'), findsOneWidget);
    expect(find.text('EXPORT'), findsOneWidget);
  });

  testWidgets('settings opens and the theme choice changes', (tester) async {
    await launchApp(tester);
    await openSettings(tester);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);

    await tester.tap(find.text('Theme'));
    await settle(tester);
    expect(find.text('System'), findsNothing);
    expect(find.text('Light'), findsOneWidget);
  });

  testWidgets('every default file-name preset shows a clean label', (
    tester,
  ) async {
    await launchApp(tester);
    await openSettings(tester);

    // The tile lives far down a lazy list, so it must be scrolled into view.
    final tile = find.text('Default file name');
    await tester.scrollUntilVisible(
      tile,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await settle(tester);

    // Cycling must always land on exactly one known preset. The original bug
    // stored raw ICU patterns, so a stored value could match no label at all.
    const labels = [
      'Scan + date and time',
      'Document + date',
      'Receipt + date',
    ];
    final seen = <String>{};
    for (var i = 0; i < labels.length; i++) {
      final shown = labels
          .where((label) => find.text(label).evaluate().isNotEmpty)
          .toList();
      expect(
        shown,
        hasLength(1),
        reason: 'expected exactly one preset label, saw $shown',
      );
      seen.add(shown.single);
      await tester.tap(tile);
      await settle(tester);
    }
    expect(seen, hasLength(labels.length), reason: 'cycle skipped a preset');
  });

  testWidgets('document-scoped tools actually navigate after picking', (
    tester,
  ) async {
    // Regression: the Tools sheet popped itself, then awaited the document
    // picker. By the time a document was chosen the sheet's context was
    // unmounted, so every `if (context.mounted) context.push(...)` silently
    // did nothing and the tool appeared dead.
    for (final tool in ['Ask AI', 'Sign', 'Reorder']) {
      await documentsBox.clear();
      await seedDocument(title: 'Quarterly invoice');
      // Tear the tree down first: pumping ScanPdfApp again would update the
      // existing element in place, keeping the router wherever the previous
      // iteration left it. A placeholder forces a genuinely fresh router.
      await tester.pumpWidget(const SizedBox.shrink());
      await settle(tester);
      await launchApp(tester);
      expect(find.text('My Scans'), findsOneWidget);

      await tester.tap(find.text('Tools'));
      await settle(tester);

      final entry = find.text(tool);
      await tester.scrollUntilVisible(
        entry,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await settle(tester);
      await tester.tap(entry);
      await settle(tester);

      final pick = find.text('Quarterly invoice');
      expect(pick, findsWidgets, reason: '$tool did not open the picker');
      await tester.tap(pick.last);
      await settle(tester, const Duration(seconds: 2));

      expect(
        find.text('My Scans'),
        findsNothing,
        reason: '$tool picked a document but never navigated',
      );
    }
  });

  testWidgets('Apple Vision recognises real text on device', (tester) async {
    // The AI screen refuses to run unless document.hasOcr is true, so if OCR
    // silently fails every AI action looks like a dead button. This seeds a
    // page containing actual words and asserts Vision read them.
    final now = DateTime.now();
    const id = 'ocr-real';
    final document = ScanDocument(
      id: id,
      title: 'Legible invoice',
      createdAt: now,
      modifiedAt: now,
      pages: const [ScanPage(id: '$id-page')],
    );
    final pages = Directory('${docsDir.path}/pages');
    await pages.create(recursive: true);
    await File(
      '${pages.path}/$id-page.jpg',
    ).writeAsBytes(ocrTextJpeg, flush: true);
    await File(
      '${pages.path}/$id-page_orig.jpg',
    ).writeAsBytes(ocrTextJpeg, flush: true);
    await documentsBox.put(id, jsonEncode(document.toJson()));

    await launchApp(tester);
    await tester.tap(find.text('Legible invoice'));
    await settle(tester, const Duration(seconds: 2));
    await tester.tap(find.text('Text'));

    // Vision took ~20s per pass on this simulator; give it room.
    for (var i = 0; i < 40; i++) {
      await settle(tester, const Duration(seconds: 1));
      if (find.textContaining('INVOICE').evaluate().isNotEmpty) break;
    }

    expect(
      find.textContaining('INVOICE'),
      findsWidgets,
      reason: 'Vision did not recognise text that is plainly in the image',
    );
  });

  testWidgets('AI Run always resolves — it never spins forever', (
    tester,
  ) async {
    // Reported symptom: "Processing…" for 5+ minutes. Root causes were an
    // unbounded await on the auth stream (itself gated behind an Amplitude
    // call) and an AI request with no timeout. Whatever the outcome — signed
    // out, no recognised text, or a service error — the button must stop
    // saying "Processing…".
    await seedDocument(id: 'ai-doc', title: 'Textless page');
    await launchApp(tester);

    await tester.tap(find.text('Textless page'));
    await settle(tester, const Duration(seconds: 2));
    await tester.tap(find.text('AI'));
    await settle(tester, const Duration(seconds: 2));

    final run = find.textContaining('Run ');
    expect(run, findsWidgets, reason: 'AI screen did not open');
    await tester.tap(run.first);

    var settled = false;
    for (var i = 0; i < 45; i++) {
      await settle(tester, const Duration(seconds: 1));
      if (find.text('Processing…').evaluate().isEmpty) {
        settled = true;
        break;
      }
    }
    expect(
      settled,
      isTrue,
      reason: 'AI Run was still "Processing…" after 45s — the hang is back',
    );
  });

  testWidgets('paywall shows the approved price and a safe fallback', (
    tester,
  ) async {
    await launchApp(tester);
    await openSettings(tester);
    await tester.tap(find.text('Upgrade to Plus'));
    await settle(tester, const Duration(seconds: 2));

    expect(find.textContaining(r'$3.99'), findsWidgets);
    expect(find.text('Restore Purchases'), findsOneWidget);
  });

  testWidgets('a document opens in the viewer and offers every export format', (
    tester,
  ) async {
    await seedDocument(title: 'Quarterly invoice');
    await launchApp(tester);

    await tester.tap(find.text('Quarterly invoice'));
    await settle(tester, const Duration(seconds: 2));
    expect(find.text('Export'), findsWidgets);

    await tester.tap(find.text('Export').last);
    await settle(tester);
    expect(find.text('PDF document'), findsOneWidget);
    expect(find.text('JPG images'), findsOneWidget);
    expect(find.text('PNG images'), findsOneWidget);
    expect(find.textContaining('Word'), findsOneWidget);
  });

  testWidgets('OCR screen reports an empty result instead of re-running', (
    tester,
  ) async {
    // A document already marked attempted must not auto-run recognition again,
    // and must say so rather than showing the never-run prompt.
    final now = DateTime.now();
    final document = ScanDocument(
      id: 'ocr-doc',
      title: 'Blank page',
      createdAt: now,
      modifiedAt: now,
      pages: const [ScanPage(id: 'ocr-doc-page')],
      ocrAttempted: true,
    );
    final jpeg = _tinyJpeg;
    final pages = Directory('${docsDir.path}/pages');
    await pages.create(recursive: true);
    await File(
      '${pages.path}/ocr-doc-page.jpg',
    ).writeAsBytes(jpeg, flush: true);
    await File(
      '${pages.path}/ocr-doc-page_orig.jpg',
    ).writeAsBytes(jpeg, flush: true);
    await documentsBox.put('ocr-doc', jsonEncode(document.toJson()));

    await launchApp(tester);
    await tester.tap(find.text('Blank page'));
    await settle(tester, const Duration(seconds: 2));
    await tester.tap(find.text('Text'));
    await settle(tester, const Duration(seconds: 2));

    expect(find.text('No text found'), findsOneWidget);
    expect(find.text('No text recognized yet'), findsNothing);
  });
}
