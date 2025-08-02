import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:report_app/Screens/edit_profile_screen.dart';
import 'package:report_app/Screens/profile_screen.dart';
import 'Screens/splash_screen.dart';
import 'Screens/login_screen.dart';
import 'Screens/signup_screen.dart';
import 'Screens/home_screen.dart';
import 'Screens/new_report_screen.dart';
import 'Screens/report_detail_screen.dart';
import 'Screens/admin_home_screen.dart';
import 'Screens/admin_report_detail_screen.dart';
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
        redirect: (context, state) {
          final user = context.read<AppUser?>();
          logger.d(user);
          if (user == null) {return '/login';}
          else{
              if(user.role =="admin")
              {
                return'/admin';
              }
              else
              { return '/home';}
          }
        },
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
        path: '/admin',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/new_report',
        builder: (context, state) => const NewReportScreen(),
      ),
      GoRoute(
        path: '/report/:reportId',
        builder: (context, state) {
          final report = state.extra as Report;
          return ReportDetailScreen(report: report);
        },
      ),
          GoRoute(
        path: '/profile',
        builder: (context, state) {
          return ProfileScreen();
        },
      ),
          GoRoute(
        path: '/edit_profile',
        builder: (context, state) {
          return EditProfileScreen();
        },
      ),
      GoRoute(
        path: '/admin/report/:reportId',
        builder: (context, state) {
          final report = state.extra as Report;
          return AdminReportDetailScreen(report: report);
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

