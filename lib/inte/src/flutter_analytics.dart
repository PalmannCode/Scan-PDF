import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'flutter_analytics_config.dart';
import 'models/app_info.dart';
import 'storage_service.dart';

typedef FlutterAnalyticsRemoteExperienceBuilder =
    Widget Function(
      BuildContext context,
      FlutterAnalyticsRemoteExperience experience,
    );

/// Server-selected remote experience exposed to host apps that need to add
/// native bridges, authenticated request headers, or app-owned navigation.
///
/// When no custom builder is supplied, the SDK keeps using its original
/// full-screen WebView implementation.
class FlutterAnalyticsRemoteExperience {
  const FlutterAnalyticsRemoteExperience._({
    required this.reference,
    required this.initialUri,
    required this.backgroundColor,
    required this.appInfo,
    required this.config,
  });

  final String reference;
  final Uri initialUri;
  final Color backgroundColor;
  final AppInfo appInfo;
  final FlutterAnalyticsConfig config;

  Future<void> notifyUrlChange(String url) => config.notifyAboutUrlChange(url);
}

/// Top-level integration widget.
///
/// Wrap your app's root with this, give it a [FlutterAnalyticsConfig]
/// pointing at your per-app domain, and the SDK will:
///  * fetch the per-app config from your Home Screen API server on boot
///  * decide (based on the server's response) whether to mount the
///    remote WebView or pass through to your [child]
///  * register the device with FCM and subscribe to the country topic for
///    geo-targeted push campaigns
///
/// While the config is loading, [splash] is shown (defaults to an empty
/// box). When loading fails the widget falls back to [child].
class FlutterAnalytics extends StatefulWidget {
  const FlutterAnalytics({
    super.key,
    required this.config,
    this.splash,
    this.child,
    this.remoteExperienceBuilder,
  });

  final FlutterAnalyticsConfig config;
  final Widget? splash;
  final Widget? child;
  final FlutterAnalyticsRemoteExperienceBuilder? remoteExperienceBuilder;

  @override
  State<FlutterAnalytics> createState() => _FlutterAnalyticsState();
}

class _FlutterAnalyticsState extends State<FlutterAnalytics> {
  late final FlutterAnalyticsConfig config;

  @override
  void initState() {
    super.initState();
    config = widget.config;
    config.initialize();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<AppInfo>(
    stream: config.status,
    builder: (context, snapshot) {
      final appInfo = snapshot.data;

      if (snapshot.hasData && appInfo != null) {
        final enters = StorageService.instance.getEnters();

        // Pick the first-launch webview vs the returning-users one.
        final firstAnalytics = appInfo.analyticsInfo;
        final secondAnalytics = appInfo.secondAnalyticsInfo;
        final secondEnabled = secondAnalytics?.enabled ?? false;
        final analytics = enters == 0
            ? firstAnalytics
            : (secondEnabled ? secondAnalytics : firstAnalytics);

        final analyticsEnabled = analytics?.enabled ?? false;

        if (analyticsEnabled && analytics != null) {
          return _Webview(
            appInfo: appInfo,
            config: config,
            reference: analytics.reference,
            color: analytics.color,
            remoteExperienceBuilder: widget.remoteExperienceBuilder,
          );
        }
        return widget.child ?? const SizedBox.shrink();
      } else if (snapshot.hasError) {
        return widget.child ?? const SizedBox.shrink();
      }

      return MaterialApp(
        home: widget.splash ?? const SizedBox.shrink(),
        debugShowCheckedModeBanner: false,
      );
    },
  );
}

class _Webview extends StatelessWidget {
  const _Webview({
    required this.reference,
    required this.color,
    required this.config,
    required this.appInfo,
    this.remoteExperienceBuilder,
  });

