import 'package:flutter/material.dart';

import 'data/demo_profile.dart';
import 'models.dart';
import 'screens/auth_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/portal_screen.dart';
import 'theme.dart';

class ScholarshipApp extends StatefulWidget {
  const ScholarshipApp({super.key});

  @override
  State<ScholarshipApp> createState() => _ScholarshipAppState();
}

class _ScholarshipAppState extends State<ScholarshipApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  Account? _account = DemoProfile.enabled ? DemoProfile.account : null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'ZABTEC Scholarship Pakistan',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: LandingScreen(onContinue: _openAuth),
    );
  }

  void _openAuth() {
    _navigatorKey.currentState!.push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        reverseTransitionDuration: const Duration(milliseconds: 360),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: AuthScreen(
            existingAccount: _account,
            onRegistered: (account) => setState(() => _account = account),
            onLogin: _openPortal,
          ),
        ),
      ),
    );
  }

  void _openPortal(Account account) {
    _navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => PortalScreen(account: account, onLogout: _goHome),
      ),
      (_) => false,
    );
  }

  void _goHome() {
    _navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LandingScreen(onContinue: _openAuth),
      ),
      (_) => false,
    );
  }
}
