// lib/core/navigation/app_router.dart
import 'dart:async';
import 'package:dental_ai_app/core/models/blog_post_model.dart';
import 'package:dental_ai_app/core/providers/user_data_provider.dart'; 
import 'package:dental_ai_app/core/services/auth_service.dart';
import 'package:dental_ai_app/features/auth/screens/login_screen.dart';
import 'package:dental_ai_app/features/auth/screens/register_screen.dart';
import 'package:dental_ai_app/features/auth/screens/user_details_screen.dart';
import 'package:dental_ai_app/features/blog/screens/blog_detail_screen.dart';
import 'package:dental_ai_app/features/blog/screens/blog_list_screen.dart';
import 'package:dental_ai_app/features/diagnosis/screens/diagnosis_form_screen.dart';
import 'package:dental_ai_app/features/diagnosis/screens/diagnosis_result_screen.dart';
import 'package:dental_ai_app/features/diagnosis/screens/image_capture_guide_screen.dart';
import 'package:dental_ai_app/features/home/screens/home_screen.dart';
import 'package:dental_ai_app/features/map/screens/nearby_clinics_map_screen.dart';
import 'package:dental_ai_app/features/user_profile/screens/UserProfileScreen.dart'; // Nueva pantalla principal
import 'package:dental_ai_app/widgets/bottom_nav_bar.dart';
import 'package:dental_ai_app/widgets/loading_spinner.dart'; 
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dental_ai_app/core/models/user_model.dart'; 

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authStateChangesValue = ref.watch(authStateChangesProvider);
  final userProfileState = ref.watch(userProfileNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splashPath,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(ref.watch(authStateChangesProvider.stream)), 
    redirect: (BuildContext context, GoRouterState state) {
      final bool isLoggedIn = authStateChangesValue.value != null;
      final String currentLocation = state.matchedLocation;
       if (currentLocation == AppRoutes.splashPath) {
        if (authStateChangesValue is AsyncLoading) return null; 
        if (!isLoggedIn) return AppRoutes.loginPath;
        if (userProfileState is AsyncLoading) return null; 
        final UserModel? profile = userProfileState.asData?.value;
        if (profile == null || profile.name == null || profile.name!.isEmpty || !profile.termsAccepted) {
          return AppRoutes.userDetailsPath;
        }
        return AppRoutes.homePath;
      }
      final bool onAuthRoute = currentLocation == AppRoutes.loginPath || currentLocation == AppRoutes.registerPath;
      if (!isLoggedIn && !onAuthRoute) return AppRoutes.loginPath;
      if (isLoggedIn && onAuthRoute) {
        if (userProfileState is AsyncLoading) return null; 
        final UserModel? profile = userProfileState.asData?.value;
        if (profile == null || profile.name == null || profile.name!.isEmpty || !profile.termsAccepted) {
          return AppRoutes.userDetailsPath;
        }
        return AppRoutes.homePath;
      }
      if (isLoggedIn && currentLocation == AppRoutes.userDetailsPath) {
        if (userProfileState is AsyncLoading) return null; 
        final UserModel? profile = userProfileState.asData?.value;
        if (profile != null && profile.name != null && profile.name!.isNotEmpty && profile.termsAccepted) {
          return AppRoutes.homePath;
        }
      }
      if (isLoggedIn && 
          currentLocation != AppRoutes.userDetailsPath && 
          !onAuthRoute && 
          currentLocation != AppRoutes.splashPath) {
        if (userProfileState is! AsyncLoading) {
            final UserModel? profile = userProfileState.asData?.value;
            if (profile == null || profile.name == null || profile.name!.isEmpty || !profile.termsAccepted) {
                return AppRoutes.userDetailsPath;
            }
        }
      }
      return null;
    },

    routes: <RouteBase>[
      GoRoute(path: AppRoutes.splashPath, name: AppRoutes.splash, builder: (context, state) => const Scaffold(body: LoadingSpinner(message: "Cargando..."))),
      GoRoute(path: AppRoutes.loginPath, name: AppRoutes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: AppRoutes.registerPath, name: AppRoutes.register, builder: (context, state) => const RegisterScreen()),
      GoRoute(path: AppRoutes.userDetailsPath, name: AppRoutes.userDetails, builder: (context, state) => const UserDetailsScreen()),

      ShellRoute(
        builder: (context, state, child) {
          return BottomNavBarScaffold(child: child);
        },
        routes: <RouteBase>[
          // Pestaña 1: Inicio
          GoRoute(
            path: AppRoutes.homePath,
            name: AppRoutes.home,
            pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
            routes: [
              GoRoute( path: AppRoutes.diagnosisFormPath, name: AppRoutes.diagnosisForm, parentNavigatorKey: _rootNavigatorKey, builder: (context, state) => const DiagnosisFormScreen()),
              GoRoute( path: AppRoutes.imageCaptureGuidePath, name: AppRoutes.imageCaptureGuide, parentNavigatorKey: _rootNavigatorKey, builder: (context, state) => const ImageCaptureGuideScreen()),
              GoRoute( path: '${AppRoutes.diagnosisResultPath}/:reportId', name: AppRoutes.diagnosisResult, parentNavigatorKey: _rootNavigatorKey, builder: (context, state) => DiagnosisResultScreen(reportId: state.pathParameters['reportId']!)),
            ]
          ),
          
          // Pestaña 2: Blog
          GoRoute(
            path: AppRoutes.blogListPath,
            name: AppRoutes.blogList,
            pageBuilder: (context, state) => const NoTransitionPage(child: BlogListScreen()),
            routes: [
              GoRoute(
                path: '${AppRoutes.blogDetailPath}/:postId',
                name: AppRoutes.blogDetail,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final postId = state.pathParameters['postId']!;
                  final post = state.extra as BlogPostModel?;
                  return BlogDetailScreen(postId: postId, post: post);
                },
              ),
            ]
          ),
          
          // Pestaña 3: Mapa
          GoRoute(
            path: AppRoutes.nearbyClinicsMapPath,
            name: AppRoutes.nearbyClinicsMap,
            pageBuilder: (context, state) => const NoTransitionPage(child: NearbyClinicsMapScreen()),
          ),
          
          // Pestaña 4: NUEVA RUTA DE USUARIO
          GoRoute(
            path: AppRoutes.userProfilePath,
            name: AppRoutes.userProfile,
            pageBuilder: (context, state) => const NoTransitionPage(child: UserProfileScreen()),
            routes: [
               GoRoute(
                // La ruta para ver el detalle de un diagnóstico desde el historial
                path: '${AppRoutes.diagnosisDetailPath}/:reportId',
                name: AppRoutes.diagnosisDetail,
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) {
                  final reportId = state.pathParameters['reportId']!;
                  return DiagnosisResultScreen(reportId: reportId, isFromHistory: true);
                },
              ),
            ]
          ),
        ],
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) { _subscription = stream.listen((_) { notifyListeners(); }); }
  @override
  void dispose() { _subscription.cancel(); super.dispose(); }
}

