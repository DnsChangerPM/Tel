// Tel — «ویرایشگر متن تلگرام»
//
// ویجت‌های مشترک رابط کاربری.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_info.dart';
import '../i18n/l10n.dart';
import '../state/editor_state.dart';
import 'theme.dart';

/// میان‌برهای صفحه‌کلید رومیزی (Ctrl+O / Ctrl+S / Ctrl+Shift+S / Ctrl+F)
class AppShortcuts extends StatelessWidget {
  const AppShortcuts({
    super.key,
    required this.child,
    required this.onOpen,
    required this.onSave,
    required this.onSaveAs,
    required this.onFind,
  });

  final Widget child;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onSaveAs;
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): onOpen,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): onSave,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true): onSaveAs,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): onFind,
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}

/// تبدیل رقم‌ها به فارسی در حالت زبان فارسی
String faDigits(AppLanguage language, Object value) {
  final String text = value.toString();
  if (language != AppLanguage.fa) return text;
  const String persian = '۰۱۲۳۴۵۶۷۸۹';
  return text.replaceAllMapped(RegExp('[0-9]'), (Match m) => persian[int.parse(m[0]!)]).replaceAll('.', '٫');
}

String num(BuildContext context, Object value) => faDigits(AppScope.of(context).language, value);

/// دکمهٔ نوار ابزار
class ToolButton extends StatelessWidget {
  const ToolButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
    this.tooltip,
    this.danger = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool danger;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color? fg = onPressed == null
        ? scheme.onSurfaceVariant
        : (danger ? scheme.error : scheme.onSurface);
    final Widget child = compact
        ? TextButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18, color: fg),
            label: Text(label, style: TextStyle(fontSize: 13, color: fg)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 36),
            ),
          )
        : FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: Icon(icon, size: 18, color: fg),
            label: Text(label, style: TextStyle(fontSize: 13, color: fg)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 38),
            ),
          );
    return Tooltip(message: tooltip ?? label, child: child);
  }
}

/// کارت بخش‌ها
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding, this.color});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      padding: padding ?? const EdgeInsets.all(12),
      child: child,
    );
  }
}

/// برچسب کوچک اطلاعاتی
class InfoChip extends StatelessWidget {
  const InfoChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.dense = true,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color base = color ?? scheme.primary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: base),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 13 : 15, color: base),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: dense ? 11.5 : 12.5,
              color: base,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// نوار وضعیت پایین صفحه
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final EditorState state = AppScope.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final L10n l10n = state.l10n;

    final Color statusColor = state.statusIsError ? scheme.error : scheme.onSurfaceVariant;

    final Widget message = Row(
      children: <Widget>[
        Icon(
          state.statusIsError ? Icons.error_outline : Icons.info_outline,
          size: 16,
          color: statusColor,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            state.statusMessage.isEmpty ? l10n.statusReady : state.statusMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: statusColor),
          ),
        ),
        if (state.busy)
          const Padding(
            padding: EdgeInsetsDirectional.only(end: 10),
            child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      ],
    );

    final List<Widget> chips = <Widget>[
      InfoChip(
        label: '${l10n.entryCount}: ${num(context, state.document.length)}',
        icon: Icons.list_alt,
        color: scheme.primary,
      ),
      InfoChip(
        label: '${num(context, state.document.changedCount)} ${l10n.edited}',
        icon: state.isDirty ? Icons.edit_note : Icons.check_circle_outline,
        color: state.isDirty ? AppTheme.brandOrange : scheme.tertiary,
      ),
      InfoChip(
        label: state.isDirty ? l10n.statusDirty : l10n.statusSaved,
        icon: state.isDirty ? Icons.warning_amber_rounded : Icons.verified_outlined,
        color: state.isDirty ? scheme.error : scheme.tertiary,
      ),
    ];

    final bool narrow = MediaQuery.sizeOf(context).width < 620;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                message,
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 6, children: chips),
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(child: message),
                Wrap(spacing: 6, children: chips),
              ],
            ),
    );
  }
}

/// صفحهٔ خوش‌آمد (وقتی هنوز فایلی باز نشده)
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key, required this.onOpen, required this.onSample, required this.onPaste});

  final VoidCallback onOpen;
  final VoidCallback onSample;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    final EditorState state = AppScope.of(context);
    final L10n l10n = state.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: SectionCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: <Color>[AppTheme.brandBlue, AppTheme.brandTeal]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_note, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.appTitle,
                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            l10n.appSubtitle,
                            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.noEntries,
                  style: TextStyle(fontSize: 13.5, height: 1.7, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: <Widget>[
                    FilledButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.folder_open, size: 18),
                      label: Text(l10n.openFile),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: onSample,
                      icon: const Icon(Icons.science_outlined, size: 18),
                      label: Text(l10n.openSample),
                    ),
                    OutlinedButton.icon(
                      onPressed: onPaste,
                      icon: const Icon(Icons.content_paste, size: 18),
                      label: Text(l10n.pasteFromClipboard),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  '${l10n.version}: ${AppInfo.fullVersion} — ${l10n.buildChannel}: ${AppInfo.buildChannel}',
                  style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
