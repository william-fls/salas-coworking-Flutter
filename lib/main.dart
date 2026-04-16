import 'package:flutter/material.dart';

import 'screens/salas_screen.dart';
import 'screens/agendamentos_screen.dart';
import 'screens/logs_screen.dart';

void main() => runApp(const CoworkingApp());

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

  static const _screens = [
    AgendamentosScreen(),
    SalasScreen(),
    LogsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