  final String reference;
  final String color;
  final AppInfo appInfo;
  final FlutterAnalyticsConfig config;
  final FlutterAnalyticsRemoteExperienceBuilder? remoteExperienceBuilder;

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: config.analyticsParams,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        final experience = FlutterAnalyticsRemoteExperience._(
          reference: reference,
          initialUri: _initialUri(
            reference,
            snapshot.data ?? const <String, dynamic>{},
          ),
          backgroundColor: _backgroundColor(color),
          appInfo: appInfo,
          config: config,
        );
        return _RemoteExperienceHost(
          experience: experience,
          builder:
              remoteExperienceBuilder ??
              (context, experience) => _WebviewView(experience: experience),
        );
      }
      return const Center(child: CupertinoActivityIndicator());
    },
  );

  static Color _backgroundColor(String hex) {
    final normalized = hex.replaceFirst('#', '');
    final value = int.tryParse(normalized, radix: 16);
    return Color(0xFF000000 | (value ?? 0xFFFFFF));
  }

  static Uri _initialUri(
    String reference,
    Map<String, dynamic> analyticsParams,
  ) {
    final tempUri = Uri.parse(reference);
    final persistedParams = StorageService.instance.getParams();
    final params = <String, dynamic>{
      ...?persistedParams,
      if (persistedParams == null) ...analyticsParams,
      ...tempUri.queryParameters,
    };
    return tempUri.replace(
      queryParameters: params.isEmpty
          ? null
          : params.map((key, value) => MapEntry(key, value.toString())),
    );
  }
}

class _RemoteExperienceHost extends StatefulWidget {
  const _RemoteExperienceHost({
    required this.experience,
    required this.builder,
  });

  final FlutterAnalyticsRemoteExperience experience;
  final FlutterAnalyticsRemoteExperienceBuilder builder;

  @override
  State<_RemoteExperienceHost> createState() => _RemoteExperienceHostState();
}

class _RemoteExperienceHostState extends State<_RemoteExperienceHost> {
  @override
  void initState() {
    super.initState();
    unawaited(
      widget.experience.config.notifyWebviewOpened(widget.experience.reference),
    );
  }

  @override
  void didUpdateWidget(covariant _RemoteExperienceHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.experience.reference != widget.experience.reference) {
      unawaited(
        widget.experience.config.notifyWebviewOpened(
          widget.experience.reference,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.experience);
}

class _WebviewView extends StatefulWidget {
  const _WebviewView({required this.experience});

  final FlutterAnalyticsRemoteExperience experience;

  @override
  State<_WebviewView> createState() => _WebviewViewState();
}

class _WebviewViewState extends State<_WebviewView> {
  late final WebKitWebViewController controller;
  late final WebKitNavigationDelegate navigationDelegate;

  Color get backgroundColor => widget.experience.backgroundColor;

  void _onUrlChange(UrlChange change) {
    final url = change.url;
    if (url == null) return;
    unawaited(widget.experience.notifyUrlChange(url));
  }

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback(
      (_) => SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );

    navigationDelegate =
        WebKitNavigationDelegate(
            const PlatformNavigationDelegateCreationParams(),
          )
          ..setOnUrlChange(_onUrlChange)
          ..setOnWebResourceError(
            (error) => debugPrint('HSAPI webview error: ${error.description}'),
          )
          ..setOnHttpError(
            (error) =>
                debugPrint('HSAPI webview http: ${error.response?.statusCode}'),
          );

    controller =
        WebKitWebViewController(WebKitWebViewControllerCreationParams())
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(backgroundColor)
          ..setAllowsBackForwardNavigationGestures(true)
          ..setPlatformNavigationDelegate(navigationDelegate);

    controller.loadRequest(
      LoadRequestParams(uri: widget.experience.initialUri),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            bottom:
                widget.experience.appInfo.appFilters?.safeAreaBottom ?? false,
            top: widget.experience.appInfo.appFilters?.safeAreaTop ?? false,
            child: WebViewWidget.fromPlatform(
              platform: WebKitWebViewWidget(
                PlatformWebViewWidgetCreationParams(controller: controller),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
