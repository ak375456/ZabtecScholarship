import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../models.dart';
import '../../services/api_client.dart';
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
    required this.onPaymentChanged,
    required this.onPayActivation,
    required this.onUploadProof,
  });

  final Account account;
  final ScholarshipApplication? application;
  final ApplicationProgress progress;
  final ActivationReceipt? receipt;
  final ValueChanged<ActivationReceipt> onPaymentChanged;
  final Future<ActivationReceipt> Function({String method}) onPayActivation;
  final Future<ActivationReceipt> Function(UploadFilePayload file)
  onUploadProof;

  @override
  State<ServicesSection> createState() => _ServicesSectionState();
}

class _ServicesSectionState extends State<ServicesSection>
    with AutomaticKeepAliveClientMixin {
  bool _savingPdf = false;
  bool _paying = false;
  bool _uploadingProof = false;

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
                    : _ChallanStatusCard(
                        key: ValueKey('challan-${widget.receipt!.status}'),
                        receipt: widget.receipt!,
                        application: widget.application,
                        progress: widget.progress,
                        savingPdf: _savingPdf,
                        uploadingProof: _uploadingProof,
                        onSavePdf: _saveReceiptPdf,
                        onUploadProof: _pickAndUploadProof,
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
      widget.onPaymentChanged(receipt);
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

  Future<void> _pickAndUploadProof() async {
    if (_uploadingProof) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    final selected = result?.files.single;
    final bytes = selected?.bytes;
    if (selected == null || bytes == null || !mounted) return;
    if (bytes.lengthInBytes > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use an image smaller than 5 MB.')),
      );
      return;
    }

    setState(() => _uploadingProof = true);
    try {
      final payment = await widget.onUploadProof(
        UploadFilePayload(
          bytes: bytes,
          filename: selected.name,
          mimeType: _imageMimeType(selected.name),
        ),
      );
      widget.onPaymentChanged(payment);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stamped challan submitted for ZABTEC verification.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not upload stamped challan: $error')),
      );
    } finally {
      if (mounted) setState(() => _uploadingProof = false);
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

class _ChallanStatusCard extends StatelessWidget {
  const _ChallanStatusCard({
    super.key,
    required this.receipt,
    required this.application,
    required this.progress,
    required this.savingPdf,
    required this.uploadingProof,
    required this.onSavePdf,
    required this.onUploadProof,
  });

  final ActivationReceipt receipt;
  final ScholarshipApplication? application;
  final ApplicationProgress progress;
  final bool savingPdf;
  final bool uploadingProof;
  final VoidCallback onSavePdf;
  final VoidCallback onUploadProof;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FormCard(
        title: receipt.statusLabel,
        icon: Icons.receipt_long_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PaymentStatusBanner(receipt: receipt),
            const SizedBox(height: 18),
            _ReceiptSummary(receipt: receipt, application: application),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
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
                if (receipt.canUploadProof)
                  ElevatedButton.icon(
                    onPressed: uploadingProof ? null : onUploadProof,
                    icon: uploadingProof
                        ? const SizedBox.square(
                            dimension: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file_rounded),
                    label: Text(
                      uploadingProof
                          ? 'Uploading...'
                          : receipt.isRejected
                          ? 'Upload corrected copy'
                          : 'Upload stamped challan',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      FormCard(
        title: 'Submission readiness',
        icon: Icons.fact_check_outlined,
        child: receipt.isApproved && progress.readyForSubmission
            ? const Text(
                'Your payment is approved. You can now submit the application from Home.',
                style: TextStyle(color: AppColors.pakistanGreen, height: 1.45),
              )
            : Text(
                receipt.isApproved
                    ? 'Still missing: ${progress.missingForSubmission.join(', ')}'
                    : 'Application submission remains locked until ZABTEC approves the stamped challan.',
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
        _summaryRow('Status', receipt.statusLabel),
        if (receipt.proofOriginalName != null)
          _summaryRow('Uploaded copy', receipt.proofOriginalName!),
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

class _PaymentStatusBanner extends StatelessWidget {
  const _PaymentStatusBanner({required this.receipt});

  final ActivationReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final (background, border, icon, color, message) = receipt.isApproved
        ? (
            AppColors.mint,
            const Color(0xFFCBE8DA),
            Icons.verified_rounded,
            AppColors.pakistanGreen,
            'ZABTEC has verified your bank-stamped challan. Your payment step is complete.',
          )
        : receipt.isPendingReview
        ? (
            const Color(0xFFFFF7E8),
            const Color(0xFFFFE0A8),
            Icons.hourglass_top_rounded,
            const Color(0xFFA66200),
            'Your stamped challan is pending ZABTEC verification. You will be able to continue after approval.',
          )
        : receipt.isRejected
        ? (
            const Color(0xFFFFF1F1),
            const Color(0xFFF2C0C0),
            Icons.cancel_outlined,
            AppColors.danger,
            'ZABTEC rejected this copy: ${receipt.rejectionReason ?? 'Please upload a clear bank-stamped challan.'}',
          )
        : (
            const Color(0xFFEAF3FB),
            const Color(0xFFC9DFF0),
            Icons.account_balance_outlined,
            AppColors.zaptecBlue,
            'Save the challan, pay it at Faysal Bank, then upload a clear image of the bank-stamped copy.',
          );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.ink, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

String? _imageMimeType(String filename) {
  final lower = filename.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return null;
}
