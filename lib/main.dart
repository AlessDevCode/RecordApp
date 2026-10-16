// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recordapp/core/router/app_router.dart';
import 'package:recordapp/core/theme/app_theme.dart';
import 'package:recordapp/core/ui/root_messenger.dart';
import 'package:recordapp/features/alarms/presentation/widgets/alarm_host.dart';
import 'package:recordapp/features/settings/presentation/providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Precarga la configuración persistida para aplicar el tema guardado
  // desde el primer frame (evita el parpadeo claro/oscuro).
  final ProviderContainer container = ProviderContainer();
  await container.read(appSettingsProvider.future);
  await container.read(translatorProvider.future);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const RecordApp(),
    ),
  );
}

class RecordApp extends ConsumerWidget {
  const RecordApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode themeMode = ref.watch(appThemeModeProvider);
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'RecordApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      builder: (BuildContext context, Widget? child) {
        return AlarmHost(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
