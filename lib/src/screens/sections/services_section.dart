import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/demo_profile.dart';
import '../../models.dart';
import '../../services/receipt_pdf_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ServicesSection extends StatefulWidget {
  const ServicesSection({
    super.key,
    required this.account,
    required this.progress,
    required this.receipt,
    required this.onPaymentCompleted,
    required this.onOpenSection,
  });

  final Account account;
  final ApplicationProgress progress;
  final ActivationReceipt? receipt;
  final ValueChanged<ActivationReceipt> onPaymentCompleted;
  final ValueChanged<int> onOpenSection;

  @override
  State<ServicesSection> createState() => _ServicesSectionState();
}

class _ServicesSectionState extends State<ServicesSection>
    with AutomaticKeepAliveClientMixin {
  final _paymentKey = GlobalKey<FormState>();
  late final TextEditingController _cardHolder;
  final _cardNumber = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  bool _savingPdf = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cardHolder = TextEditingController(text: widget.account.fullName);
    if (DemoProfile.enabled) {
      _cardNumber.text = DemoProfile.cardNumber;
      _expiry.text = DemoProfile.cardExpiry;
      _cvv.text = DemoProfile.cardCvv;
    }
  }

  @override
  void dispose() {
    _cardHolder.dispose();
    _cardNumber.dispose();
    _expiry.dispose();
    _cvv.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 520 ? 18 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                eyebrow: 'Activation',
                title: 'Services',
                description:
                    'Services unlock after profile completion and the PKR 1,500 activation payment.',
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _contentForState(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contentForState() {
    if (!widget.progress.coreProfileComplete) {
      return _LockedServicesCard(
        key: const ValueKey('services-locked'),
        missing: widget.progress.missingForServices,
        onOpenSection: _openMissingSection,
      );
    }

    if (!widget.progress.servicePaymentComplete || widget.receipt == null) {
      return _PaymentCard(
        key: const ValueKey('services-payment'),
        formKey: _paymentKey,
        cardHolder: _cardHolder,
        cardNumber: _cardNumber,
        expiry: _expiry,
        cvv: _cvv,
        onPay: _payActivationFee,
      );
    }

    return _UnlockedServicesCard(
      key: const ValueKey('services-unlocked'),
      receipt: widget.receipt!,
      savingPdf: _savingPdf,
      onSavePdf: _saveReceiptPdf,
    );
  }

  void _openMissingSection(String section) {
    final index = switch (section) {
      'Profile' => 1,
      'Family' => 2,
      'Education' => 3,
      'Documents' => 6,
      _ => 0,
    };
    widget.onOpenSection(index);
  }

  void _payActivationFee() {
    if (!_paymentKey.currentState!.validate()) return;
    final digits = _cardNumber.text.replaceAll(RegExp(r'\D'), '');
    final now = DateTime.now();
    final receipt = ActivationReceipt(
      receiptNumber: 'ZAB-${now.millisecondsSinceEpoch}',
      account: widget.account,
      issuedAt: now,
      amountPkr: ReceiptPdfService.activationFeePkr,
      paymentMethod: 'Card payment',
      cardLast4: digits.substring(digits.length - 4),
    );
    widget.onPaymentCompleted(receipt);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Payment recorded. Profile is active and services are unlocked.',
        ),
      ),
    );
  }

  Future<void> _saveReceiptPdf() async {
    final receipt = widget.receipt;
    if (receipt == null || _savingPdf) return;
    setState(() => _savingPdf = true);
    try {
      final File file = await ReceiptPdfService.saveActivationReceipt(receipt);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receipt PDF saved: ${file.path}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save receipt PDF: $error')),
      );
    } finally {
      if (mounted) setState(() => _savingPdf = false);
    }
  }
}

class _LockedServicesCard extends StatelessWidget {
  const _LockedServicesCard({
    super.key,
    required this.missing,
    required this.onOpenSection,
  });

  final List<String> missing;
  final ValueChanged<String> onOpenSection;

