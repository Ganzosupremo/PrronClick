// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';
import 'history_page.dart';
import 'l10n/app_localizations.dart';
import 'metronome_page.dart';
import 'setlists_page.dart';
import 'settings_page.dart';
import 'songs_page.dart';
import 'theme.dart';
import 'transfer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PrronClickApp(state: await AppState.load()));
}

class PrronClickApp extends StatelessWidget {
  const PrronClickApp({super.key, required this.state});

  final AppState state;

  static final _light = stageTheme(Brightness.light);
  static final _dark = stageTheme(Brightness.dark);

  /// English first: it is what a phone in any other language gets.
  static const languages = [Locale('en'), Locale('es'), Locale('de')];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => MaterialApp(
        title: 'PrronClick',
        themeMode: ThemeMode.system,
        theme: _light,
        darkTheme: _dark,
        // null: the phone's language.
        locale: switch (state.library.language) {
          '' => null,
          final code => Locale(code),
        },
        supportedLocales: languages,
        // material_ui's own delegates: Flutter's would not reach its widgets.
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: state.audioOk
            ? HomePage(state: state)
            : Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: Text(AppLocalizations.of(context).audioFailed),
                  ),
                ),
              ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.state});

  final AppState state;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: PageTitle([t.tabMetronome, t.tabSongs, t.tabSetlists][tab]),
        actions: [
          if (tab == 1)
            PopupMenuButton<bool>(
              tooltip: t.importExport,
              icon: const Icon(Icons.import_export),
              onSelected: (import) => import
                  ? importSongs(context, widget.state)
                  : exportSongs(context, widget.state),
              itemBuilder: (_) => [
                PopupMenuItem(value: true, child: Text(t.importSongs)),
                PopupMenuItem(value: false, child: Text(t.exportSongs)),
              ],
            ),
          if (tab == 2)
            IconButton(
              tooltip: t.importSetlist,
              icon: const Icon(Icons.file_open_outlined),
              onPressed: () => importSetlist(context, widget.state),
            ),
          IconButton(
            tooltip: t.history,
            icon: const Icon(Icons.insights_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => HistoryPage(state: widget.state),
              ),
            ),
          ),
          IconButton(
            tooltip: t.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsPage(state: widget.state),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        // IndexedStack keeps the metronome running while other tabs show.
        child: IndexedStack(
          index: tab,
          children: [
            MetronomePage(state: widget.state),
            SongsPage(
              state: widget.state,
              onLoaded: () => setState(() => tab = 0),
            ),
            SetlistsPage(
              state: widget.state,
              onStarted: () => setState(() => tab = 0),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.timer_outlined),
            label: t.tabMetronome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.library_music_outlined),
            label: t.tabSongs,
          ),
          NavigationDestination(
            icon: const Icon(Icons.queue_music_outlined),
            label: t.tabSetlists,
          ),
        ],
      ),
    );
  }
}
