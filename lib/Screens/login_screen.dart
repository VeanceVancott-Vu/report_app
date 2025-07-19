import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '/utils/logger.dart';
import '/utils/request_permission.dart';
import '/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  Position? _position;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _requestLocationOnce();
  }

  Future<void> _requestLocationOnce() async {
    try {
      final pos = await requestLocationPermission();
      setState(() {
        _position = pos;
      });
    } catch (e) {
      logger.e('Location permission denied or error: $e');
      setState(() {
        _errorMessage = 'Location permission is required to log in.';
      });
    }
  }

  void _onLoginPressed() async {
    if (_position == null) {
      setState(() {
        _errorMessage = 'Location not available. Please grant permission.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.logIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        location: _position!, // safe to use after null check
      );

      if (mounted) context.go('/home');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSignUpPressed() {
    context.go('/signup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('assets/logo.png', width: 60, height: 60),
                  const SizedBox(width: 12),
                  const Text(
                    'Smart report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                'Login',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              const Text('Email', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Enter your email',
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Password', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              const SizedBox(height: 10),
              Center(
                child: InkWell(
                  onTap: _onSignUpPressed,
                  child: const Text(
                    'Have no account? Sign up',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onLoginPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        )
                      : const Text('Log in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
