import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'Screens/splash_screen.dart';
import 'Screens/login_screen.dart';
import 'Screens/signup_screen.dart';
import 'Screens/home_screen.dart';
import 'Screens/new_report_screen.dart';
import 'Screens/report_detail_screen.dart'; // Added import
import 'services/auth_service.dart';
import 'services/report_service.dart';
import 'viewmodels/report_viewmodel.dart';
import 'models/user_model.dart';
import 'models/report_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        ProxyProvider<AuthService, AppUser?>(
          update: (_, authService, __) => authService.currentAppUser,
        ),
        ChangeNotifierProvider(
          create: (_) => ReportViewModel(ReportService()),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/new_report',
        builder: (context, state) => const NewReportScreen(),
      ),
      GoRoute(
        path: '/report/:reportId',
        builder: (context, state) {
          final report = state.extra as Report; // Pass report via extra
          return ReportDetailScreen(report: report);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}