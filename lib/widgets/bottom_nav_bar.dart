// lib/widgets/bottom_nav_bar.dart
import 'package:dental_ai_app/core/navigation/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomNavBarScaffold extends StatefulWidget {
  final Widget child;

  const BottomNavBarScaffold({super.key, required this.child});

  @override
  State<BottomNavBarScaffold> createState() => _BottomNavBarScaffoldState();
}

class _BottomNavBarScaffoldState extends State<BottomNavBarScaffold> {
  
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    // La nueva estructura de navegación con 4 pestañas
    if (location.startsWith(AppRoutes.homePath)) return 0;
    if (location.startsWith(AppRoutes.blogListPath)) return 1;
    if (location.startsWith(AppRoutes.nearbyClinicsMapPath)) return 2;
    if (location.startsWith(AppRoutes.userProfilePath)) return 3; // Nueva pestaña de Usuario
    return 0; // Por defecto a Inicio
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed(AppRoutes.home);
        break;
      case 1:
        context.goNamed(AppRoutes.blogList);
        break;
      case 2:
        context.goNamed(AppRoutes.nearbyClinicsMap);
        break;
      case 3:
        context.goNamed(AppRoutes.userProfile); // Navegar a la nueva ruta de Usuario
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        type: BottomNavigationBarType.fixed, // Asegura que todos los items sean visibles
        items: const <BottomNavigationBarItem>[
          // Nuevos 4 items de la barra de navegación
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
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
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Usuario',
          ),
        ],
      ),
    );
  }
}