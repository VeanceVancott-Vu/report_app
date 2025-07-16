import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //App logo
            Image.asset(
              'assets/logo.png', 
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            //App title
            const Text(
              'Smart report',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                fontFamily: 'Serif', // Optional: customize font
              ),
            ),
          ],
        ),
      ),
    );
  }
}
