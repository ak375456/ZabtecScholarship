import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/demo_profile.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ResearchSection extends StatefulWidget {
  const ResearchSection({super.key, required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<ResearchSection> createState() => _ResearchSectionState();
}

class _ResearchSectionState extends State<ResearchSection>
    with AutomaticKeepAliveClientMixin {
  final _key = GlobalKey<FormState>();
  bool? _hasResearch = DemoProfile.enabled ? false : null;
  int _publications = 1;
  bool _attempted = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 520 ? 18 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Form(
            key: _key,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader(
                  eyebrow: 'Academic background',
                  title: 'Research & publications',
                  description:
                      'Tell us about published work, or simply declare that you do not have any yet.',
                ),
                const SizedBox(height: 24),
                FormCard(
                  title: 'Research declaration',
                  icon: Icons.science_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Have you authored or co-authored a published research paper?',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.check_rounded),
                            label: Text('Yes'),
                          ),
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.close_rounded),
                            label: Text('Not yet'),
                          ),
                        ],
                        selected: _hasResearch == null
                            ? <bool>{}
                            : {_hasResearch!},
                        emptySelectionAllowed: true,
                        onSelectionChanged: (value) =>
                            setState(() => _hasResearch = value.first),
                      ),
                      if (_hasResearch == null && _attempted) ...[
                        const SizedBox(height: 9),
                        const Text(
                          'Please choose one option.',
                          style: TextStyle(
                            color: Color(0xFFC73838),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: _hasResearch == true
                      ? Column(
                          children: [
                            const SizedBox(height: 18),
                            ...List.generate(
                              _publications,
                              (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 18),
                                child: _PublicationCard(
                                  number: index + 1,
                                  canRemove: _publications > 1,
                                  onRemove: () =>
                                      setState(() => _publications--),
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _publications >= 5
                                  ? null
                                  : () => setState(() => _publications++),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add another publication'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                if (_hasResearch == false) ...[
                  const SizedBox(height: 18),
                  FormCard(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.leafGreen,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'That’s completely fine. Research experience is not required to complete your profile.',
                              style: TextStyle(
                                color: AppColors.pakistanGreen,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width < 520
                        ? double.infinity
                        : 210,
                    child: PrimaryButton(
                      label: 'Save section',
                      icon: Icons.check_rounded,
                      onPressed: _save,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (_hasResearch == null) {
      setState(() => _attempted = true);
      return;
    }
    if (_key.currentState!.validate()) widget.onSaved();
  }
}

class _PublicationCard extends StatelessWidget {
  const _PublicationCard({
    required this.number,
    required this.canRemove,
    required this.onRemove,
  });
  final int number;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => FormCard(
    title: 'Publication $number',
    icon: Icons.article_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canRemove)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              label: const Text('Remove'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB23535),
              ),
            ),
          ),
        TextFormField(
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Paper title'),
          validator: (v) => requiredText(v, 'Paper title'),
        ),
        const SizedBox(height: 16),
        FormGrid(
          children: [
            TextFormField(
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Journal / conference',
              ),
              validator: (v) => requiredText(v, 'Journal / conference'),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Publication status',
              ),
              items: [
                'Published',
                'Accepted',
                'In press',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (_) {},
              validator: (v) => v == null ? 'Select publication status' : null,
            ),
            TextFormField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                DigitsOnlyFormatter(),
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(labelText: 'Publication year'),
              validator: (v) => requiredText(v, 'Publication year'),
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'DOI (optional)',
                hintText: '10.xxxx/xxxxx',
              ),
            ),
            TextFormField(
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Your role',
                hintText: 'e.g. First author',
              ),
              validator: (v) => requiredText(v, 'Author role'),
            ),
            TextFormField(
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Publication URL (optional)',
                hintText: 'https://',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          minLines: 3,
          maxLines: 5,
          maxLength: 400,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Research summary',
            hintText: 'Briefly describe the problem and your contribution',
          ),
          validator: (v) => requiredText(v, 'Research summary'),
        ),
      ],
    ),
  );
}
