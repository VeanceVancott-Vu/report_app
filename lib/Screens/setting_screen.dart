import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../services/auth_service.dart'; // Adjust path to your AuthService

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
  int _currentIndex = 3; // Settings tab (Admin at index 2)
  bool _notificationsEnabled = true; // Placeholder state for display
  bool _darkModeEnabled = false; // Placeholder state for display
  final AuthService _authService = AuthService();

  void _onNavTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    logger.d('Bottom navigation tapped: index $index');
    switch (index) {
      case 0:
        context.push('/login'); // Navigate to LoginScreen
        break;
      case 1:
        context.push('/map'); // Navigate to MapScreen
        break;
      case 2:
        context.push('/admin'); // Navigate to AdminScreen
        break;
      case 3:
        // Already on SettingsScreen, no navigation needed
        break;
    }
  }

  void _handleLogout(BuildContext context) async {
    try {
      await _authService.logOut();
      if (mounted) {
        context.go('/login'); // Navigate to LoginScreen after logout
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            logger.d('Back button pressed on SettingsScreen');
            context.go('/login'); // Navigate to LoginScreen
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preferences',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'Enable Notifications',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                          logger.d('Notifications toggled: $value');
                        },
                        activeColor: Colors.blue.shade700,
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text(
                          'Dark Mode',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        value: _darkModeEnabled,
                        onChanged: (value) {
                          setState(() {
                            _darkModeEnabled = value;
                          });
                          logger.d('Dark mode toggled: $value');
                        },
                        activeColor: Colors.blue.shade700,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  title: const Text(
                    'Manage Account',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    logger.d('Manage Account tapped');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account settings not implemented')),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Log Out',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  onTap: () {
                    logger.d('Log Out tapped');
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Log Out'),
                        content: const Text('Are you sure you want to log out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _handleLogout(context);
                            },
                            child: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 28,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey.shade700,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.report), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: "Map"),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}