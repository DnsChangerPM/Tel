// Tel — «ویرایشگر متن تلگرام»
//
// تب «رشته‌ها»: فهرست همهٔ متن‌های فایل + ویرایش تک‌تک آن‌ها.

import 'package:flutter/material.dart';

import '../core/xml_document.dart';
import '../i18n/l10n.dart';
import '../state/editor_state.dart';
import 'theme.dart';
import 'widgets.dart';

class EntriesPanel extends StatelessWidget {
  const EntriesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final EditorState state = AppScope.of(context);
    final L10n l10n = state.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final List<XmlStringEntry> entries = state.filteredEntries;

    if (state.document.source.trim().isEmpty) {
      return Center(child: Text(l10n.noEntries, style: TextStyle(color: scheme.onSurfaceVariant)));
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: SectionCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        onChanged: state.setEntrySearch,
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 18),
                          hintText: l10n.searchHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InfoChip(
                      label:
                          '${faNum(context, entries.length)} / ${faNum(context, state.document.length)}',
                      icon: Icons.list_alt,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: <Widget>[
                      _filterChip(context, state, EntryFilter.all, l10n.filterAll, Icons.apps),
                      _filterChip(context, state, EntryFilter.untranslated, l10n.filterUntranslated,
                          Icons.translate),
                      _filterChip(context, state, EntryFilter.edited, l10n.filterEdited, Icons.edit_note),
                      _filterChip(context, state, EntryFilter.empty, l10n.filterEmpty, Icons.hourglass_empty),
                      _filterChip(
                          context, state, EntryFilter.technical, l10n.filterTechnical, Icons.build_outlined),
                      const SizedBox(width: 8),
                      ToolButton(
                        icon: Icons.check_circle_outline,
                        label: l10n.applyEdits,
                        onPressed: state.document.hasPendingEdits ? state.applyEditsToText : null,
                        compact: true,
                      ),
                      const SizedBox(width: 6),
                      ToolButton(
                        icon: Icons.undo,
                        label: l10n.revertAll,
                        onPressed: state.document.hasPendingEdits ? state.revertAllEdits : null,
                        compact: true,
                        danger: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(child: Text(l10n.nothingFound, style: TextStyle(color: scheme.onSurfaceVariant)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final XmlStringEntry entry = entries[index];
                    return EntryTile(
                      key: ValueKey<String>('${entry.name}#${entry.outerStart}'),
                      entry: entry,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(
    BuildContext context,
    EditorState state,
    EntryFilter filter,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: FilterChip(
        selected: state.filter == filter,
        onSelected: (_) => state.setFilter(filter),
        avatar: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 11.5)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// کارت ویرایش یک رشته
class EntryTile extends StatefulWidget {
  const EntryTile({super.key, required this.entry});

  final XmlStringEntry entry;

  @override
  State<EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<EntryTile> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // در initState به وضعیت سراسری دسترسی نداریم؛ مقدار خام کافی است چون در
    // build اگر ویرایش در انتظاری وجود داشته باشد همگام‌سازی می‌شود.
    _controller = TextEditingController(text: widget.entry.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isFocused => _focusNode.hasFocus;

  @override
  Widget build(BuildContext context) {
    final EditorState state = AppScope.of(context);
    final L10n l10n = state.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final XmlStringEntry entry = widget.entry;
    final bool edited = state.document.isEntryEdited(entry);
    final List<String> placeholders = entry.placeholders;
    final String currentValue = state.document.valueOf(entry);

    // اگر مقدار از بیرون تغییر کرده (مثلاً «برگشت همه») و کاربر در حال تایپ نیست،
    // همگام‌سازی در پایان فریم انجام می‌شود تا هنگام build وضعیت عوض نشود.
    if (!_isFocused && _controller.text != currentValue) {
      final String value = currentValue;
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (!mounted || _focusNode.hasFocus) return;
        if (_controller.text == value) return;
        _controller.text = value;
      });
    }

    final List<Widget> badges = <Widget>[
      if (placeholders.isNotEmpty)
        InfoChip(label: placeholders.join(' '), icon: Icons.data_object, color: scheme.tertiary),
      if (!entry.translatable) InfoChip(label: l10n.notTranslatable, icon: Icons.block, color: scheme.error),
      if (entry.isDuplicate) InfoChip(label: l10n.duplicate, icon: Icons.copy_all, color: scheme.error),
      if (entry.looksUntranslated)
        InfoChip(label: l10n.filterUntranslated, icon: Icons.translate, color: AppTheme.brandOrange),
    ];

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
      color: edited
          ? scheme.primaryContainer
          : Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SelectableText(
            entry.name,
            maxLines: 1,
            style: AppTheme.monoStyle(context, size: 12.5, color: scheme.primary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (edited)
                InfoChip(label: l10n.edited, icon: Icons.edit, color: scheme.primary, dense: true),
              InfoChip(
                label: '${l10n.lineLabel} ${faNum(context, entry.line)}',
                icon: Icons.tag,
                color: scheme.onSurfaceVariant,
                dense: true,
              ),
              ...badges,
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  minLines: 1,
                  style: TextStyle(fontSize: 14, height: 1.6, color: scheme.onSurface),
                  onChanged: (String value) => state.setEntryValue(entry, value),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: scheme.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: const OutlineInputBorder(),
                    hintText: entry.value.isEmpty ? '(${l10n.filterEmpty})' : null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: l10n.copy,
                icon: const Icon(Icons.content_copy, size: 18),
                onPressed: () => state.copyToClipboard(currentValue, message: l10n.statusCopied),
              ),
              IconButton(
                tooltip: l10n.revert,
                icon: Icon(Icons.undo, size: 18, color: edited ? scheme.error : scheme.onSurfaceVariant),
                onPressed: edited ? () => state.revertEntry(entry) : null,
              ),
            ],
          ),
          if (entry.preview != entry.value) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              entry.preview,
              style: TextStyle(fontSize: 12.5, height: 1.6, color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}
