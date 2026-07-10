import 'package:flutter/material.dart';
import '../../models.dart';
import '../../services/receipt_pdf_service.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ServicesSection extends StatefulWidget {
  const ServicesSection({
    super.key,
    required this.account,
    required this.application,
    required this.progress,
    required this.receipt,
    required this.onPaymentCompleted,
    required this.onPayActivation,
  });

  final Account account;
  final ScholarshipApplication? application;
  final ApplicationProgress progress;
  final ActivationReceipt? receipt;
  final ValueChanged<ActivationReceipt> onPaymentCompleted;
  final Future<ActivationReceipt> Function({String method}) onPayActivation;

  @override
  State<ServicesSection> createState() => _ServicesSectionState();
}

class _ServicesSectionState extends State<ServicesSection>
    with AutomaticKeepAliveClientMixin {
  bool _savingPdf = false;
  bool _paying = false;

  @override
  bool get wantKeepAlive => true;

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
                title: 'Registration fee challan',
                description:
                    'The PKR 1,500 registration fee challan becomes available after your full profile and required documents are complete.',
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: widget.receipt == null
                    ? widget.progress.paymentEligible
                          ? _PaymentCard(
                              key: const ValueKey('services-payment'),
                              paying: _paying,
                              onGenerate: _generateChallan,
                            )
                          : _PaymentLockedCard(
                              key: const ValueKey('payment-locked'),
                              missing: widget.progress.missingForPayment,
                            )
                    : _UnlockedServicesCard(
                        key: const ValueKey('services-unlocked'),
                        receipt: widget.receipt!,
                        application: widget.application,
                        progress: widget.progress,
                        savingPdf: _savingPdf,
                        onSavePdf: _saveReceiptPdf,
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generateChallan() async {
    setState(() => _paying = true);
    try {
      final receipt = await widget.onPayActivation(method: 'bank_transfer');
      widget.onPaymentCompleted(receipt);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bank challan generated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not generate challan: $error')),
      );
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _saveReceiptPdf() async {
    final receipt = widget.receipt;
    if (receipt == null || _savingPdf) return;
    setState(() => _savingPdf = true);
    try {
      final saved = await ReceiptPdfService.saveActivationReceipt(
        receipt,
        application: widget.application,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Challan PDF ${saved.label}')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save challan PDF: $error')),
      );
    } finally {
      if (mounted) setState(() => _savingPdf = false);
    }
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    super.key,
    required this.paying,
    required this.onGenerate,
  });

  final bool paying;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) => FormCard(
    title: 'Registration fee challan',
    icon: Icons.receipt_long_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 480 ? 18 : 22,
          ),
          decoration: BoxDecoration(
            color: AppColors.deepBlue,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2201411C),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REGISTRATION FEE',
                style: TextStyle(
                  color: Color(0xFFA6D8FF),
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'PKR 1,500',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Generate a bank challan and take it to Faysal Bank for deposit.',
                style: TextStyle(color: Color(0xFFCDE4F7), height: 1.45),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No card, Easypaisa, JazzCash, or bank-transfer details are required in the app.',
          style: TextStyle(color: AppColors.muted, height: 1.45),
        ),
        const SizedBox(height: 22),
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width < 520
                ? double.infinity
                : 280,
            child: PrimaryButton(
              label: paying ? 'Generating...' : 'Generate challan',
              icon: Icons.receipt_long_rounded,
              onPressed: paying ? null : onGenerate,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PaymentLockedCard extends StatelessWidget {
  const _PaymentLockedCard({super.key, required this.missing});

  final List<String> missing;

  @override
  Widget build(BuildContext context) => FormCard(
    title: 'Challan locked',
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
                  'Complete every required profile section and upload all required documents before generating the registration fee challan.',
                  style: TextStyle(color: AppColors.ink, height: 1.45),
                ),
              ),
            ],
          ),
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'Still required',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: missing
                .map(
                  (item) => Chip(
                    avatar: const Icon(Icons.radio_button_unchecked, size: 16),
                    label: Text(item),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    ),
  );
}

class _UnlockedServicesCard extends StatelessWidget {
  const _UnlockedServicesCard({
    super.key,
    required this.receipt,
    required this.application,
    required this.progress,
    required this.savingPdf,
    required this.onSavePdf,
  });

  final ActivationReceipt receipt;
  final ScholarshipApplication? application;
  final ApplicationProgress progress;
  final bool savingPdf;
  final VoidCallback onSavePdf;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FormCard(
        title: 'Bank challan generated',
        icon: Icons.receipt_long_outlined,
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
                      'Your registration fee challan is ready. Save it and take it to Faysal Bank for deposit.',
                      style: TextStyle(color: AppColors.ink, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _ReceiptSummary(receipt: receipt, application: application),
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
                  label: Text(savingPdf ? 'Saving PDF...' : 'Save challan PDF'),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      FormCard(
        title: 'Submission readiness',
        icon: Icons.fact_check_outlined,
        child: progress.readyForSubmission
            ? const Text(
                'All required sections are complete. You can submit the application from Home.',
                style: TextStyle(color: AppColors.pakistanGreen, height: 1.45),
              )
            : Text(
                'Still missing: ${progress.missingForSubmission.join(', ')}',
                style: const TextStyle(color: AppColors.muted, height: 1.45),
              ),
      ),
    ],
  );
}

class _ReceiptSummary extends StatelessWidget {
  const _ReceiptSummary({required this.receipt, required this.application});

  final ActivationReceipt receipt;
  final ScholarshipApplication? application;

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
        _summaryRow('Challan number', receipt.challanNumber),
        _summaryRow('Student name', receipt.account.fullName),
        _summaryRow('Father name', _fatherName(application)),
        _summaryRow('Amount', receipt.amountLabel),
        _summaryRow(
          'Due date',
          _formatDate(receipt.issuedAt.add(const Duration(days: 7))),
        ),
        _summaryRow('Status', 'Challan generated'),
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

  String _fatherName(ScholarshipApplication? application) {
    final family = application?.family ?? const {};
    final father = family['father'];
    if (father is Map) {
      final name = father['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return 'Not provided';
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
