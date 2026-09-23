// Tel — «ویرایشگر متن تلگرام»
//
// صفحهٔ اصلی: نوار بالا، تب‌ها و نوار وضعیت.

import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../i18n/l10n.dart';
import '../state/editor_state.dart';
import 'editor_panel.dart';
import 'entries_panel.dart';
import 'help_panel.dart';
import 'issues_panel.dart';
import 'theme.dart';
import 'widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _tabs.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  EditorState get state => AppScope.of(context);

  // ---------------------------------------------------------------------------
  // عملیات
  // ---------------------------------------------------------------------------

  Future<void> _openFile() async {
    if (!await _confirmDiscard() || !mounted) return;
    await state.openFile();
  }

  Future<void> _save() async {
    final bool ok = await state.save();
    if (ok && mounted) _toast(state.l10n.statusSaved);
  }

  Future<void> _saveAs() async {
    final bool ok = await state.save(asNew: true);
    if (ok && mounted) _toast(state.l10n.statusSaved);
  }

  Future<void> _paste() async {
    if (!await _confirmDiscard() || !mounted) return;
    final String? text = await state.pasteFromClipboard();
    if (!mounted) return;
    if (text == null) {
      _toast(state.l10n.statusError, isError: true);
    }
  }

  Future<void> _sample() async {
    if (!await _confirmDiscard() || !mounted) return;
    await state.loadSample();
    if (!mounted) return;
    _toast(state.l10n.sampleNotice);
  }

  Future<void> _manualPath() async {
    final L10n l10n = state.l10n;
    final TextEditingController controller =
        TextEditingController(text: state.filePath ?? state.lastDirectory ?? '');
    final String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.enterPathManually),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 2,
            minLines: 1,
            decoration: InputDecoration(
              labelText: l10n.pathLabel,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.loadFromPath),
          ),
        ],
      ),
    );
    // آزادسازی کنترلر بعد از بسته‌شدن کامل دیالوگ
    Future<void>.delayed(const Duration(milliseconds: 500), controller.dispose);
    if (result == null || result.trim().isEmpty) return;
    if (!await _confirmDiscard() || !mounted) return;
    await state.openPath(result);
  }

  Future<bool> _confirmDiscard() async {
    if (!state.isDirty) return true;
    final L10n l10n = state.l10n;
    final bool? answer = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.statusDirty),
        content: Text(l10n.discardQuestion),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.close)),
        ],
      ),
    );
    return answer ?? false;
  }

  void _toast(String message, {bool isError = false}) {
    if (!mounted) return;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: isError ? TextStyle(color: scheme.onErrorContainer) : null,
        ),
        backgroundColor: isError ? scheme.errorContainer : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final EditorState state = AppScope.of(context);
    final L10n l10n = state.l10n;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool empty = state.document.source.trim().isEmpty;

    return AppShortcuts(
      onOpen: _openFile,
      onSave: _save,
      onSaveAs: _saveAs,
      onFind: () {
        _tabs.animateTo(0);
        _searchFocus.requestFocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: scheme.surface,
          titleSpacing: 12,
          title: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: <Color>[AppTheme.brandBlue, AppTheme.brandTeal]),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.edit_note, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(l10n.appTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                      '${state.displayName}  •  v${AppInfo.version}',
                      style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            if (state.busy)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
              ),
            IconButton(
              tooltip: l10n.openFile,
              onPressed: _openFile,
              icon: const Icon(Icons.folder_open),
            ),
            IconButton(
              tooltip: l10n.save,
              onPressed: _save,
              icon: Icon(
                state.isDirty ? Icons.save : Icons.save_outlined,
                color: state.isDirty ? AppTheme.brandOrange : null,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: l10n.settings,
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                switch (value) {
                  case 'sample':
                    _sample();
                    break;
                  case 'saveAs':
                    _saveAs();
                    break;
                  case 'copyAll':
                    state.copyToClipboard(state.document.render());
                    break;
                  case 'clear':
                    state.clearAll();
                    break;
                  case 'paste':
                    _paste();
                    break;
                  case 'manualPath':
                    _manualPath();
                    break;
                  case 'help':
                    _tabs.animateTo(3);
                    break;
                  case 'lang_fa':
                    state.setLanguage(AppLanguage.fa);
                    break;
                  case 'lang_en':
                    state.setLanguage(AppLanguage.en);
                    break;
                  case 'theme_dark':
                    state.setThemeMode(ThemeMode.dark);
                    break;
                  case 'theme_light':
                    state.setThemeMode(ThemeMode.light);
                    break;
                  case 'theme_system':
                    state.setThemeMode(ThemeMode.system);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(value: 'sample', child: Text(l10n.openSample)),
                PopupMenuItem<String>(value: 'paste', child: Text(l10n.pasteFromClipboard)),
                PopupMenuItem<String>(value: 'saveAs', child: Text(l10n.saveAs)),
                PopupMenuItem<String>(value: 'copyAll', child: Text(l10n.copyAll)),
                PopupMenuItem<String>(value: 'manualPath', child: Text(l10n.enterPathManually)),
                const PopupMenuDivider(),
                PopupMenuItem<String>(value: 'theme_dark', child: Text('${l10n.theme}: ${l10n.themeDark}')),
                PopupMenuItem<String>(value: 'theme_light', child: Text('${l10n.theme}: ${l10n.themeLight}')),
                PopupMenuItem<String>(value: 'theme_system', child: Text('${l10n.theme}: ${l10n.themeSystem}')),
                PopupMenuItem<String>(value: 'lang_fa', child: Text('${l10n.language}: فارسی')),
                PopupMenuItem<String>(value: 'lang_en', child: Text('${l10n.language}: English')),
                const PopupMenuDivider(),
                PopupMenuItem<String>(value: 'clear', child: Text(l10n.clear)),
                PopupMenuItem<String>(value: 'help', child: Text(l10n.tabHelp)),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: <Widget>[
              Tab(icon: const Icon(Icons.code, size: 18), text: l10n.tabEditor),
              Tab(icon: const Icon(Icons.list_alt, size: 18), text: l10n.tabEntries),
              Tab(icon: const Icon(Icons.fact_check_outlined, size: 18), text: l10n.tabIssues),
              Tab(icon: const Icon(Icons.menu_book_outlined, size: 18), text: l10n.tabHelp),
            ],
          ),
        ),
        body: empty
            ? WelcomeView(onOpen: _openFile, onSample: _sample, onPaste: _paste)
            : TabBarView(
                controller: _tabs,
                children: <Widget>[
                  EditorPanel(
                    searchFocusNode: _searchFocus,
                    onOpen: _openFile,
                    onSave: _save,
                    onSaveAs: _saveAs,
                    onSample: _sample,
                    onPaste: _paste,
                    onManualPath: _manualPath,
                  ),
                  const EntriesPanel(),
                  const IssuesPanel(),
                  const HelpPanel(),
                ],
              ),
        bottomNavigationBar: const SafeArea(child: StatusBar()),
      ),
    );
  }
}
