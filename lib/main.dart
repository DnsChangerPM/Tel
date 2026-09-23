// Tel — «ویرایشگر متن تلگرام»
//
// نقطهٔ ورود برنامه. بدون هیچ پکیج بیرونی؛ بنابراین ساخت روی اندروید و ویندوز
// بدون وابستگی شبکه‌ای (pub.dev) هم انجام می‌شود.

import 'package:flutter/material.dart';

import 'core/app_info.dart';
import 'i18n/l10n.dart';
import 'i18n/localizations.dart';
import 'state/editor_state.dart';
import 'ui/home_screen.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final EditorState state = EditorState();
  await state.bootstrap();
  runApp(TelApp(state: state));
}

class TelApp extends StatelessWidget {
  const TelApp({super.key, required this.state});

  final EditorState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: ListenableBuilder(
        listenable: state,
        builder: (BuildContext context, Widget? child) {
          final L10n l10n = state.l10n;
          return MaterialApp(
            title: AppInfo.titleFa,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: state.themeMode,
            locale: Locale(state.language.code),
            supportedLocales: const <Locale>[Locale('fa'), Locale('en')],
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppMaterialLocalizationsDelegate(),
            ],
            builder: (BuildContext context, Widget? inner) {
              return Directionality(
                textDirection: l10n.direction,
                child: MediaQuery.withClampedTextScaling(
                  minScaleFactor: 0.85,
                  maxScaleFactor: 1.6,
                  child: inner ?? const SizedBox.shrink(),
                ),
              );
            },
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
