import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/auth_strings.dart';
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
  AppLanguage _language = AppLanguage.english;
  bool _showSignupPassword = false;
  bool _showConfirmPassword = false;
  bool _showLoginPassword = false;
  bool _busy = false;

  AuthStrings get _strings => AuthStrings(_language);

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

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
    return Directionality(
      textDirection: _language.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
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
                          Expanded(child: _AuthStory(strings: _strings)),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(child: _languagePicker()),
                                    const SizedBox(width: 16),
                                    const BrandMark(compact: true),
                                  ],
                                ),
                                const SizedBox(height: 34),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 260),
                                  switchInCurve: Curves.easeOutCubic,
                                  child: _signup ? _signupForm() : _loginForm(),
                                ),
                                const SizedBox(height: 20),
                                _LegalLinks(
                                  notice: _strings.get('legalNotice'),
                                  termsLabel: _strings.get('terms'),
                                  privacyLabel: _strings.get('privacy'),
                                  onTerms: () => _openLegalPage(
                                    _termsUrl,
                                    _strings.get('terms'),
                                  ),
                                  onPrivacy: () => _openLegalPage(
                                    _privacyUrl,
                                    _strings.get('privacy'),
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
      ),
    );
  }

  Widget _languagePicker() => SizedBox(
    width: 170,
    child: DropdownButtonHideUnderline(
      child: DropdownButton<AppLanguage>(
        value: _language,
        isExpanded: true,
        borderRadius: BorderRadius.circular(16),
        icon: const Icon(Icons.language_rounded),
        items: AppLanguage.values
            .map(
              (language) => DropdownMenuItem(
                value: language,
                child: Text(language.label, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: _busy
            ? null
            : (language) {
                if (language != null) _setLanguage(language);
              },
      ),
    ),
  );

  Widget _loginForm() => Form(
    key: const ValueKey('login-form'),
    child: Form(
      key: _loginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _strings.get('signIn'),
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 10),
          Text(
            _strings.get('loginHelp'),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _loginIdentifier,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: InputDecoration(
              labelText: _strings.get('identifier'),
              hintText: _strings.get('identifierHint'),
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            validator: _validateLoginIdentifier,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPassword,
            obscureText: !_showLoginPassword,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: _strings.get('password'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _showLoginPassword = !_showLoginPassword),
                icon: Icon(
                  _showLoginPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                tooltip: _showLoginPassword
                    ? _strings.get('hidePassword')
                    : _strings.get('showPassword'),
              ),
            ),
            validator: (value) => value == null || value.isEmpty
                ? _strings.get('passwordRequired')
                : null,
            onFieldSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: _busy ? _strings.get('signingIn') : _strings.get('signIn'),
            icon: Icons.arrow_forward_rounded,
            onPressed: _busy ? null : _login,
          ),
          const SizedBox(height: 18),
          _SwitchPrompt(
            prefix: _strings.get('studentApplicant'),
            action: _strings.get('createAccount'),
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
          _strings.get('createStudentAccount'),
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: 10),
        Text(
          _strings.get('signupHelp'),
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        FormGrid(
          children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              decoration: InputDecoration(
                labelText: _strings.get('fullName'),
                hintText: _strings.get('nameHint'),
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return _strings.get('completeName');
                }
                if (value.trim().length < 3) {
                  return _strings.get('completeName');
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
              decoration: InputDecoration(
                labelText: _strings.get('cnic'),
                hintText: _strings.get('cnicHint'),
                prefixIcon: const Icon(Icons.badge_outlined),
                counterText: '',
              ),
              maxLength: 13,
              validator: (value) => validateCnic(value) == null
                  ? null
                  : _strings.get('cnicInvalid'),
            ),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [
                DigitsOnlyFormatter(),
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                labelText: _strings.get('phone'),
                hintText: '3311234567',
                prefixText: '+92  ',
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              validator: (value) => validatePakPhone(value) == null
                  ? null
                  : _strings.get('phoneInvalid'),
            ),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                labelText: _strings.get('email'),
                hintText: 'you@example.com',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (value) => validateEmail(value) == null
                  ? null
                  : _strings.get('emailInvalid'),
            ),
            TextFormField(
              controller: _password,
              obscureText: !_showSignupPassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: _strings.get('password'),
                helperText: _strings.get('passwordHelp'),
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
                      ? _strings.get('hidePassword')
                      : _strings.get('showPassword'),
                ),
              ),
              validator: (value) => validatePassword(value) == null
                  ? null
                  : _strings.get('passwordInvalid'),
            ),
            TextFormField(
              controller: _confirmPassword,
              obscureText: !_showConfirmPassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: _strings.get('confirmPassword'),
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
                      ? _strings.get('hidePassword')
                      : _strings.get('showPassword'),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return _strings.get('confirmRequired');
                }
                if (value != _password.text) {
                  return _strings.get('passwordsMismatch');
                }
                return null;
              },
            ),
          ],
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: _busy
              ? _strings.get('creatingAccount')
              : _strings.get('createAccount'),
          icon: Icons.check_rounded,
          onPressed: _busy ? null : _register,
        ),
        const SizedBox(height: 18),
        _SwitchPrompt(
          prefix: _strings.get('alreadyRegistered'),
          action: _strings.get('signIn'),
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
    final identifier = _loginIdentifier.text.trim();
    final isEmail = identifier.contains('@');
    setState(() => _busy = true);
    try {
      final session = await widget.api.login(
        cnic: isEmail ? null : identifier,
        email: isEmail ? identifier : null,
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
      if (!opened) {
        _showError(_strings.get('openFailed').replaceFirst('{page}', label));
      }
    } catch (_) {
      _showError(_strings.get('openFailed').replaceFirst('{page}', label));
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
      '${_strings.get('connectionFailed')}${details.isEmpty ? '' : ' $details'}',
    );
  }

  String? _validateLoginIdentifier(String? value) {
    final identifier = value?.trim() ?? '';
    if (identifier.isEmpty) return _strings.get('identifierRequired');
    final valid = identifier.contains('@')
        ? validateEmail(identifier) == null
        : validateCnic(identifier) == null;
    return valid ? null : _strings.get('identifierInvalid');
  }

  Future<void> _loadLanguage() async {
    final preferences = await SharedPreferences.getInstance();
    final code = preferences.getString('app_language');
    if (!mounted || code == null) return;
    final language = AppLanguage.values.where((item) => item.code == code);
    if (language.isNotEmpty) setState(() => _language = language.first);
  }

  Future<void> _setLanguage(AppLanguage language) async {
    setState(() => _language = language);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('app_language', language.code);
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks({
    required this.notice,
    required this.termsLabel,
    required this.privacyLabel,
    required this.onTerms,
    required this.onPrivacy,
  });

  final String notice;
  final String termsLabel;
  final String privacyLabel;
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
        Text(
          notice,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            TextButton(
              onPressed: onTerms,
              style: linkStyle,
              child: Text(termsLabel),
            ),
            TextButton(
              onPressed: onPrivacy,
              style: linkStyle,
              child: Text(privacyLabel),
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
  const _AuthStory({required this.strings});

  final AuthStrings strings;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 580),
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(
      color: AppColors.deepBlue,
      borderRadius: BorderRadius.circular(32),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.school_rounded, color: Colors.white, size: 42),
        const SizedBox(height: 150),
        Text(
          strings.get('storyTitle'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            height: 1.16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          strings.get('storyBody'),
          style: const TextStyle(
            color: Color(0xFFC1D9D1),
            fontSize: 16,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 34),
        _TrustLine(
          icon: Icons.verified_user_outlined,
          text: strings.get('secureSession'),
        ),
        const SizedBox(height: 14),
        _TrustLine(
          icon: Icons.assignment_turned_in_outlined,
          text: strings.get('liveStatus'),
        ),
        const SizedBox(height: 14),
        _TrustLine(
          icon: Icons.admin_panel_settings_outlined,
          text: strings.get('rolePortals'),
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
