import 'package:flutter/material.dart';

import 'database/database_factory_setup_stub.dart'
    if (dart.library.io) 'database/database_factory_setup_io.dart'
    if (dart.library.html) 'database/database_factory_setup_web.dart'
    as database_factory_setup;
import 'screens/salas_screen.dart';
import 'screens/agendamentos_screen.dart';
import 'screens/logs_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await database_factory_setup.initializeDatabaseFactory();
  runApp(const CoworkingApp());
}

class CoworkingApp extends StatelessWidget {
  const CoworkingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coworking Rooms',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1565C0),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const _HomeShell(),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell();

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;
  int _salasRefreshToken = 0;

  List<Widget> get _screens => [
        const AgendamentosScreen(),
        SalasScreen(refreshToken: _salasRefreshToken),
        const LogsScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() {
          _index = i;
          if (i == 1) {
            _salasRefreshToken++;
          }
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Agendamentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.meeting_room_outlined),
            selectedIcon: Icon(Icons.meeting_room),
            label: 'Salas',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Logs',
          ),
        ],
      ),
    );
  }
}
