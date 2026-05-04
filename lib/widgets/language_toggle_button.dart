import 'package:flutter/material.dart';

import '../l10n/locale_controller.dart';
import '../l10n/theme_controller.dart';

class AppHeaderActions extends StatelessWidget {
  const AppHeaderActions({super.key});

  String _settingsTitle(BuildContext context) => 'Settings';

  String _themeLabel(BuildContext context) => 'Theme';

  String _themeValue(BuildContext context, ThemeMode mode) {
    final isDark = mode == ThemeMode.dark;
    return isDark ? 'Dark' : 'Light';
  }

  String _languageLabel(BuildContext context) => 'Language';

  String _languageValue(BuildContext context) {
    final isMn = localeController.value.languageCode == 'mn';
    return isMn ? 'MN' : 'EN';
  }

  Future<void> _openSettingsSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _settingsTitle(sheetContext),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeController,
                  builder: (context, mode, _) {
                    final isDark = mode == ThemeMode.dark;
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Icon(
                          isDark
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                        ),
                        title: Text(_themeLabel(context)),
                        subtitle: Text(_themeValue(context, mode)),
                        trailing: Switch(
                          value: isDark,
                          onChanged: (_) => themeController.toggleTheme(),
                        ),
                        onTap: themeController.toggleTheme,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<Locale>(
                  valueListenable: localeController,
                  builder: (context, locale, _) {
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.language_rounded),
                        title: Text(_languageLabel(context)),
                        subtitle: Text(_languageValue(context)),
                        trailing: FilledButton.tonal(
                          onPressed: localeController.toggleLanguage,
                          child: Text(
                            locale.languageCode == 'mn' ? 'EN' : 'MN',
                          ),
                        ),
                        onTap: localeController.toggleLanguage,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: _settingsTitle(context),
      onPressed: () => _openSettingsSheet(context),
      icon: const Icon(Icons.settings_outlined),
    );
  }
}
