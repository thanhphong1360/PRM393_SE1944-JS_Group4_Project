
import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../models/user.dart';
import '../../shared/screens/home_screen.dart';
import '../services/auth_service.dart';
import '../storage/token_storage.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<User?> _authFuture;

  @override
  void initState() {
    super.initState();
    _authFuture = _checkAuthentication();
  }

  Future<User?> _checkAuthentication() async {
    final hasToken = await TokenStorage.hasToken();

    if (!hasToken) {
      return null;
    }

    try {
      return await AuthService.getCurrentUser();
    } catch (e) {
      await AuthService.logout();
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _authFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          return HomeScreen(user: user);
        }

        return const LoginScreen();
      },
    );
  }
}
