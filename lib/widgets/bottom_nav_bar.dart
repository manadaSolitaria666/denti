// lib/widgets/bottom_nav_bar.dart
import 'package:dental_ai_app/core/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBarScaffold extends StatefulWidget {
  final Widget child; // El contenido de la pestaña actual

  const BottomNavBarScaffold({super.key, required this.child});

  @override
  State<BottomNavBarScaffold> createState() => _BottomNavBarScaffoldState();
}

class _BottomNavBarScaffoldState extends State<BottomNavBarScaffold> {
  // Determina el índice actual basado en la ruta de GoRouter
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.homePath)) {
      return 0;
    }
    if (location.startsWith(AppRoutes.diagnosisHistoryPath)) {
      return 1;
    }
    if (location.startsWith(AppRoutes.blogListPath)) {
      return 2;
    }
    if (location.startsWith(AppRoutes.nearbyClinicsMapPath)) {
      return 3;
    }
    if (location.startsWith(AppRoutes.remindersSettingsPath)) {
      return 4;
    }
    return 0; // Por defecto a Home
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed(AppRoutes.home);
        break;
      case 1:
        context.goNamed(AppRoutes.diagnosisHistory);
        break;
      case 2:
        context.goNamed(AppRoutes.blogList);
        break;
      case 3:
        context.goNamed(AppRoutes.nearbyClinicsMap);
        break;
      case 4:
        context.goNamed(AppRoutes.remindersSettings);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child, // Muestra la pantalla actual de la ruta anidada
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed, // Para más de 3 items, o shifting
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: 'Blog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
        // Puedes personalizar colores aquí:
        // selectedItemColor: Theme.of(context).colorScheme.primary,
        // unselectedItemColor: Colors.grey,
      ),
    );
  }
}
