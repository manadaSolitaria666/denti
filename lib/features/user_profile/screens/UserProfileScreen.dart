// lib/features/user_profile/screens/user_profile_screen.dart
import 'package:dental_ai_app/core/providers/auth_provider.dart';
import 'package:dental_ai_app/core/providers/user_data_provider.dart';
import 'package:dental_ai_app/features/diagnosis_history/screens/diagnosis_history_screen.dart';
import 'package:dental_ai_app/features/settings_reminders/screens/reminders_settings_screen.dart';
import 'package:dental_ai_app/features/user_profile/screens/EditProfileScreen.dart'; // Nueva pantalla
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileNotifierProvider);
    final user = userProfileAsync.asData?.value;

    return DefaultTabController(
      length: 3, // Tres pestañas: Historial, Mi Perfil, Notificaciones
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // No queremos botón de atrás
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mi Perfil',
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),
              if (user != null)
                Text(
                  user.email ?? 'Cargando...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                // Lógica de cierre de sesión
                await ref.read(authNotifierProvider.notifier).signOut();
                // GoRouter se encargará de redirigir a Login
              },
              tooltip: 'Cerrar Sesión',
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.history_outlined), text: 'Historial'),
              Tab(icon: Icon(Icons.person_outline), text: 'Mis Datos'),
              Tab(icon: Icon(Icons.notifications_outlined), text: 'Ajustes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Contenido de la primera pestaña: Historial de Diagnósticos
            DiagnosisHistoryScreen(),
            
            // Contenido de la segunda pestaña: Editar Perfil
            EditProfileScreen(),

            // Contenido de la tercera pestaña: Ajustes y Recordatorios
            RemindersSettingsScreen(),
          ],
        ),
      ),
    );
  }
}
