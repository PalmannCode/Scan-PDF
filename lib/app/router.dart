import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:scanpdf/app/theme/app_motion.dart';
import 'package:scanpdf/features/event/presentation/screens/event_screen.dart';
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
import 'package:scanpdf/features/viewer/presentation/screens/document_viewer_screen.dart';
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
        path: '/paywall',
        pageBuilder: (context, state) =>
            _slideUpPage(state, const PaywallScreen()),
      ),
      GoRoute(
        path: '/event',
        pageBuilder: (context, state) =>
            _fadeThroughPage(state, const EventScreen()),
      ),
    ],
  );
}
