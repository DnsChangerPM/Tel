// Tel — «ویرایشگر متن تلگرام»
//
// تب «راهنما»: آموزش کار + تنظیمات + درباره.

import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../i18n/l10n.dart';
import '../state/editor_state.dart';
import 'theme.dart';
import 'widgets.dart';

class HelpPanel extends StatelessWidget {
  const HelpPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final EditorState state = AppScope.of(context);
    final L10n l10n = state.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.settings, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(l10n.settings, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(l10n.language, style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    for (final AppLanguage lang in AppLanguage.values)
                      ChoiceChip(
                        label: Text(lang.label),
                        selected: state.language == lang,
                        onSelected: (_) => state.setLanguage(lang),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(l10n.theme, style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: <Widget>[
                    ChoiceChip(
                      label: Text(l10n.themeDark),
                      selected: state.themeMode == ThemeMode.dark,
                      onSelected: (_) => state.setThemeMode(ThemeMode.dark),
                    ),
                    ChoiceChip(
                      label: Text(l10n.themeLight),
                      selected: state.themeMode == ThemeMode.light,
                      onSelected: (_) => state.setThemeMode(ThemeMode.light),
                    ),
                    ChoiceChip(
                      label: Text(l10n.themeSystem),
                      selected: state.themeMode == ThemeMode.system,
                      onSelected: (_) => state.setThemeMode(ThemeMode.system),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.menu_book_outlined, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(l10n.tabHelp, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                SelectableText(
                  l10n.helpBody.trim(),
                  style: const TextStyle(fontSize: 13, height: 1.9),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.info_outline, size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Text(l10n.about, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                SelectableText(
                  AppInfo.aboutFa.trim(),
                  style: const TextStyle(fontSize: 13, height: 1.9),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    InfoChip(
                      label: '${l10n.version}: ${AppInfo.fullVersion}',
                      icon: Icons.numbers,
                      dense: false,
                    ),
                    InfoChip(
                      label: '${l10n.buildTime}: ${AppInfo.buildTime}',
                      icon: Icons.schedule,
                      color: AppTheme.brandTeal,
                      dense: false,
                    ),
                    InfoChip(
                      label: '${l10n.buildChannel}: ${AppInfo.buildChannel}',
                      icon: Icons.alt_route,
                      color: AppTheme.brandOrange,
                      dense: false,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SelectableText(
                        AppInfo.repository,
                        style: AppTheme.monoStyle(context, size: 12),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.copy,
                      icon: const Icon(Icons.content_copy, size: 18),
                      onPressed: () => state.copyToClipboard(AppInfo.repository),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
