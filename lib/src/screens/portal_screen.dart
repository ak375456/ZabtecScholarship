import 'package:flutter/material.dart';

import '../models.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'sections/documents_section.dart';
import 'sections/education_section.dart';
import 'sections/experience_section.dart';
import 'sections/family_section.dart';
import 'sections/personal_section.dart';
import 'sections/research_section.dart';
import 'sections/services_section.dart';

class PortalScreen extends StatefulWidget {
  const PortalScreen({
    super.key,
    required this.api,
    required this.session,
    required this.onLogout,
  });

  final ApiClient api;
  final AuthSession session;
  final Future<void> Function() onLogout;

  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  ScholarshipApplication? _application;
  List<StudentDocument> _documents = [];
  List<EducationDocumentRequirement> _educationRequirements = [];
  ActivationReceipt? _activationReceipt;
  bool _loading = true;
  bool _submitting = false;
  bool _deletingAccount = false;
  int _index = 0;

  static const _items = [
    (Icons.home_outlined, 'Home'),
    (Icons.person_outline_rounded, 'Profile'),
    (Icons.family_restroom_rounded, 'Family'),
    (Icons.school_outlined, 'Education'),
    (Icons.work_outline_rounded, 'Experience'),
    (Icons.science_outlined, 'Research'),
    (Icons.folder_copy_outlined, 'Documents'),
    (Icons.receipt_long_outlined, 'Challan'),
  ];

  ApplicationProgress get _progress =>
      _effectiveProgress(_application?.progress ?? ApplicationProgress());

