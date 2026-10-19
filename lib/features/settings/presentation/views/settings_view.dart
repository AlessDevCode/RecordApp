// lib/features/settings/presentation/views/settings_view.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recordapp/core/i18n/translation_extension.dart';
import 'package:recordapp/features/settings/domain/models/app_settings.dart';
import 'package:recordapp/features/settings/domain/models/app_theme_mode.dart';
import 'package:recordapp/features/settings/domain/models/time_format_pref.dart';
import 'package:recordapp/features/settings/presentation/providers/settings_providers.dart';
import 'package:recordapp/features/settings/presentation/widgets/about_header.dart';
import 'package:recordapp/features/settings/presentation/widgets/settings_section.dart';
import 'package:recordapp/features/settings/presentation/widgets/username_field.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  static const List<String> _formatosFecha = <String>[
    'YYYY-MM-DD',
    'DD/MM/YYYY',
    'MM/DD/YYYY',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppSettings> settingsAsync =
        ref.watch(appSettingsProvider);
    final AppSettingsNotifier notifier =
        ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ref.tr('settings.title', 'CONFIGURACIÓN'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => Center(
          child: Text(ref.tr('home.error', 'No se pudieron cargar las misiones')),
        ),
        data: (AppSettings s) {
          final List<String> opcionesFecha = <String>{
            ..._formatosFecha,
            s.dateFormat,
          }.toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: <Widget>[
              const AboutHeader(),
              SettingsSection(
                title: ref.tr('settings.appearance', 'APARIENCIA'),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: Text(ref.tr('settings.theme', 'Tema visual')),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<AppThemeMode>(
                    expandedInsets: EdgeInsets.zero,
                    segments: <ButtonSegment<AppThemeMode>>[
                      ButtonSegment<AppThemeMode>(
                        value: AppThemeMode.light,
                        icon: const Icon(Icons.light_mode_outlined),
                        label: Text(ref.tr('settings.theme_light', 'Claro')),
                      ),
                      ButtonSegment<AppThemeMode>(
                        value: AppThemeMode.dark,
                        icon: const Icon(Icons.dark_mode_outlined),
                        label: Text(ref.tr('settings.theme_dark', 'Oscuro')),
                      ),
                      ButtonSegment<AppThemeMode>(
                        value: AppThemeMode.system,
                        icon: const Icon(Icons.settings_suggest_outlined),
                        label: Text(ref.tr('settings.theme_system', 'Sistema')),
                      ),
                    ],
                    selected: <AppThemeMode>{s.themeMode},
                    onSelectionChanged: (Set<AppThemeMode> seleccion) {
                      unawaited(notifier.setThemeMode(seleccion.first));
                    },
                  ),
                ),
              ),
              SettingsSection(title: ref.tr('settings.general', 'GENERAL')),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(ref.tr('settings.language', 'Idioma')),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    expandedInsets: EdgeInsets.zero,
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(value: 'es', label: Text('Español')),
                      ButtonSegment<String>(value: 'en', label: Text('English')),
                      ButtonSegment<String>(
                        value: 'pt',
                        label: Text('Português'),
                      ),
                    ],
                    selected: <String>{
                      const <String>['es', 'en', 'pt'].contains(s.language)
                          ? s.language
                          : 'es',
                    },
                    onSelectionChanged: (Set<String> seleccion) {
                      unawaited(notifier.setLanguage(seleccion.first));
                    },
                  ),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: Text(ref.tr('settings.notifications', 'Notificaciones')),
                subtitle: Text(
                  ref.tr(
                    'settings.notifications_desc',
                    'Habilitar alertas de misiones',
                  ),
                ),
                value: s.notificationsEnabled,
                onChanged: (bool valor) {
                  unawaited(
                    notifier.setNotificationsEnabled(habilitadas: valor),
                  );
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.push_pin_outlined),
                title: Text(
                  ref.tr('settings.persistent', 'Notificación fija'),
                ),
                subtitle: Text(
                  ref.tr(
                    'settings.persistent_desc',
                    'Muestra en la barra de estado tu próxima misión o alarma',
                  ),
                ),
                value: s.persistentNotification,
                onChanged: (bool valor) {
                  unawaited(
                    notifier.setPersistentNotification(activada: valor),
                  );
                },
              ),
              const SizedBox(height: 8),
              UsernameField(
                key: ValueKey<String>('username_${s.cyberUsername}'),
                initialValue: s.cyberUsername,
                label: ref.tr('settings.username', 'Nombre de operador'),
                saveLabel: ref.tr('settings.username_save', 'Guardar'),
                onSaved: (String valor) {
                  unawaited(notifier.setCyberUsername(valor));
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(ref.tr('settings.time_format', 'Formato de hora')),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TimeFormatPref>(
                    expandedInsets: EdgeInsets.zero,
                    segments: const <ButtonSegment<TimeFormatPref>>[
                      ButtonSegment<TimeFormatPref>(
                        value: TimeFormatPref.h24,
                        label: Text('24 h'),
                      ),
                      ButtonSegment<TimeFormatPref>(
                        value: TimeFormatPref.h12,
                        label: Text('12 h'),
                      ),
                    ],
                    selected: <TimeFormatPref>{s.timeFormat},
                    onSelectionChanged: (Set<TimeFormatPref> seleccion) {
                      unawaited(notifier.setTimeFormat(seleccion.first));
                    },
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: Text(ref.tr('settings.date_format', 'Formato de fecha')),
                trailing: DropdownButton<String>(
                  value: s.dateFormat,
                  underline: const SizedBox.shrink(),
                  items: <DropdownMenuItem<String>>[
                    for (final String formato in opcionesFecha)
                      DropdownMenuItem<String>(
                        value: formato,
                        child: Text(formato),
                      ),
                  ],
                  onChanged: (String? valor) {
                    if (valor == null) return;
                    unawaited(notifier.setDateFormat(valor));
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}