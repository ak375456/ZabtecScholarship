import 'package:flutter/material.dart';

import '../../data/demo_profile.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ExperienceSection extends StatefulWidget {
  const ExperienceSection({super.key, required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<ExperienceSection> createState() => _ExperienceSectionState();
}

class _ExperienceSectionState extends State<ExperienceSection>
    with AutomaticKeepAliveClientMixin {
  final _key = GlobalKey<FormState>();
  final List<int> _records = [0];
  int _nextId = 1;
  bool? _hasExperience = DemoProfile.enabled ? true : null;

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
                  eyebrow: 'Background',
                  title: 'Experience',
                  description:
                      'Include employment, internships, volunteering, freelance work or leadership experience.',
                ),
                const SizedBox(height: 24),
                FormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Do you have any experience to add?',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('Yes')),
                          ButtonSegment(value: false, label: Text('Not yet')),
                        ],
                        selected: _hasExperience == null
                            ? <bool>{}
                            : {_hasExperience!},
                        emptySelectionAllowed: true,
                        onSelectionChanged: (value) =>
                            setState(() => _hasExperience = value.first),
                      ),
                    ],
                  ),
                ),
                if (_hasExperience == true) ...[
                  const SizedBox(height: 18),
                  ...List.generate(
                    _records.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _ExperienceRecord(
                        key: ValueKey(_records[index]),
                        number: index + 1,
                        canRemove: _records.length > 1,
                        demo: DemoProfile.enabled && index == 0
                            ? DemoProfile.experience
                            : null,
                        onRemove: () =>
                            setState(() => _records.removeAt(index)),
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _records.length >= 6
                        ? null
                        : () => setState(() => _records.add(_nextId++)),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add another experience'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
                if (_hasExperience == false) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: AppColors.leafGreen,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Experience is optional. You can return and add it later.',
                            style: TextStyle(color: AppColors.pakistanGreen),
                          ),
                        ),
                      ],
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
                      label: 'Save experience',
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
    if (_hasExperience == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Yes or Not yet.')),
      );
      return;
    }
    if (_key.currentState!.validate()) widget.onSaved();
  }
}

class _ExperienceRecord extends StatefulWidget {
  const _ExperienceRecord({
    super.key,
    required this.number,
    required this.canRemove,
    required this.demo,
    required this.onRemove,
  });

  final int number;
  final bool canRemove;
  final DemoExperience? demo;
  final VoidCallback onRemove;

  @override
  State<_ExperienceRecord> createState() => _ExperienceRecordState();
}

class _ExperienceRecordState extends State<_ExperienceRecord> {
  late bool _current;

  @override
  void initState() {
    super.initState();
    _current = widget.demo?.current ?? false;
  }

  @override
  Widget build(BuildContext context) => FormCard(
    title: 'Experience ${widget.number}',
    icon: Icons.work_outline_rounded,
    child: Column(
      children: [
        if (widget.canRemove)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Remove'),
            ),
          ),
        FormGrid(
          children: [
            TextFormField(
              initialValue: widget.demo?.organization,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Organization'),
              validator: (v) => requiredText(v, 'Organization'),
            ),
            TextFormField(
              initialValue: widget.demo?.role,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Role / title'),
              validator: (v) => requiredText(v, 'Role / title'),
            ),
            DropdownButtonFormField<String>(
              initialValue: widget.demo?.type,
              decoration: const InputDecoration(labelText: 'Experience type'),
              items: [
                'Employment',
                'Internship',
                'Volunteer work',
                'Freelance',
                'Leadership',
                'Other',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (_) {},
              validator: (v) => v == null ? 'Select experience type' : null,
            ),
            TextFormField(
              initialValue: widget.demo?.startDate,
              decoration: const InputDecoration(
                labelText: 'Start date',
                hintText: 'MM/YYYY',
              ),
              validator: (v) => requiredText(v, 'Start date'),
            ),
            if (!_current)
              TextFormField(
                initialValue: widget.demo?.endDate,
                decoration: const InputDecoration(
                  labelText: 'End date',
                  hintText: 'MM/YYYY',
                ),
                validator: (v) => requiredText(v, 'End date'),
              ),
          ],
        ),
        CheckboxListTile(
          value: _current,
          onChanged: (value) => setState(() => _current = value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('I currently work here'),
        ),
        TextFormField(
          initialValue: widget.demo?.description,
          minLines: 3,
          maxLines: 5,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Responsibilities and achievements',
          ),
          validator: (v) => requiredText(v, 'Experience description'),
        ),
      ],
    ),
  );
}
