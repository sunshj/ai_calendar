import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/schedule/page/schedule_page.dart';
import '../constants/app_constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppConstants.scheduleRoute,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppConstants.scheduleRoute,
        name: 'schedule',
        builder: (context, state) => const SchedulePage(),
      ),
      GoRoute(
        path: AppConstants.historyRoute,
        name: 'history',
        builder: (context, state) => const PlaceholderPage(title: 'History'),
      ),
      GoRoute(
        path: AppConstants.settingsRoute,
        name: 'settings',
        builder: (context, state) => const PlaceholderPage(title: 'Settings'),
      ),
      GoRoute(
        path: AppConstants.aiRoute,
        name: 'ai',
        builder: (context, state) => const PlaceholderPage(title: 'AI Settings'),
      ),
      GoRoute(
        path: AppConstants.debugRoute,
        name: 'debug',
        builder: (context, state) => const PlaceholderPage(title: 'Debug'),
      ),
    ],
    errorBuilder: (context, state) => PlaceholderPage(
      title: 'Page Not Found',
      error: state.error?.toString(),
    ),
  );
}

class PlaceholderPage extends StatelessWidget {
  final String title;
  final String? error;

  const PlaceholderPage({
    super.key,
    required this.title,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              Text(
                '$title - Coming Soon',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Text(
                  error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