  @override
  Widget build(BuildContext context) => FormCard(
    title: 'Services locked for now',
    icon: Icons.lock_outline_rounded,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFE0A8)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFFA66200)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your profile and services will be available once you complete Profile, Family, Education and Documents, then pay the PKR 1,500 activation fee.',
                  style: TextStyle(color: AppColors.ink, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Complete these first',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: missing
              .map(
                (section) => ActionChip(
                  avatar: const Icon(Icons.radio_button_unchecked, size: 16),
                  label: Text(section),
                  onPressed: () => onOpenSection(section),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    super.key,
    required this.formKey,
    required this.cardHolder,
    required this.cardNumber,
    required this.expiry,
    required this.cvv,
    required this.onPay,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController cardHolder;
  final TextEditingController cardNumber;
  final TextEditingController expiry;
  final TextEditingController cvv;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) => FormCard(
    title: 'Profile activation payment',
    icon: Icons.credit_card_rounded,
    child: Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 480 ? 18 : 22,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.deepBlue, AppColors.pakistanGreen],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2201411C),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 560;
                final amount = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVATION FEE',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .7),
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'PKR 1,500',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your profile and services will be available once you pay this amount.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .78),
                        height: 1.45,
                      ),
                    ),
                  ],
                );
                final badge = Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .18),
                    ),
                  ),
                  child: const Text(
                    'Dummy card flow',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [amount, const SizedBox(height: 18), badge],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: amount),
                    const SizedBox(width: 18),
                    badge,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'A receipt/challan PDF will be generated after payment. This is a frontend placeholder until a real payment gateway is connected.',
            style: TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 20),
          FormGrid(
            children: [
              TextFormField(
                controller: cardHolder,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Cardholder name'),
                validator: (value) => requiredText(value, 'Cardholder name'),
              ),
              TextFormField(
                controller: cardNumber,
                decoration: const InputDecoration(
                  labelText: 'Card number',
                  hintText: '4242 4242 4242 4242',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  DigitsOnlyFormatter(),
                  LengthLimitingTextInputFormatter(16),
                ],
                validator: _validateCardNumber,
              ),
              TextFormField(
                controller: expiry,
                decoration: const InputDecoration(
                  labelText: 'Expiry',
                  hintText: 'MM/YY',
                ),
                keyboardType: TextInputType.datetime,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                  LengthLimitingTextInputFormatter(5),
                ],
                validator: _validateExpiry,
              ),
              TextFormField(
                controller: cvv,
                decoration: const InputDecoration(
                  labelText: 'CVV',
                  hintText: '123',
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                inputFormatters: [
                  DigitsOnlyFormatter(),
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: _validateCvv,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width < 520
                  ? double.infinity
                  : 260,
              child: PrimaryButton(
                label: 'Pay PKR 1,500',
                icon: Icons.lock_open_rounded,
                onPressed: onPay,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  String? _validateCardNumber(String? value) {
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.length != 16) return 'Enter a 16-digit card number';
    return null;
  }

  String? _validateExpiry(String? value) {
    final expiryText = value?.trim() ?? '';
    if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(expiryText)) {
      return 'Use MM/YY';
    }
    return null;
  }

  String? _validateCvv(String? value) {
    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.length < 3 || digits.length > 4) return 'Enter 3 or 4 digits';
    return null;
  }
}

class _UnlockedServicesCard extends StatelessWidget {
  const _UnlockedServicesCard({
    super.key,
    required this.receipt,
    required this.savingPdf,
    required this.onSavePdf,
  });

  final ActivationReceipt receipt;
  final bool savingPdf;
  final VoidCallback onSavePdf;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FormCard(
        title: 'Profile active',
        icon: Icons.verified_user_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBE8DA)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.pakistanGreen,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Payment received. Your profile is active and services are now available.',
                      style: TextStyle(color: AppColors.ink, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _ReceiptSummary(receipt: receipt),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: MediaQuery.sizeOf(context).width < 520
                    ? double.infinity
                    : 250,
                child: OutlinedButton.icon(
                  onPressed: savingPdf ? null : onSavePdf,
                  icon: savingPdf
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(savingPdf ? 'Saving PDF...' : 'Save receipt PDF'),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      FormCard(
        title: 'Available services',
        icon: Icons.apps_rounded,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 650;
            final cards = [
              const _ServiceTile(
                icon: Icons.assignment_turned_in_outlined,
                title: 'Scholarship application',
                description: 'Submit and maintain your active application.',
              ),
              const _ServiceTile(
                icon: Icons.receipt_long_outlined,
                title: 'Challan / receipt generation',
                description:
                    'Generate saved PDF receipts for activation records.',
              ),
              const _ServiceTile(
                icon: Icons.fact_check_outlined,
                title: 'Document review',
                description:
                    'See missing document alerts once backend review is added.',
              ),
              const _ServiceTile(
                icon: Icons.timeline_rounded,
                title: 'Application tracking',
                description: 'Track future scholarship status updates.',
              ),
            ];
            if (compact) {
              return Column(
                children: cards
                    .map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: card,
                      ),
                    )
                    .toList(),
              );
            }
            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: cards
                  .map(
                    (card) => SizedBox(
                      width: (constraints.maxWidth - 14) / 2,
                      child: card,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ),
    ],
  );
}

class _ReceiptSummary extends StatelessWidget {
  const _ReceiptSummary({required this.receipt});

  final ActivationReceipt receipt;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        _summaryRow('Receipt number', receipt.receiptNumber),
        _summaryRow('Amount', receipt.amountLabel),
        _summaryRow(
          'Payment method',
          '${receipt.paymentMethod} •••• ${receipt.cardLast4}',
        ),
        _summaryRow('Status', 'Profile active / services unlocked'),
      ],
    ),
  );

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.canvas,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FB),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.zaptecBlue),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
