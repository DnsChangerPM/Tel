// Tel — «ویرایشگر متن تلگرام»
//
// تب «متن فایل»: ویرایشگر خام XML به‌همراه جست‌وجو و جایگزینی.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../i18n/l10n.dart';
import '../state/editor_state.dart';
import 'theme.dart';
import 'widgets.dart';

class EditorPanel extends StatefulWidget {
  const EditorPanel({
    super.key,
    required this.searchFocusNode,
    required this.onOpen,
    required this.onSave,
    required this.onSaveAs,
    required this.onSample,
    required this.onPaste,
    required this.onManualPath,
  });

  final FocusNode searchFocusNode;
  final VoidCallback onOpen;
  final VoidCallback onSave;
  final VoidCallback onSaveAs;
  final VoidCallback onSample;
  final VoidCallback onPaste;
  final VoidCallback onManualPath;

  @override
  State<EditorPanel> createState() => _EditorPanelState();
}

class _EditorPanelState extends State<EditorPanel> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _regex = false;
  bool _caseSensitive = false;
  String? _regexError;
  int _lastMatchIndex = -1;
  int _cursorLine = 1;
  int _cursorColumn = 1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateCursor);
  }

  @override
  void dispose() {
    _controller.removeListener(_updateCursor);
    _controller.dispose();
    _searchController.dispose();
    _replaceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncFromState(EditorState state) {
    if (_controller.text != state.document.source) {
      final TextSelection selection = _controller.selection;
      _controller.value = TextEditingValue(
        text: state.document.source,
        selection: selection.baseOffset <= state.document.source.length
            ? selection
            : TextSelection.collapsed(offset: state.document.source.length),
      );
      _updateCursor();
    }
  }

  void _updateCursor() {
    if (!mounted) return;
    final int offset = _controller.selection.baseOffset.clamp(0, _controller.text.length);
    final String before = _controller.text.substring(0, offset);
    final int lastNewline = before.lastIndexOf('\n');
    final int line = '\n'.allMatches(before).length + 1;
    final int column = offset - lastNewline;
    if (line == _cursorLine && column == _cursorColumn) return;

    // هنگام build نمی‌توان setState صدا زد (مثلاً وقتی متن از بیرون همگام می‌شود)
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      _cursorLine = line;
      _cursorColumn = column;
      return;
    }
    setState(() {
      _cursorLine = line;
      _cursorColumn = column;
    });
  }

  RegExp? _buildPattern() {
    final String needle = _searchController.text;
    if (needle.isEmpty) return null;
    try {
      _regexError = null;
      return RegExp(_regex ? needle : RegExp.escape(needle), caseSensitive: _caseSensitive, multiLine: true);
    } on FormatException catch (error) {
      _regexError = error.message;
      return null;
    }
  }

  int _matchCount() {
    final RegExp? pattern = _buildPattern();
    if (pattern == null) return 0;
    return pattern.allMatches(_controller.text).length;
  }

  void _findNext() {
    final RegExp? pattern = _buildPattern();
    if (pattern == null) return;
    final Iterable<RegExpMatch> matches = pattern.allMatches(_controller.text);
    if (matches.isEmpty) {
      setState(() => _lastMatchIndex = -1);
      return;
    }
    final int start = _controller.selection.baseOffset;
    RegExpMatch? next;
    for (final RegExpMatch m in matches) {
      if (m.start > start) {
        next = m;
        break;
      }
    }
    next ??= matches.first;
    _selectRange(next.start, next.end);
  }

  void _selectRange(int start, int end) {
    _controller.selection = TextSelection(baseOffset: start, extentOffset: end);
    setState(() => _lastMatchIndex = start);
    // اسکرول تقریبی به محل تطابق
    final double line = _cursorLineOf(start);
    final double total = (_controller.text.split('\n').length).clamp(1, 1 << 30).toDouble();
    if (_scrollController.hasClients) {
      final double max = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo((line / total * max).clamp(0, max));
    }
    _updateCursor();
  }

  double _cursorLineOf(int offset) => '\n'.allMatches(_controller.text.substring(0, offset)).length.toDouble();

  void _replaceCurrent() {
    final RegExp? pattern = _buildPattern();
    if (pattern == null) return;
    final TextSelection selection = _controller.selection;
    final String selected = selection.textInside(_controller.text);
    if (selected.isEmpty || pattern.matchAsPrefix(selected) == null) {
      _findNext();
      return;
    }
    final String replacement = _regex
        ? selected.replaceFirstMapped(pattern, _replaceController.text)
        : _replaceController.text;
    final String updated = _controller.text.replaceRange(selection.start, selection.end, replacement);
    _controller.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: selection.start + replacement.length),
    );
    _apply(updated);
    _findNext();
  }

  void _replaceAllMatches() {
    final RegExp? pattern = _buildPattern();
    if (pattern == null) return;
    final String source = _controller.text;
    final String updated = _regex
        ? source.replaceAllMapped(pattern, (Match m) => _replaceController.text)
        : source.replaceAll(pattern, _replaceController.text);
    final int count = pattern.allMatches(source).length;
    _controller.value = TextEditingValue(text: updated, selection: const TextSelection.collapsed(offset: 0));
    _apply(updated);
    setState(() {});
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${num(context, count)} ${AppScope.of(context).l10n.matchesFound}')),
      );
    }
  }

  void _apply(String text) {
    AppScope.of(context).updateSource(text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final EditorState state = AppScope.of(context);
    final L10n l10n = state.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    _syncFromState(state);

    final int matches = _matchCount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              ToolButton(icon: Icons.folder_open, label: l10n.openFile, onPressed: widget.onOpen, tooltip: 'Ctrl+O'),
              ToolButton(icon: Icons.science_outlined, label: l10n.openSample, onPressed: widget.onSample),
              ToolButton(
                icon: Icons.save_outlined,
                label: l10n.save,
                onPressed: widget.onSave,
                tooltip: 'Ctrl+S',
              ),
              ToolButton(
                icon: Icons.save_as_outlined,
                label: l10n.saveAs,
                onPressed: widget.onSaveAs,
                tooltip: 'Ctrl+Shift+S',
                compact: true,
              ),
              ToolButton(
                icon: Icons.download_outlined,
                label: l10n.pasteFromClipboard,
                onPressed: widget.onPaste,
                compact: true,
              ),
              ToolButton(
                icon: Icons.content_copy_outlined,
                label: l10n.copyAll,
                onPressed: () => state.copyToClipboard(_controller.text),
                compact: true,
              ),
              ToolButton(
                icon: Icons.link,
                label: l10n.enterPathManually,
                onPressed: widget.onManualPath,
                compact: true,
              ),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SectionCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: widget.searchFocusNode,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: const Icon(Icons.search, size: 18),
                          hintText: l10n.searchHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _replaceController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          isDense: true,
                          prefixIcon: const Icon(Icons.find_replace, size: 18),
                          hintText: l10n.replaceHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: <Widget>[
                    FilterChip(
                      label: Text(l10n.useRegex, style: const TextStyle(fontSize: 11.5)),
                      selected: _regex,
                      onSelected: (bool v) => setState(() => _regex = v),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      label: Text(l10n.caseSensitive, style: const TextStyle(fontSize: 11.5)),
                      selected: _caseSensitive,
                      onSelected: (bool v) => setState(() => _caseSensitive = v),
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 8),
                    if (_regexError != null)
                      Expanded(
                        child: Text(
                          _regexError!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: scheme.error),
                        ),
                      )
                    else
                      InfoChip(
                        label: '${num(context, matches)} ${l10n.matchesFound}',
                        icon: Icons.filter_alt_outlined,
                        color: matches > 0 ? scheme.primary : scheme.onSurfaceVariant,
                      ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: matches > 0 ? _findNext : null,
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      label: Text(l10n.goToNext),
                    ),
                    TextButton.icon(
                      onPressed: matches > 0 ? _replaceCurrent : null,
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: Text(l10n.replace),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: matches > 0 ? _replaceAllMatches : null,
                      icon: const Icon(Icons.auto_fix_high, size: 18),
                      label: Text(l10n.replaceAll),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: SectionCard(
              padding: const EdgeInsets.all(6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      scrollController: _scrollController,
                      onChanged: (String text) {
                        state.updateSource(text);
                        setState(() {});
                      },
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: AppTheme.monoStyle(context),
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(8),
                        hintText: '<?xml version="1.0" encoding="utf-8"?>\n<resources>...</resources>',
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      InfoChip(label: '${l10n.lineLabel}: ${num(context, _cursorLine)}', icon: Icons.tag),
                      const SizedBox(width: 6),
                      InfoChip(label: '${num(context, _cursorColumn)}', icon: Icons.arrow_right_alt),
                      const SizedBox(width: 6),
                      InfoChip(
                        label: '${num(context, _controller.text.length)} char',
                        icon: Icons.data_object,
                        color: scheme.onSurfaceVariant,
                      ),
                      const Spacer(),
                      InfoChip(
                        label: state.isDirty ? l10n.statusDirty : l10n.statusSaved,
                        color: state.isDirty ? scheme.error : scheme.tertiary,
                        icon: state.isDirty ? Icons.warning_amber_rounded : Icons.check,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
