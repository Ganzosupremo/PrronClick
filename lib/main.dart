// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:material_ui/material_ui.dart';

import 'app_state.dart';
import 'metronome_page.dart';
import 'settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PrronClickApp(state: await AppState.load()));
}

class PrronClickApp extends StatelessWidget {
  const PrronClickApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PrronClick',
      themeMode: ThemeMode.system,
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepOrange,
        brightness: Brightness.dark,
      ),
      home: state.audioOk
          ? HomePage(state: state)
          : const Scaffold(
              body: Center(child: Text('No se pudo abrir la salida de audio.')),
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

  static const titles = ['Metrónomo', 'Canciones', 'Setlists'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[tab]),
        actions: [
          IconButton(
            tooltip: 'Ajustes',
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
            const _ComingSoon(
              icon: Icons.library_music_outlined,
              text: 'Aquí podrás crear canciones con nombre, tempo, compás y duración.',
            ),
            const _ComingSoon(
              icon: Icons.queue_music_outlined,
              text: 'Aquí podrás armar setlists con tus canciones.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            label: 'Metrónomo',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            label: 'Canciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music_outlined),
            label: 'Setlists',
          ),
        ],
      ),
    );
  }
}

// shortcut: empty tabs until phases 3 (songs) and 4 (setlists).
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Próximamente', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
