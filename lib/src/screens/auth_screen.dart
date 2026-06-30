import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/demo_profile.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.existingAccount,
    required this.onRegistered,
    required this.onLogin,
  });
  final Account? existingAccount;
  final ValueChanged<Account> onRegistered;
  final ValueChanged<Account> onLogin;

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
  final _loginCnic = TextEditingController();
  final _loginPassword = TextEditingController();
  Account? _localAccount;
  bool _signup = false;
  bool _showSignupPassword = false;
  bool _showConfirmPassword = false;
  bool _showLoginPassword = false;

  @override
  void initState() {
    super.initState();
    _localAccount =
        widget.existingAccount ??
        (DemoProfile.enabled ? DemoProfile.account : null);
    if (DemoProfile.enabled) _prefillDemoAuth();
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _cnic,
      _phone,
      _email,
      _password,
      _confirmPassword,
      _loginCnic,
      _loginPassword,
    ]) {
      c.dispose();
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
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.arrow_back_rounded),
                                    tooltip: 'Back',
                                  ),
                                  const Spacer(),
                                  const BrandMark(compact: true),
                                ],
                              ),
                              const SizedBox(height: 30),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 320),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween(
                                          begin: const Offset(.04, 0),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    ),
                                child: _signup ? _signupForm() : _loginForm(),
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
    key: const ValueKey('login'),
    child: Form(
      key: _loginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Welcome back', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 10),
          const Text(
            'Sign in securely with your CNIC and password.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: _loginCnic,
            keyboardType: TextInputType.number,
            inputFormatters: [
              DigitsOnlyFormatter(),
              LengthLimitingTextInputFormatter(13),
            ],
            decoration: const InputDecoration(
              labelText: 'CNIC',
              hintText: '3520212345671',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            validator: validateCnic,
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
            validator: (v) => requiredText(v, 'Password'),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Sign in',
            icon: Icons.arrow_forward_rounded,
            onPressed: _login,
          ),
          const SizedBox(height: 18),
          _SwitchPrompt(
            prefix: 'New to the scholarship portal?',
            action: 'Create account',
            onTap: () => setState(() => _signup = true),
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
          'Create your account',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 10),
        const Text(
          'Use information exactly as it appears on your CNIC.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 26),
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
              validator: (v) {
                final required = requiredText(v, 'Full name');
                if (required != null) return required;
                if (v!.trim().split(RegExp(r'\s+')).length < 2) {
                  return 'Enter your complete name';
                }
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
                helperText: '3-digit network + 7-digit number',
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
              validator: (v) {
                if (v != _password.text) return 'Passwords do not match';
                return requiredText(v, 'Password confirmation');
              },
            ),
          ],
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: 'Create account',
          icon: Icons.check_rounded,
          onPressed: _register,
        ),
        const SizedBox(height: 18),
        _SwitchPrompt(
          prefix: 'Already registered?',
          action: 'Sign in',
          onTap: () => setState(() => _signup = false),
        ),
      ],
    ),
  );

  void _register() {
    if (!_signupKey.currentState!.validate()) return;
    final account = Account(
      fullName: _name.text.trim(),
      cnic: _cnic.text,
      phone: '+92${_phone.text}',
      email: _email.text.trim(),
      password: _password.text,
    );
    widget.onRegistered(account);
    _localAccount = account;
    _loginCnic.text = account.cnic;
    setState(() => _signup = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created. Sign in to continue.')),
    );
  }

  void _login() {
    if (!_loginKey.currentState!.validate()) return;
    final account = _localAccount;
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No account found. Please create an account first.'),
        ),
      );
      return;
    }
    if (_loginCnic.text != account.cnic ||
        _loginPassword.text != account.password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CNIC or password does not match.')),
      );
      return;
    }
    widget.onLogin(account);
  }

  void _prefillDemoAuth() {
    final account = _localAccount ?? DemoProfile.account;
    _name.text = account.fullName;
    _cnic.text = account.cnic;
    _phone.text = DemoProfile.signupPhoneDigits;
    _email.text = account.email;
    _password.text = account.password;
    _confirmPassword.text = account.password;
    _loginCnic.text = account.cnic;
    _loginPassword.text = account.password;
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
  final VoidCallback onTap;

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
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.pakistanGreen,
          Color(0xFF052D3B),
          AppColors.deepBlue,
        ],
      ),
      borderRadius: BorderRadius.circular(32),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.school_rounded, color: Colors.white, size: 42),
        SizedBox(height: 150),
        Text(
          'Opportunity should meet talent wherever it lives.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            height: 1.16,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
        SizedBox(height: 18),
        Text(
          'Create your profile once, complete it in clear steps, and always know what remains.',
          style: TextStyle(
            color: Color(0xFFC1D9D1),
            fontSize: 16,
            height: 1.55,
          ),
        ),
        SizedBox(height: 34),
        _TrustLine(
          icon: Icons.verified_user_outlined,
          text: 'CNIC-based applicant profile',
        ),
        SizedBox(height: 14),
        _TrustLine(
          icon: Icons.track_changes_outlined,
          text: 'Visible application progress',
        ),
        SizedBox(height: 14),
        _TrustLine(
          icon: Icons.devices_outlined,
          text: 'Works across phone, tablet and web',
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