// Clase AppRoutes actualizada
class AppRoutes {
  static const String splash = 'splash';
  static const String splashPath = '/splash';
  static const String login = 'login';
  static const String loginPath = '/login';
  static const String register = 'register';
  static const String registerPath = '/register';
  static const String userDetails = 'userDetails';
  static const String userDetailsPath = '/user-details';
  static const String home = 'home';
  static const String homePath = '/home';
  static const String diagnosisForm = 'diagnosisForm';
  static const String diagnosisFormPath = 'diagnosis-form';
  static const String imageCaptureGuide = 'imageCaptureGuide';
  static const String imageCaptureGuidePath = 'image-capture';
  static const String diagnosisResult = 'diagnosisResult';
  static const String diagnosisResultPath = 'diagnosis-result';
  static const String blogList = 'blogList';
  static const String blogListPath = '/blog';
  static const String blogDetail = 'blogDetail';
  static const String blogDetailPath = 'post';
  static const String nearbyClinicsMap = 'nearbyClinicsMap';
  static const String nearbyClinicsMapPath = '/map';

  // Nuevas y eliminadas rutas
  static const String userProfile = 'userProfile';
  static const String userProfilePath = '/profile'; // Nueva ruta para la pestaña de Usuario
  
  static const String diagnosisDetail = 'diagnosisDetail';
  static const String diagnosisDetailPath = 'history-detail'; // Nueva ruta anidada para /profile
}
