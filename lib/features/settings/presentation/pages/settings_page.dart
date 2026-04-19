import 'package:flutter/material.dart';

import '../../../../app/settings/app_settings_controller.dart';
import '../../../../config/service_locator.dart';
import '../../../../shared/utils/app_i18n.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final AppSettingsController _controller = getIt<AppSettingsController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(context.tr('settings.title')),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              _buildSection(
                context: context,
                title: context.tr('settings.section.display'),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.dark_mode_outlined),
                      title: Text(context.tr('settings.appearance')),
                      subtitle: Text(_themeLabel(_controller.themeMode)),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<ThemeMode>(
                      style: SegmentedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        selectedForegroundColor: colorScheme.onPrimary,
                        selectedBackgroundColor: colorScheme.primary,
                        backgroundColor: colorScheme.surface,
                      ),
                      segments: [
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode_outlined),
                          label: Text(context.tr('settings.theme.light')),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode_outlined),
                          label: Text(context.tr('settings.theme.dark')),
                        ),
                        ButtonSegment<ThemeMode>(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.settings_suggest_outlined),
                          label: Text(context.tr('settings.theme.system')),
                        ),
                      ],
                      selected: {_controller.themeMode},
                      onSelectionChanged: (selected) {
                        _controller.setThemeMode(selected.first);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildSection(
                context: context,
                title: context.tr('settings.section.language'),
                child: DropdownButtonFormField<String>(
                  value: _controller.languageCode,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.language_rounded),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'vi',
                      child: Text(context.tr('settings.language.vi')),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text(context.tr('settings.language.en')),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _controller.setLanguageCode(value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 14),
              _buildSection(
                context: context,
                title: context.tr('settings.section.notifications'),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.tr('settings.notifications.enable')),
                      subtitle: Text(
                        context.tr('settings.notifications.enable.desc'),
                      ),
                      value: _controller.notificationsEnabled,
                      onChanged: (value) {
                        _controller.setNotificationsEnabled(value);
                      },
                    ),
                    Divider(height: 6, color: theme.dividerColor),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        context.tr('settings.notifications.reminder'),
                      ),
                      subtitle: Text(
                        context.tr('settings.notifications.reminder.desc'),
                      ),
                      value:
                          _controller.appointmentReminders &&
                          _controller.notificationsEnabled,
                      onChanged: _controller.notificationsEnabled
                          ? (value) {
                              _controller.setAppointmentReminders(value);
                            }
                          : null,
                    ),
                    Divider(height: 6, color: theme.dividerColor),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.tr('settings.notifications.promo')),
                      subtitle: Text(
                        context.tr('settings.notifications.promo.desc'),
                      ),
                      value:
                          _controller.promotionsEnabled &&
                          _controller.notificationsEnabled,
                      onChanged: _controller.notificationsEnabled
                          ? (value) {
                              _controller.setPromotionsEnabled(value);
                            }
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildSection(
                context: context,
                title: context.tr('settings.section.suggestion'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SuggestionLine(
                      text: context.tr('settings.suggestion.security'),
                    ),
                    _SuggestionLine(
                      text: context.tr('settings.suggestion.privacy'),
                    ),
                    _SuggestionLine(
                      text: context.tr('settings.suggestion.data'),
                    ),
                    _SuggestionLine(
                      text: context.tr('settings.suggestion.help'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return context.tr('settings.theme.label.dark');
      case ThemeMode.system:
        return context.tr('settings.theme.label.system');
      case ThemeMode.light:
        return context.tr('settings.theme.label.light');
    }
  }
}

class _SuggestionLine extends StatelessWidget {
  const _SuggestionLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