  Account get _account => widget.session.user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 920;
    final pages = [
      DashboardSection(
        account: _account,
        application: _application,
        documents: _documents,
        receipt: _activationReceipt,
        loading: _loading,
        submitting: _submitting,
        onRefresh: _load,
        onContinue: () => _selectPage(1),
        onOpenPayment: () => _selectPage(7),
        onSubmit: _submitApplication,
      ),
      PersonalSection(
        account: _account,
        application: _application,
        onSaved: (payload) =>
            _saveSection('Profile', () => widget.api.updatePersonal(payload)),
      ),
      FamilySection(
        application: _application,
        onSaved: (payload) => _saveSection(
          'Family details',
          () => widget.api.updateFamily(payload),
        ),
      ),
      EducationSection(
        application: _application,
        onRequirementsChanged: (requirements) =>
            setState(() => _educationRequirements = requirements),
        onSaved: (entries) => _saveSection(
          'Education history',
          () => widget.api.updateEducation(entries),
        ),
      ),
      ExperienceSection(
        application: _application,
        onSaved: (payload) => _saveSection(
          'Experience',
          () => widget.api.updateExperience(payload),
        ),
      ),
      ResearchSection(
        application: _application,
        onSaved: (payload) => _saveSection(
          'Research declaration',
          () => widget.api.updateResearch(payload),
        ),
      ),
      DocumentsSection(
        educationRequirements: _educationRequirements,
        documents: _documents,
        onUpload: _uploadDocument,
        onDelete: _deleteDocument,
        onSaved: () => _saveSection('Documents', () async => {}),
      ),
      ServicesSection(
        account: _account,
        application: _application,
        progress: _progress,
        receipt: _activationReceipt,
        onPaymentCompleted: (receipt) => setState(() {
          _activationReceipt = receipt;
          _application?.progress.payment = true;
        }),
        onPayActivation: _payActivation,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: wide
          ? null
          : Drawer(
              width: MediaQuery.sizeOf(context).width.clamp(280, 330),
              child: SafeArea(
                child: _PortalMenu(
                  account: _account,
                  selectedIndex: _index,
                  progress: _progress,
                  onSelected: _selectPage,
                  onLogout: widget.onLogout,
                  onDeleteAccount: _confirmDeleteAccount,
                  deletingAccount: _deletingAccount,
                ),
              ),
            ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 12,
        leading: wide
            ? null
            : IconButton(
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Open menu',
              ),
        title: wide
            ? const BrandMark(compact: true)
            : Text(
                _items[_index].$2,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Refresh application',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Semantics(
              button: true,
              label: 'Open profile',
              child: InkWell(
                onTap: () => _selectPage(1),
                borderRadius: BorderRadius.circular(30),
                child: CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColors.deepBlue,
                  child: Text(
                    _account.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 248,
              child: _PortalMenu(
                account: _account,
                selectedIndex: _index,
                progress: _progress,
                onSelected: _selectPage,
                onLogout: widget.onLogout,
                onDeleteAccount: _confirmDeleteAccount,
                deletingAccount: _deletingAccount,
              ),
            ),
          Expanded(
            child: IndexedStack(index: _index, children: pages),
          ),
        ],
      ),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait<dynamic>([
        widget.api.getStudentApplication(),
        widget.api.getDocuments(),
        widget.api.getReceipt(),
      ]);
      final app = results[0] as ScholarshipApplication;
      if (!mounted) return;
      setState(() {
        _application = app;
        _documents = results[1] as List<StudentDocument>;
        _activationReceipt = results[2] as ActivationReceipt?;
        _educationRequirements = _requirementsFrom(app);
      });
    } catch (error) {
      _message('Could not load portal data: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSection(
    String section,
    Future<dynamic> Function() action,
  ) async {
    try {
      await action();
      await _load();
      _message('$section saved.');
    } catch (error) {
      _message('Could not save $section: $error');
      rethrow;
    }
  }

  Future<void> _uploadDocument(
    String documentType,
    UploadFilePayload file,
  ) async {
    await widget.api.uploadDocument(documentType: documentType, file: file);
    await _load();
  }

  Future<void> _deleteDocument(StudentDocument document) async {
    await widget.api.deleteDocument(document.id);
    await _load();
  }

  Future<ActivationReceipt> _payActivation({
    String method = 'bank_transfer',
  }) async {
    if (!_progress.paymentEligible) {
      throw 'Complete all required profile sections and documents before generating the challan.';
    }
    final receipt = await widget.api.processPayment(method: method);
    await _load();
    return receipt;
  }

  Future<void> _submitApplication() async {
    if (!_progress.readyForSubmission || _submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.api.submitApplication();
      await _load();
      _message('Application submitted successfully.');
    } catch (error) {
      _message('Could not submit application: $error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    if (_deletingAccount) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
        title: const Text('Delete account permanently?'),
        content: const Text(
          'This will permanently delete your student account and associated '
          'scholarship application data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _deletingAccount = true);
    try {
      await widget.api.deleteStudentAccount();
    } catch (error) {
      _message('Could not delete account: $error');
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  void _selectPage(int index) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    setState(() => _index = index);
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<EducationDocumentRequirement> _requirementsFrom(
    ScholarshipApplication app,
  ) => [
    for (var index = 0; index < app.education.length; index++)
      if ((app.education[index]['level']?.toString() ?? '').isNotEmpty)
        EducationDocumentRequirement(
          id: index,
          level: app.education[index]['level'].toString(),
          status: 'Completed',
        ),
  ];

  ApplicationProgress _effectiveProgress(ApplicationProgress source) {
    final paid = source.payment || _activationReceipt != null;
    return ApplicationProgress(
      personal: source.personal,
      family: source.family,
      education: source.education,
      experience: source.experience,
      research: source.research,
      documents: _requiredDocumentsComplete(),
      payment: paid,
    );
  }

  bool _requiredDocumentsComplete() {
    final uploaded = _documents
        .map((document) => document.documentType)
        .toSet();
    return _requiredDocumentTypes().every(uploaded.contains);
  }

  Set<String> _requiredDocumentTypes() => {
    'photograph',
    'cnic_front',
    'cnic_back',
    ..._educationDocumentTypes(_educationRequirements),
  };
}

Set<String> _educationDocumentTypes(
  List<EducationDocumentRequirement> requirements,
) {
  final types = <String>{};
  for (final requirement in requirements) {
    final level = requirement.level.toLowerCase();
    if (level.contains('matric') || level.contains('ssc')) {
      types.add('matric_certificate');
    } else if (level.contains('fsc') ||
        level.contains('hssc') ||
        level.contains('a-level') ||
        level.contains('o-level')) {
      types.add('fsc_certificate');
    } else if (level.contains('master') || level.contains('mphil')) {
      types.add('masters_certificate');
    } else if (level.contains('bs') ||
        level.contains('bachelor') ||
        level.contains('associate')) {
      types.add('bachelors_certificate');
    } else {
      types.add('other');
    }
  }
  return types;
}

class _PortalMenu extends StatelessWidget {
  const _PortalMenu({
    required this.account,
    required this.selectedIndex,
    required this.progress,
    required this.onSelected,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.deletingAccount,
  });

  final Account account;
  final int selectedIndex;
  final ApplicationProgress progress;
  final ValueChanged<int> onSelected;
  final Future<void> Function() onLogout;
  final Future<void> Function() onDeleteAccount;
  final bool deletingAccount;

  static const _items = _PortalScreenState._items;

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.deepBlue,
                child: Text(
                  account.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${progress.percent}% complete',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _items.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: ListTile(
                onTap: () => onSelected(index),
                selected: selectedIndex == index,
                selectedTileColor: const Color(0xFFEAF3FB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                leading: Icon(
                  _items[index].$1,
                  color: selectedIndex == index
                      ? AppColors.zaptecBlue
                      : AppColors.muted,
                ),
                title: Text(
                  _items[index].$2,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selectedIndex == index
                        ? AppColors.deepBlue
                        : AppColors.muted,
                  ),
                ),
                trailing: _trailingFor(index),
              ),
            ),
          ),
        ),
        const Divider(),
        ListTile(
          onTap: onLogout,
          leading: const Icon(Icons.logout_rounded, color: AppColors.muted),
          title: const Text(
            'Sign out',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        ListTile(
          onTap: deletingAccount ? null : onDeleteAccount,
          leading: deletingAccount
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.danger,
                  ),
                )
              : const Icon(Icons.delete_forever_outlined),
          iconColor: AppColors.danger,
          title: Text(
            deletingAccount ? 'Deleting account...' : 'Delete account',
            style: const TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    ),
  );

  bool _completeFor(int index) => switch (index) {
    1 => progress.personal,
    2 => progress.family,
    3 => progress.education,
    4 => progress.experience,
    5 => progress.research,
    6 => progress.documents,
    7 => progress.payment,
    _ => false,
  };

  Widget? _trailingFor(int index) {
    if (index > 0 && _completeFor(index)) {
      return const Icon(
        Icons.check_circle,
        size: 17,
        color: AppColors.leafGreen,
      );
    }
    return null;
  }
}

class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.account,
    required this.application,
    required this.documents,
    required this.receipt,
    required this.loading,
    required this.submitting,
    required this.onRefresh,
    required this.onContinue,
    required this.onOpenPayment,
    required this.onSubmit,
  });

  final Account account;
  final ScholarshipApplication? application;
  final List<StudentDocument> documents;
  final ActivationReceipt? receipt;
  final bool loading;
  final bool submitting;
  final Future<void> Function() onRefresh;
  final VoidCallback onContinue;
  final VoidCallback onOpenPayment;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final progress = application?.progress ?? ApplicationProgress();
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 520 ? 18 : 32,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${account.fullName.split(' ').first}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 7),
                Text(
                  loading
                      ? 'Loading your application...'
                      : 'Your application is ready to continue.',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 26),
                _ProgressHero(progress: progress),
                const SizedBox(height: 18),
                _StatusCard(
                  application: application,
                  receipt: receipt,
                  progress: progress,
                  submitting: submitting,
                  onContinue: onContinue,
                  onOpenPayment: onOpenPayment,
                  onSubmit: onSubmit,
                ),
                const SizedBox(height: 26),
                _ApplicationSummary(
                  application: application,
                  documents: documents,
                  receipt: receipt,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.application,
    required this.receipt,
    required this.progress,
    required this.submitting,
    required this.onContinue,
    required this.onOpenPayment,
    required this.onSubmit,
  });

