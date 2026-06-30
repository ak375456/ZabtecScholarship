import 'package:flutter/material.dart';

import '../data/demo_profile.dart';
import '../models.dart';
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
    required this.account,
    required this.onLogout,
  });

  final Account account;
  final VoidCallback onLogout;

  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final progress = ApplicationProgress(prefilled: DemoProfile.enabled);
  List<EducationDocumentRequirement> _educationRequirements = [];
  ActivationReceipt? _activationReceipt;
  int _index = 0;

  static const _items = [
    (Icons.home_outlined, 'Home'),
    (Icons.person_outline_rounded, 'Profile'),
    (Icons.family_restroom_rounded, 'Family'),
    (Icons.school_outlined, 'Education'),
    (Icons.work_outline_rounded, 'Experience'),
    (Icons.science_outlined, 'Research'),
    (Icons.folder_copy_outlined, 'Documents'),
    (Icons.design_services_outlined, 'Services'),
  ];

  @override
  void initState() {
    super.initState();
    if (!DemoProfile.enabled) return;
    _educationRequirements = [
      for (var index = 0; index < DemoProfile.education.length; index++)
        EducationDocumentRequirement(
          id: index,
          level: DemoProfile.education[index].level,
          status: DemoProfile.education[index].status,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 920;
    final pages = [
      DashboardSection(
        account: widget.account,
        progress: progress,
        onContinue: () => _selectPage(1),
        onOpenServices: () => _selectPage(7),
      ),
      PersonalSection(
        account: widget.account,
        onSaved: () => _saved('Profile', () => progress.personal = true),
      ),
      FamilySection(
        onSaved: () => _saved('Family details', () => progress.family = true),
      ),
      EducationSection(
        onRequirementsChanged: (requirements) =>
            setState(() => _educationRequirements = requirements),
        onSaved: () =>
            _saved('Education history', () => progress.education = true),
      ),
      ExperienceSection(
        onSaved: () => _saved('Experience', () => progress.experience = true),
      ),
      ResearchSection(
        onSaved: () =>
            _saved('Research declaration', () => progress.research = true),
      ),
      DocumentsSection(
        educationRequirements: _educationRequirements,
        onSaved: () => _saved('Documents', () => progress.documents = true),
      ),
      ServicesSection(
        account: widget.account,
        progress: progress,
        receipt: _activationReceipt,
        onOpenSection: _selectPage,
        onPaymentCompleted: (receipt) => setState(() {
          _activationReceipt = receipt;
          progress.servicePaymentComplete = true;
        }),
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
                  account: widget.account,
                  selectedIndex: _index,
                  progress: progress,
                  onSelected: _selectPage,
                  onLogout: widget.onLogout,
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
          if (wide)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Center(
                child: Text(
                  '${progress.percent}% complete',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
                    widget.account.initials,
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
                account: widget.account,
                selectedIndex: _index,
                progress: progress,
                onSelected: _selectPage,
                onLogout: widget.onLogout,
              ),
            ),
          Expanded(
            child: IndexedStack(index: _index, children: pages),
          ),
        ],
      ),
    );
  }

  void _selectPage(int index) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
    setState(() => _index = index);
  }

  void _saved(String section, VoidCallback update) {
    setState(update);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$section saved. Progress updated.')),
    );
  }
}

class _PortalMenu extends StatelessWidget {
  const _PortalMenu({
    required this.account,
    required this.selectedIndex,
    required this.progress,
    required this.onSelected,
    required this.onLogout,
  });

  final Account account;
  final int selectedIndex;
  final ApplicationProgress progress;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;

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
                      progress.servicesUnlocked
                          ? 'Profile active'
                          : '${progress.percent}% profile complete',
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
    7 => progress.servicesUnlocked,
    _ => false,
  };

  Widget? _trailingFor(int index) {
    if (index == 7 && !progress.servicesUnlocked) {
      return Icon(
        progress.coreProfileComplete
            ? Icons.credit_card_rounded
            : Icons.lock_outline_rounded,
        size: 17,
        color: AppColors.muted,
      );
    }
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
    required this.progress,
    required this.onContinue,
    required this.onOpenServices,
  });

  final Account account;
  final ApplicationProgress progress;
  final VoidCallback onContinue;
  final VoidCallback onOpenServices;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 520 ? 18 : 32),
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
            const Text(
              'Your scholarship workspace is ready.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 26),
            _ProgressHero(progress: progress),
            const SizedBox(height: 18),
            _ActivationStatusCard(
              progress: progress,
              onContinue: onContinue,
              onOpenServices: onOpenServices,
            ),
            const SizedBox(height: 26),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 480 ? 24 : 34,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF3FB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inbox_outlined,
                      size: 34,
                      color: AppColors.zaptecBlue,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'No submitted application yet',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 7),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: const Text(
                      'Complete your profile from the menu. Your application status and future announcements will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 210,
                    child: PrimaryButton(
                      label: 'Continue setup',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: onContinue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActivationStatusCard extends StatelessWidget {
  const _ActivationStatusCard({
    required this.progress,
    required this.onContinue,
    required this.onOpenServices,
  });

  final ApplicationProgress progress;
  final VoidCallback onContinue;
  final VoidCallback onOpenServices;

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.servicesUnlocked;
    final readyForPayment = progress.coreProfileComplete && !unlocked;
    final title = unlocked
        ? 'Profile active'
        : readyForPayment
        ? 'Activation payment required'
        : 'Services unlock after setup';
    final description = unlocked
        ? 'Your profile is active and Services are now available.'
        : readyForPayment
        ? 'Your required profile sections are complete. Pay PKR 1,500 to activate your profile and services.'
        : 'Complete Profile, Family, Education and Documents first. After that, pay PKR 1,500 to activate your profile and services.';
    final icon = unlocked
        ? Icons.verified_user_outlined
        : readyForPayment
        ? Icons.credit_card_rounded
        : Icons.lock_outline_rounded;
    final color = unlocked ? AppColors.pakistanGreen : AppColors.zaptecBlue;
    final label = unlocked
        ? 'Open services'
        : readyForPayment
        ? 'Pay activation fee'
        : 'Continue setup';
    final action = readyForPayment || unlocked ? onOpenServices : onContinue;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 480 ? 18 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0800183B),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final content = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final button = SizedBox(
            width: compact ? double.infinity : 210,
            child: OutlinedButton.icon(
              onPressed: action,
              icon: Icon(unlocked ? Icons.apps_rounded : icon),
              label: Text(label),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [content, const SizedBox(height: 16), button],
            );
          }
          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 20),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({required this.progress});
  final ApplicationProgress progress;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 480 ? 22 : 30),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.deepBlue, AppColors.zaptecBlue],
      ),
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
              'APPLICATION READINESS',
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
                  ? 'Everything is ready'
                  : 'Build your application at your own pace',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 23,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Use the menu to move between sections. Your saved progress stays visible here.',
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
