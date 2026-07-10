import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/common.dart';

const _termsUrl = 'https://akbaruddin678.github.io/ZabtectTermCondition/';
const _privacyUrl = 'https://akbaruddin678.github.io/ZabtecprivacyPolicy/';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.api,
    required this.onAuthenticated,
  });

  final ApiClient api;
  final ValueChanged<AuthSession> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginKey = GlobalKey<FormState>();
  final _signupKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _cnic = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _loginIdentifier = TextEditingController();
  final _loginPassword = TextEditingController();
  bool _signup = false;
  bool _staffLogin = false;
  bool _showSignupPassword = false;
  bool _showConfirmPassword = false;
  bool _showLoginPassword = false;
  bool _busy = false;

  @override
  void dispose() {
    for (final controller in [
      _name,
      _cnic,
      _phone,
      _email,
      _password,
      _confirmPassword,
      _loginIdentifier,
      _loginPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth < 560 ? 20 : 40,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Row(
                    children: [
                      if (constraints.maxWidth >= 850) ...[
                        const Expanded(child: _AuthStory()),
                        const SizedBox(width: 56),
                      ],
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Align(
                                alignment: Alignment.centerRight,
                                child: BrandMark(compact: true),
                              ),
                              const SizedBox(height: 34),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                switchInCurve: Curves.easeOutCubic,
                                child: _signup ? _signupForm() : _loginForm(),
                              ),
                              const SizedBox(height: 20),
                              _LegalLinks(
                                onTerms: () => _openLegalPage(
                                  _termsUrl,
                                  'Terms & Conditions',
                                ),
                                onPrivacy: () => _openLegalPage(
                                  _privacyUrl,
                                  'Privacy Policy',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginForm() => Form(
    key: const ValueKey('login-form'),
    child: Form(
      key: _loginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sign in', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 10),
          const Text(
            'Students use CNIC. HEC and admin users use email.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.badge_outlined),
                label: Text('Student'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.admin_panel_settings_outlined),
                label: Text('HEC / Admin'),
              ),
            ],
            selected: {_staffLogin},
            onSelectionChanged: _busy
                ? null
                : (value) => setState(() {
                    _staffLogin = value.first;
                    _loginIdentifier.clear();
                  }),
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _loginIdentifier,
            keyboardType: _staffLogin
                ? TextInputType.emailAddress
                : TextInputType.number,
            autofillHints: _staffLogin
                ? const [AutofillHints.email]
                : const [AutofillHints.username],
            inputFormatters: _staffLogin
                ? null
                : [DigitsOnlyFormatter(), LengthLimitingTextInputFormatter(13)],
            decoration: InputDecoration(
              labelText: _staffLogin ? 'Email address' : 'CNIC',
              hintText: _staffLogin ? 'admin@zabtec.edu.pk' : '3520212345671',
              prefixIcon: Icon(
                _staffLogin ? Icons.email_outlined : Icons.badge_outlined,
              ),
              counterText: '',
            ),
            maxLength: _staffLogin ? null : 13,
            validator: _staffLogin ? validateEmail : validateCnic,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPassword,
            obscureText: !_showLoginPassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _showLoginPassword = !_showLoginPassword),
                icon: Icon(
                  _showLoginPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: _showLoginPassword ? 'Hide password' : 'Show password',
              ),
            ),
            validator: (value) => requiredText(value, 'Password'),
            onFieldSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: _busy ? 'Signing in...' : 'Sign in',
            icon: Icons.arrow_forward_rounded,
            onPressed: _busy ? null : _login,
          ),
          const SizedBox(height: 18),
          _SwitchPrompt(
            prefix: 'Student applicant?',
            action: 'Create account',
            onTap: _busy ? null : () => setState(() => _signup = true),
          ),
        ],
      ),
    ),
  );

  Widget _signupForm() => Form(
    key: _signupKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Create student account',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 10),
        const Text(
          'Admin and HEC accounts are created from the admin portal.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        FormGrid(
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Full name',
                hintText: 'Name as shown on CNIC',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (value) {
                final required = requiredText(value, 'Full name');
                if (required != null) return required;
                if (value!.trim().length < 3) return 'Enter your complete name';
                return null;
              },
            ),
            TextFormField(
              controller: _cnic,
              keyboardType: TextInputType.number,
              inputFormatters: [
                DigitsOnlyFormatter(),
                LengthLimitingTextInputFormatter(13),
              ],
              decoration: const InputDecoration(
                labelText: 'CNIC',
                hintText: '13 digits without dashes',
                prefixIcon: Icon(Icons.badge_outlined),
                counterText: '',
              ),
              maxLength: 13,
              validator: validateCnic,
            ),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                DigitsOnlyFormatter(),
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '3311234567',
                prefixText: '+92  ',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: validatePakPhone,
            ),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'you@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: validateEmail,
            ),
            TextFormField(
              controller: _password,
              obscureText: !_showSignupPassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                helperText: '8+ characters with upper, lower-case and number',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _showSignupPassword = !_showSignupPassword,
                  ),
                  icon: Icon(
                    _showSignupPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  tooltip: _showSignupPassword
                      ? 'Hide password'
                      : 'Show password',
                ),
              ),
              validator: validatePassword,
            ),
            TextFormField(
              controller: _confirmPassword,
              obscureText: !_showConfirmPassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: const Icon(Icons.lock_reset_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  tooltip: _showConfirmPassword
                      ? 'Hide password'
                      : 'Show password',
                ),
              ),
              validator: (value) {
                final required = requiredText(value, 'Password confirmation');
                if (required != null) return required;
                if (value != _password.text) return 'Passwords do not match';
                return null;
              },
            ),
          ],
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: _busy ? 'Creating account...' : 'Create account',
          icon: Icons.check_rounded,
          onPressed: _busy ? null : _register,
        ),
        const SizedBox(height: 18),
        _SwitchPrompt(
          prefix: 'Already registered?',
          action: 'Sign in',
          onTap: _busy ? null : () => setState(() => _signup = false),
        ),
      ],
    ),
  );

  Future<void> _register() async {
    if (!_signupKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final session = await widget.api.register(
        fullName: _name.text.trim(),
        cnic: _cnic.text,
        email: _email.text.trim(),
        phone: '+92${_phone.text}',
        password: _password.text,
      );
      widget.onAuthenticated(session);
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showConnectionError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _login() async {
    if (!_loginKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final session = await widget.api.login(
        cnic: _staffLogin ? null : _loginIdentifier.text.trim(),
        email: _staffLogin ? _loginIdentifier.text.trim() : null,
        password: _loginPassword.text,
      );
      widget.onAuthenticated(session);
    } on ApiException catch (error) {
      _showError(error.message);
    } catch (error) {
      _showConnectionError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openLegalPage(String url, String label) async {
    try {
      final opened = await launchUrl(Uri.parse(url));
      if (!opened) _showError('Could not open $label. Please try again.');
    } catch (_) {
      _showError('Could not open $label. Please try again.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 8)),
    );
  }

  void _showConnectionError(Object error) {
    final details = error.toString().trim();
    _showError(
      'Could not connect to the API at ${widget.api.baseUrl}. Please check your internet connection or ask support to confirm the live backend is available.${details.isEmpty ? '' : ' Details: $details'}',
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks({required this.onTerms, required this.onPrivacy});

  final VoidCallback onTerms;
  final VoidCallback onPrivacy;

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return Column(
      children: [
        const Text(
          'By continuing, you agree to our terms and acknowledge our privacy policy.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            TextButton(
              onPressed: onTerms,
              style: linkStyle,
              child: const Text('Terms & Conditions'),
            ),
            TextButton(
              onPressed: onPrivacy,
              style: linkStyle,
              child: const Text('Privacy Policy'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SwitchPrompt extends StatelessWidget {
  const _SwitchPrompt({
    required this.prefix,
    required this.action,
    required this.onTap,
  });
  final String prefix;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      Text('$prefix ', style: const TextStyle(color: AppColors.muted)),
      TextButton(onPressed: onTap, child: Text(action)),
    ],
  );
}

class _AuthStory extends StatelessWidget {
  const _AuthStory();

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 580),
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      color: AppColors.deepBlue,
      borderRadius: BorderRadius.circular(32),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.school_rounded, color: Colors.white, size: 42),
        SizedBox(height: 150),
        Text(
          'One secure portal for students, HEC reviewers, and admins.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            height: 1.16,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 18),
        Text(
          'Sign in securely, complete your application, upload documents, pay the activation fee, and track review decisions.',
          style: TextStyle(
            color: Color(0xFFC1D9D1),
            fontSize: 16,
            height: 1.55,
          ),
        ),
        SizedBox(height: 34),
        _TrustLine(
          icon: Icons.verified_user_outlined,
          text: 'JWT session with refresh tokens',
        ),
        SizedBox(height: 14),
        _TrustLine(
          icon: Icons.assignment_turned_in_outlined,
          text: 'Live application status',
        ),
        SizedBox(height: 14),
        _TrustLine(
          icon: Icons.admin_panel_settings_outlined,
          text: 'Role-based portals after login',
        ),
      ],
    ),
  );
}

class _TrustLine extends StatelessWidget {
  const _TrustLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: const Color(0xFF92DEB8), size: 21),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}
