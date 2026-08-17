import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:scanpdf/app/theme/app_motion.dart';
import 'package:scanpdf/features/event/presentation/screens/event_screen.dart';
import 'package:scanpdf/features/auth/presentation/screens/account_screen.dart';
import 'package:scanpdf/features/ai/presentation/screens/document_ai_screen.dart';
import 'package:scanpdf/features/tools/presentation/instant_translate_screen.dart';
import 'package:scanpdf/features/tools/presentation/expense_report_screen.dart';
import 'package:scanpdf/features/tools/presentation/measure_screen.dart';
import 'package:scanpdf/features/tools/presentation/object_count_screen.dart';
import 'package:scanpdf/features/tools/presentation/qr_result_screen.dart';
import 'package:scanpdf/features/home/presentation/screens/folder_screen.dart';
import 'package:scanpdf/features/home/presentation/screens/my_scans_screen.dart';
import 'package:scanpdf/features/home/presentation/screens/search_screen.dart';
import 'package:scanpdf/features/home/presentation/screens/trash_screen.dart';
import 'package:scanpdf/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:scanpdf/features/paywall/presentation/screens/paywall_screen.dart';
import 'package:scanpdf/features/scanner/presentation/screens/camera_screen.dart';
import 'package:scanpdf/features/scanner/presentation/screens/crop_screen.dart';
import 'package:scanpdf/features/scanner/presentation/screens/page_review_screen.dart';
import 'package:scanpdf/features/settings/presentation/screens/settings_screen.dart';
import 'package:scanpdf/features/settings/presentation/screens/app_icon_screen.dart';
import 'package:scanpdf/features/settings/presentation/screens/support_screen.dart';
import 'package:scanpdf/features/settings/presentation/screens/signatures_screen.dart';
import 'package:scanpdf/features/settings/presentation/screens/workflows_screen.dart';
import 'package:scanpdf/features/settings/presentation/screens/email_template_screen.dart';
import 'package:scanpdf/services/ai_service.dart';
import 'package:scanpdf/features/viewer/presentation/screens/document_viewer_screen.dart';
import 'package:scanpdf/features/viewer/presentation/screens/advanced_document_tools_screen.dart';
import 'package:scanpdf/features/viewer/presentation/screens/manage_pages_screen.dart';
import 'package:scanpdf/features/viewer/presentation/screens/ocr_result_screen.dart';
import 'package:scanpdf/features/viewer/presentation/screens/sign_screen.dart';
import 'package:scanpdf/shared/providers/storage_provider.dart';

/// Fade-through page transition (mechanical motion personality).
CustomTransitionPage<T> _fadeThroughPage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.sheet,
    reverseTransitionDuration: AppMotion.sheet,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          fillColor: Colors.transparent,
          child: child,
        ),
  );
}

/// Full-screen slide-up for the camera (capture feels like a sheet).
CustomTransitionPage<T> _slideUpPage<T>(GoRouterState state, Widget child) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: AppMotion.sheet,
    reverseTransitionDuration: AppMotion.sheet,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        SlideTransition(
          position: animation.drive(
            Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).chain(CurveTween(curve: AppMotion.enter)),
          ),
          child: child,
        ),
  );
}

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final prefs = Hive.box<String>(HiveBoxes.prefs);
      final done = prefs.get('onboarding_done') == 'true';
      final path = state.matchedLocation;
      // The event route is redirect-exempt: the ASC deep link must open
      // on a fresh install even before onboarding.
      if (!done && path != '/onboarding' && path != '/event') {
        return '/onboarding';
      }
      if (done && path == '/onboarding') return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const MyScansScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const SearchScreen()),
      ),
      GoRoute(
        path: '/camera',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const CameraScreen()),
      ),
      GoRoute(
        path: '/review',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const PageReviewScreen()),
      ),
      GoRoute(
        path: '/crop/:index',
        pageBuilder: (context, state) => _fadeThroughPage(
          state,
          CropScreen(
            pageIndex: int.tryParse(state.pathParameters['index'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: '/document/:id',
        pageBuilder: (context, state) => _fadeThroughPage(
          state,
          DocumentViewerScreen(documentId: state.pathParameters['id']!),
        ),
        routes: [
          GoRoute(
            path: 'sign',
            pageBuilder: (context, state) => _fadeThroughPage(
              state,
              SignScreen(documentId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: 'text',
            pageBuilder: (context, state) => _fadeThroughPage(
              state,
              OcrResultScreen(documentId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: 'ai',
            pageBuilder: (context, state) => _fadeThroughPage(
              state,
              DocumentAiScreen(
                documentId: state.pathParameters['id']!,
                initialAction:
                    AiAction.values
                        .where(
                          (action) =>
                              action.name ==
                              state.uri.queryParameters['action'],
                        )
                        .firstOrNull ??
                    AiAction.ask,
              ),
            ),
          ),
          GoRoute(
            path: 'tools',
            pageBuilder: (context, state) => _fadeThroughPage(
              state,
              AdvancedDocumentToolsScreen(
                documentId: state.pathParameters['id']!,
              ),
            ),
          ),
          GoRoute(
            path: 'pages',
            pageBuilder: (context, state) => _fadeThroughPage(
              state,
              ManagePagesScreen(documentId: state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/folder/:id',
        pageBuilder: (context, state) => _fadeThroughPage(
          state,
          FolderScreen(folderId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/trash',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const TrashScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/settings/app-icon',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const AppIconScreen()),
      ),
      GoRoute(
        path: '/support',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const SupportScreen()),
      ),
      GoRoute(
        path: '/settings/signatures',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const SignaturesScreen()),
      ),
      GoRoute(
        path: '/settings/workflows',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const WorkflowsScreen()),
      ),
      GoRoute(
        path: '/settings/email-template',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const EmailTemplateScreen()),
      ),
      GoRoute(
        path: '/account',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const AccountScreen()),
      ),
      GoRoute(
        path: '/paywall',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const PaywallScreen()),
      ),
      GoRoute(
        path: '/event',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const EventScreen()),
      ),
      GoRoute(
        path: '/qr-result',
        pageBuilder: (context, state) => _fadeThroughPage(
          state,
          QrResultScreen(value: state.uri.queryParameters['value'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/measure',
        pageBuilder: (context, state) => _fadeThroughPage(
          state,
          MeasureScreen(imagePath: state.extra! as String),
        ),
      ),
      GoRoute(
        path: '/count',
        pageBuilder: (context, state) => _fadeThroughPage(
          state,
          ObjectCountScreen(imagePath: state.extra! as String),
        ),
      ),
      GoRoute(
        path: '/translate',
        pageBuilder: (context, state) => _fadeThroughPage(
          state,
          InstantTranslateScreen(imagePath: state.extra! as String),
        ),
      ),
      GoRoute(
        path: '/expense-report',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const ExpenseReportScreen()),
      ),
    ],
  );
}
