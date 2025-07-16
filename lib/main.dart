import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Screens/splash_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // 🔥 Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth & Firestore Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(),
    );
  }
}

class FirebaseHomePage extends StatefulWidget {
  @override
  State<FirebaseHomePage> createState() => _FirebaseHomePageState();
}

class _FirebaseHomePageState extends State<FirebaseHomePage> {
  User? _user;
  String _status = 'Not logged in';

  @override
  void initState() {
    super.initState();
    _signInAnonymously();
  }

  Future<void> _signInAnonymously() async {
    try {
      final result = await FirebaseAuth.instance.signInAnonymously();
      setState(() {
        _user = result.user;
        _status = 'Logged in as ${_user!.uid}';
      });

      // Write user info to Firestore
      await FirebaseFirestore.instance.collection('users').doc(_user!.uid).set({
        'uid': _user!.uid,
        'login_time': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _readUserData() async {
    if (_user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
    final data = doc.data();

    setState(() {
      _status = 'User document: ${data.toString()}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Test')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _readUserData,
              child: Text('Read Firestore Data'),
            ),
          ],
        ),
      ),
    );
  }
}
