// Tel — «ویرایشگر متن تلگرام»
//
// تب «بررسی سلامت»: نتیجهٔ اعتبارسنجی فایل و مقایسه با فایل مرجع انگلیسی.

import 'package:flutter/material.dart';

import '../core/xml_validation.dart';
import '../i18n/l10n.dart';
import '../state/editor_state.dart';
import 'theme.dart';
import 'widgets.dart';

class IssuesPanel extends StatelessWidget {
  const IssuesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final EditorState state = AppScope.of(context);
    final L10n l10n = state.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final ValidationReport? report = state.report;
    final List<ValidationIssue> issues = report?.issues ?? <ValidationIssue>[];

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    ToolButton(
                      icon: Icons.fact_check_outlined,
                      label: l10n.validateNow,
                      onPressed: () {
                        final ValidationReport fresh = state.validate();
                        state.showStatus(
                          fresh.issues.isEmpty
                              ? l10n.noIssues
                              : '${num(context, fresh.errorCount)} ${l10n.severityError} • '
                                  '${num(context, fresh.warningCount)} ${l10n.severityWarning} • '
                                  '${num(context, fresh.infoCount)} ${l10n.severityInfo}',
                          isError: fresh.hasErrors,
                        );
                      },
                    ),
                    ToolButton(
                      icon: Icons.translate,
                      label: l10n.loadEnglishReference,
                      onPressed: state.loadEnglishReference,
                      compact: true,
                    ),
                    ToolButton(
                      icon: Icons.copy_all,
                      label: l10n.copyReport,
                      onPressed: issues.isEmpty
                          ? null
                          : () => state.copyToClipboard(
                                issues.map((ValidationIssue i) => i.toString()).join('\n'),
                              ),
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InfoChip(
                  label: state.englishBaselineName ?? l10n.englishReferenceHint,
                  icon: Icons.info_outline,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    InfoChip(
                      label: '${l10n.severityError}: ${num(context, report?.errorCount ?? 0)}',
                      icon: Icons.error_outline,
                      color: scheme.error,
                      dense: false,
                    ),
                    InfoChip(
                      label: '${l10n.severityWarning}: ${num(context, report?.warningCount ?? 0)}',
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.brandOrange,
                      dense: false,
                    ),
                    InfoChip(
                      label: '${l10n.severityInfo}: ${num(context, report?.infoCount ?? 0)}',
                      icon: Icons.tips_and_updates_outlined,
                      color: scheme.tertiary,
                      dense: false,
                    ),
                    InfoChip(
                      label: '${l10n.entryCount}: ${num(context, state.document.length)}',
                      icon: Icons.list_alt,
                      color: scheme.primary,
                      dense: false,
                    ),
                    InfoChip(
                      label: '${l10n.filterUntranslated}: ${num(context, state.document.untranslatedCount)}',
                      icon: Icons.translate,
                      color: AppTheme.brandTeal,
                      dense: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: issues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.verified, size: 42, color: scheme.tertiary),
                      const SizedBox(height: 10),
                      Text(l10n.noIssues, style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: issues.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (BuildContext context, int index) {
                    return _IssueTile(issue: issues[index]);
                  },
                ),
        ),
      ],
    );
  }
}

class _IssueTile extends StatelessWidget {
  const _IssueTile({required this.issue});

  final ValidationIssue issue;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final (IconData icon, Color color) = switch (issue.severity) {
      IssueSeverity.error => (Icons.error_outline, scheme.error),
      IssueSeverity.warning => (Icons.warning_amber_rounded, AppTheme.brandOrange),
      IssueSeverity.info => (Icons.info_outline, scheme.tertiary),
    };

    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(issue.message, style: const TextStyle(fontSize: 13, height: 1.6)),
                const SizedBox(height: 2),
                Text(
                  <String>[
                    issue.code,
                    if (issue.line != null) '${AppScope.of(context).l10n.lineLabel} ${num(context, issue.line!)}',
                    if (issue.name != null) issue.name!,
                  ].join(' • '),
                  style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
