import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key, required this.onContinue});
  final VoidCallback onContinue;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFD),
      body: Stack(
        children: [
          const Positioned.fill(child: _LandingBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth < 600 ? 24 : 56,
                  vertical: 22,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 44,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: constraints.maxWidth >= 840
                          ? Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _content(context, wide: true),
                                ),
                                const SizedBox(width: 56),
                                const Expanded(
                                  flex: 4,
                                  child: _OpportunityCard(),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _content(context),
                                const SizedBox(height: 30),
                                const _OpportunityCard(),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, {bool wide = false}) => FadeTransition(
    opacity: CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, .7, curve: Curves.easeOut),
    ),
    child: SlideTransition(
      position: Tween(begin: const Offset(0, .06), end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BrandMark(),
          const SizedBox(height: 34),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flag_rounded,
                  color: AppColors.pakistanGreen,
                  size: 18,
                ),
                SizedBox(width: 7),
                Flexible(
                  child: Text(
                    'FOR STUDENTS ACROSS PAKISTAN',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.pakistanGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your potential.\nOur scholarship.',
            style:
                (wide
                        ? Theme.of(context).textTheme.displayLarge
                        : Theme.of(context).textTheme.displaySmall)
                    ?.copyWith(color: AppColors.deepBlue),
          ),
          const SizedBox(height: 18),
          const Text(
            'A clearer path to higher education—built for ambitious Pakistani students ready to shape what comes next.',
            style: TextStyle(
              fontSize: 17,
              height: 1.55,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 25),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeaturePill(
                icon: Icons.school_outlined,
                label: 'Free education',
              ),
              _FeaturePill(
                icon: Icons.workspace_premium_outlined,
                label: 'Merit focused',
              ),
              _FeaturePill(icon: Icons.public, label: 'Nationwide access'),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: wide ? 220 : double.infinity,
            child: PrimaryButton(
              label: 'Begin application',
              icon: Icons.arrow_forward_rounded,
              onPressed: widget.onContinue,
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: AppColors.muted,
              ),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Your application is private and secure.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.zaptecBlue),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ],
    ),
  );
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard();

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 390),
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.zaptecBlue, AppColors.deepBlue],
      ),
      borderRadius: BorderRadius.circular(30),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40062F66),
          blurRadius: 42,
          offset: Offset(0, 18),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
        ),
        const SizedBox(height: 76),
        const Text(
          'EDUCATION CHANGES EVERYTHING',
          style: TextStyle(
            color: Color(0xFFA7E5C7),
            fontSize: 11,
            letterSpacing: 1.25,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'One application.\nA future of possibility.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 29,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -.6,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Complete your profile at your own pace and keep track of every step.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .74),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .13)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Color(0xFFA7E5C7)),
              SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Simple, guided application',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LandingBackdrop extends StatelessWidget {
  const _LandingBackdrop();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BackdropPainter());
}

class _BackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width * .95, -30),
      size.width * .32,
      Paint()..color = const Color(0x0D0789E8),
    );
    canvas.drawCircle(
      Offset(-40, size.height * .92),
      size.width * .22,
      Paint()..color = const Color(0x0F078F50),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
