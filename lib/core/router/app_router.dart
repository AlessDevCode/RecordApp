// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:recordapp/features/settings/presentation/views/settings_view.dart';
import 'package:recordapp/features/tasks/domain/models/task.dart';
import 'package:recordapp/features/tasks/presentation/views/editor_view.dart';
import 'package:recordapp/features/tasks/presentation/views/home_view.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

abstract final class AppRoutes {
  static const String home = '/';

  /// Sin `extra`: nueva misión. Con `extra: Task`: edición de esa misión.
  static const String editor = '/editor';
  static const String settings = '/settings';
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: AppRoutes.editor,
        name: 'editor',
        builder: (context, state) {
          final Object? extra = state.extra;
          return EditorView(task: extra is Task ? extra : null);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsView(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
