import 'package:flutter/material.dart';
import 'package:healherr/authentication/login_pages/login_widget.dart';
import 'package:healherr/authentication/services/auth_session_service.dart';
import 'package:healherr/home/home_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<AuthSession?> _loadSession() {
    return AuthSessionService().getSession();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Healher App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFE91E63)),
        useMaterial3: true,
      ),
      home: FutureBuilder<AuthSession?>(
        future: _loadSession(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data;
          if (session != null) {
            return HomeWidget(
              userId: session.userId,
              fullName: session.fullName,
            );
          }

          return LoginWidget();
        },
      ),
    );
  }
}