  final ScholarshipApplication? application;
  final ActivationReceipt? receipt;
  final ApplicationProgress progress;
  final bool submitting;
  final VoidCallback onContinue;
  final VoidCallback onOpenPayment;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        application?.isDraft == true && progress.readyForSubmission;
    return FormCard(
      title: 'Application status',
      icon: Icons.assignment_turned_in_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                application?.statusLabel ?? 'Loading',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                application?.applicationNumber == null
                    ? 'Application number will appear when your record is created.'
                    : 'Application ${application!.applicationNumber}',
                style: const TextStyle(color: AppColors.muted),
              ),
              if (!progress.readyForSubmission) ...[
                const SizedBox(height: 10),
                Text(
                  'Complete before submission: ${progress.missingForSubmission.join(', ')}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
              if (receipt != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Challan ${receipt!.challanNumber}',
                  style: const TextStyle(
                    color: AppColors.pakistanGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          );
          final buttons = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: progress.payment
                    ? onContinue
                    : progress.paymentEligible
                    ? onOpenPayment
                    : onContinue,
                icon: Icon(
                  progress.payment
                      ? Icons.edit_note_rounded
                      : progress.paymentEligible
                      ? Icons.payments_outlined
                      : Icons.payments_outlined,
                ),
                label: Text(
                  progress.payment
                      ? 'Continue form'
                      : progress.paymentEligible
                      ? 'Open challan'
                      : 'Complete profile',
                ),
              ),
              ElevatedButton.icon(
                onPressed: canSubmit && !submitting ? onSubmit : null,
                icon: submitting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(submitting ? 'Submitting...' : 'Submit'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [content, const SizedBox(height: 18), buttons],
            );
          }
          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 20),
              buttons,
            ],
          );
        },
      ),
    );
  }
}

