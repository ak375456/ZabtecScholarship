import 'package:flutter/material.dart';

import 'models.dart';
import 'screens/auth_screen.dart';
import 'screens/portal_screen.dart';
import 'screens/staff_portal_screen.dart';
import 'services/api_client.dart';
import 'services/session_store.dart';
import 'theme.dart';
import 'widgets/common.dart';

class ScholarshipApp extends StatefulWidget {
  const ScholarshipApp({super.key});

  @override
  State<ScholarshipApp> createState() => _ScholarshipAppState();
}

class _ScholarshipAppState extends State<ScholarshipApp> {
  final _sessionStore = SessionStore();
  late final ApiClient _api;
  AuthSession? _session;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(onSessionChanged: _persistSession);
    _restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HEC scholarships',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandMark(compact: true),
              SizedBox(height: 22),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    final session = _session;
    if (session == null) {
      return AuthScreen(api: _api, onAuthenticated: _setSession);
    }

    if (session.user.isStudent) {
      return PortalScreen(api: _api, session: session, onLogout: _logout);
    }

    return StaffPortalScreen(api: _api, session: session, onLogout: _logout);
  }

  Future<void> _restoreSession() async {
    final saved = await _sessionStore.load();
    if (saved == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    _api.setSession(saved);
    try {
      await _api.fetchMe();
      if (mounted) {
        setState(() {
          _session = _api.session;
          _loading = false;
        });
      }
    } catch (_) {
      await _sessionStore.clear();
      _api.setSession(null);
      if (mounted) {
        setState(() {
          _session = null;
          _loading = false;
        });
      }
    }
  }

  Future<void> _setSession(AuthSession session) async {
    await _persistSession(session);
    if (mounted) setState(() => _session = session);
  }

  Future<void> _persistSession(AuthSession? session) async {
    if (session == null) {
      await _sessionStore.clear();
    } else {
      await _sessionStore.save(session);
    }
    if (mounted) setState(() => _session = session);
  }

  Future<void> _logout() async {
    await _api.logout();
    if (mounted) setState(() => _session = null);
  }
}
