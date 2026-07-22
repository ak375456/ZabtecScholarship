import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false, this.showHec = false});
  final bool compact;
  final bool showHec;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 48.0 : 72.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoTile(path: 'assets/zabtec-app-icon-1024.png', size: size),
        SizedBox(width: compact ? 10 : 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ZABTEC',
              style: TextStyle(
                color: AppColors.deepBlue,
                fontSize: compact ? 16 : 22,
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
              ),
            ),
            Text(
              'Scholarships',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: compact ? 10 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (showHec) ...[
          SizedBox(width: compact ? 10 : 14),
          Container(width: 1, height: size * .52, color: AppColors.border),
          SizedBox(width: compact ? 10 : 14),
          _LogoTile(path: 'assets/hec-logo.png', size: size),
        ],
      ],
    );
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile({required this.path, required this.size});
  final String path;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .08),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(size * .24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1800183B),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * .15),
      child: Image.asset(path, fit: BoxFit.contain),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: onPressed,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        if (icon != null) ...[const SizedBox(width: 10), Icon(icon, size: 20)],
      ],
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
  });
  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow.toUpperCase(),
        style: const TextStyle(
          color: AppColors.leafGreen,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
      const SizedBox(height: 8),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 8),
      Text(description, style: const TextStyle(color: AppColors.muted)),
    ],
  );
}

class FormCard extends StatelessWidget {
  const FormCard({super.key, required this.child, this.title, this.icon});
  final Widget child;
  final String? title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 480 ? 18 : 24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0900183B),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.pakistanGreen),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
        ],
        child,
      ],
    ),
  );
}

class FormGrid extends StatelessWidget {
  const FormGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 680 ? 2 : 1;
      const gap = 16.0;
      final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: 16,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
}

class DigitsOnlyFormatter extends FilteringTextInputFormatter {
  DigitsOnlyFormatter() : super.allow(RegExp(r'[0-9]'));
}

String? requiredText(String? value, String label) {
  if (value == null || value.trim().isEmpty) return '$label is required';
  return null;
}

String? validateCnic(String? value) {
  final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
  if (digits.length != 13) return 'Enter a valid 13-digit CNIC';
  return null;
}

String? validatePakPhone(String? value) {
  final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
  if (digits.length != 10 || !digits.startsWith('3')) {
    return 'Use 3XX XXXXXXX after +92';
  }
  return null;
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.length < 8) return 'Use at least 8 characters';
  if (!RegExp(r'[A-Z]').hasMatch(password) ||
      !RegExp(r'[a-z]').hasMatch(password) ||
      !RegExp(r'[0-9]').hasMatch(password)) {
    return 'Include upper, lower-case letters and a number';
  }
  return null;
}

Future<DateTime?> pickAppDate(BuildContext context, {DateTime? initial}) =>
    showDatePicker(
      context: context,
      initialDate: initial ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

String formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

DateTime? parseAppDate(String value) {
  final parts = value.split('/');
  if (parts.length != 3) return DateTime.tryParse(value);
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  return DateTime(year, month, day);
}

String formatBackendDate(Object? value) {
  final date = value is DateTime
      ? value
      : DateTime.tryParse(value?.toString() ?? '');
  return date == null ? '' : formatDate(date.toLocal());
}