class _ApplicationSummary extends StatelessWidget {
  const _ApplicationSummary({
    required this.application,
    required this.documents,
    required this.receipt,
  });

  final ScholarshipApplication? application;
  final List<StudentDocument> documents;
  final ActivationReceipt? receipt;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 760
          ? (constraints.maxWidth - 28) / 3
          : constraints.maxWidth;
      final cards = [
        _MetricCard(
          icon: Icons.confirmation_number_outlined,
          label: 'Application',
          value: application?.applicationNumber ?? 'Draft',
        ),
        _MetricCard(
          icon: Icons.folder_copy_outlined,
          label: 'Documents',
          value: '${documents.length} uploaded',
        ),
        _MetricCard(
          icon: Icons.receipt_long_outlined,
          label: 'Challan',
          value: receipt == null ? 'Pending' : 'Generated',
        ),
      ];
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        children: cards
            .map((card) => SizedBox(width: width, child: card))
            .toList(),
      );
    },
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.zaptecBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({required this.progress});
  final ApplicationProgress progress;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 480 ? 22 : 30),
    decoration: BoxDecoration(
      color: AppColors.deepBlue,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x2D062F66),
          blurRadius: 30,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final text = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'APPLICATION PROGRESS',
              style: TextStyle(
                color: Color(0xFFA6D8FF),
                fontSize: 11,
                letterSpacing: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              progress.percent == 100
                  ? 'Everything is complete'
                  : 'Complete your application sections',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your progress updates automatically as each required section is saved.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .72),
                height: 1.45,
              ),
            ),
          ],
        );
        final ring = SizedBox(
          width: 116,
          height: 116,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 106,
                height: 106,
                child: CircularProgressIndicator(
                  value: progress.value,
                  strokeWidth: 9,
                  backgroundColor: Colors.white.withValues(alpha: .14),
                  color: const Color(0xFF65D6A2),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Text(
                '${progress.percent}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [text, const SizedBox(height: 24), ring],
          );
        }
        return Row(
          children: [
            Expanded(child: text),
            const SizedBox(width: 28),
            ring,
          ],
        );
      },
    ),
  );
}
