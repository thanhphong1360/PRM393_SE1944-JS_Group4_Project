
import 'package:flutter/material.dart';

import 'core/services/auth_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ConferenceApp());
}

class ConferenceApp extends StatelessWidget {
  const ConferenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conference Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}
