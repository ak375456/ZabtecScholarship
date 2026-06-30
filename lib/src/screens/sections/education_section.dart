import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/demo_profile.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class EducationSection extends StatefulWidget {
  const EducationSection({
    super.key,
    required this.onSaved,
    required this.onRequirementsChanged,
  });

  final VoidCallback onSaved;
  final ValueChanged<List<EducationDocumentRequirement>> onRequirementsChanged;

  @override
  State<EducationSection> createState() => _EducationSectionState();
}

class _EducationSectionState extends State<EducationSection>
    with AutomaticKeepAliveClientMixin {
  final _key = GlobalKey<FormState>();
  late final List<int> _records;
  late final Map<int, EducationDocumentRequirement> _requirements;
  late int _nextId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (DemoProfile.enabled) {
      _records = List.generate(DemoProfile.education.length, (index) => index);
      _nextId = _records.length;
      _requirements = {
        for (var index = 0; index < DemoProfile.education.length; index++)
          index: EducationDocumentRequirement(
            id: index,
            level: DemoProfile.education[index].level,
            status: DemoProfile.education[index].status,
          ),
      };
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onRequirementsChanged(_requirements.values.toList());
        }
      });
    } else {
      _records = [0];
      _nextId = 1;
      _requirements = {};
    }
  }

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
                  eyebrow: 'Academic profile',
                  title: 'Education',
                  description:
                      'Add only the qualifications you have studied. Academic images are managed separately in Documents.',
                ),
                const SizedBox(height: 24),
                ...List.generate(
                  _records.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _EducationRecord(
                      key: ValueKey(_records[index]),
                      recordId: _records[index],
                      number: index + 1,
                      canRemove: _records.length > 1,
                      demo:
                          DemoProfile.enabled &&
                              index < DemoProfile.education.length
                          ? DemoProfile.education[index]
                          : null,
                      onChanged: (requirement) =>
                          _updateRequirement(_records[index], requirement),
                      onRemove: () => _removeRecord(index),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _records.length >= 8
                      ? null
                      : () => setState(() => _records.add(_nextId++)),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add another qualification'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width < 520
                        ? double.infinity
                        : 210,
                    child: PrimaryButton(
                      label: 'Save education',
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

  void _updateRequirement(int id, EducationDocumentRequirement? requirement) {
    if (requirement == null) {
      _requirements.remove(id);
    } else {
      _requirements[id] = requirement;
    }
    widget.onRequirementsChanged(_requirements.values.toList());
  }

  void _removeRecord(int index) {
    final id = _records[index];
    setState(() => _records.removeAt(index));
    _requirements.remove(id);
    widget.onRequirementsChanged(_requirements.values.toList());
  }

  void _save() {
    if (_key.currentState!.validate()) widget.onSaved();
  }
}

class _EducationRecord extends StatefulWidget {
  const _EducationRecord({
    super.key,
    required this.recordId,
    required this.number,
    required this.canRemove,
    required this.demo,
    required this.onChanged,
    required this.onRemove,
  });

  final int recordId;
  final int number;
  final bool canRemove;
  final DemoEducation? demo;
  final ValueChanged<EducationDocumentRequirement?> onChanged;
  final VoidCallback onRemove;

  @override
  State<_EducationRecord> createState() => _EducationRecordState();
}

class _EducationRecordState extends State<_EducationRecord> {
  late String? _level;
  late String _status;
  late String _grading;

  static const _levels = [
    'Matric / SSC',
    'FSc / HSSC',
    'O-Level',
    'A-Level',
    'Diploma / DAE',
    'Associate degree',
    'BS / Bachelor’s',
    'Master’s',
    'MPhil / MS',
    'PhD',
  ];

  @override
  void initState() {
    super.initState();
    _level = widget.demo?.level;
    _status = widget.demo?.status ?? 'Completed';
    _grading = widget.demo?.grading ?? 'Percentage';
  }

  @override
  Widget build(BuildContext context) => FormCard(
    title: 'Qualification ${widget.number}',
    icon: Icons.school_outlined,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.canRemove)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              label: const Text('Remove'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB23535),
              ),
            ),
          ),
        FormGrid(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _level,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Qualification level',
              ),
              items: _levels
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _level = value);
                _notifyParent();
              },
              validator: (v) => v == null ? 'Select qualification level' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Study status'),
              items: [
                'Completed',
                'In progress',
                'Awaiting result',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (value) {
                setState(() => _status = value!);
                _notifyParent();
              },
            ),
            TextFormField(
              initialValue: widget.demo?.programme,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Programme / group',
                hintText: 'e.g. Pre-Engineering or Computer Science',
              ),
              validator: (v) => requiredText(v, 'Programme / group'),
            ),
            TextFormField(
              initialValue: widget.demo?.institute,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Institute name'),
              validator: (v) => requiredText(v, 'Institute name'),
            ),
            TextFormField(
              initialValue: widget.demo?.board,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Board / university',
              ),
              validator: (v) => requiredText(v, 'Board / university'),
            ),
            TextFormField(
              initialValue: widget.demo?.registrationNumber,
              decoration: const InputDecoration(
                labelText: 'Roll / registration number',
              ),
              validator: (v) => requiredText(v, 'Registration number'),
            ),
            TextFormField(
              initialValue: widget.demo?.completionYear,
              keyboardType: TextInputType.number,
              inputFormatters: [
                DigitsOnlyFormatter(),
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: _status == 'Completed'
                    ? 'Completion year'
                    : 'Expected completion year',
                hintText: '2026',
              ),
              validator: _validateYear,
            ),
            DropdownButtonFormField<String>(
              initialValue: _grading,
              decoration: const InputDecoration(labelText: 'Grading system'),
              items: [
                'Percentage',
                'GPA / CGPA',
                'Grade',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (value) => setState(() => _grading = value!),
            ),
            ..._resultFields(),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FB),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Row(
            children: [
              Icon(Icons.folder_outlined, color: AppColors.zaptecBlue),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Transcript and certificate images will appear in Documents after you select a qualification.',
                  style: TextStyle(color: AppColors.deepBlue, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _notifyParent() {
    final level = _level;
    if (level == null) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged(
      EducationDocumentRequirement(
        id: widget.recordId,
        level: level,
        status: _status,
      ),
    );
  }

  List<Widget> _resultFields() {
    if (_status != 'Completed') return const [];
    if (_grading == 'GPA / CGPA') {
      return [
        _numberField(
          'GPA / CGPA achieved',
          'e.g. 3.65',
          initialValue: widget.demo?.gpa,
        ),
        _numberField(
          'GPA scale',
          'e.g. 4.0 or 5.0',
          initialValue: widget.demo?.gpaScale,
        ),
      ];
    }
    if (_grading == 'Grade') {
      return [
        TextFormField(
          initialValue: widget.demo?.grade,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Grade achieved',
            hintText: 'e.g. A+',
          ),
          validator: (v) => requiredText(v, 'Grade'),
        ),
      ];
    }
    return [
      _numberField(
        'Obtained marks',
        'e.g. 935',
        initialValue: widget.demo?.obtainedMarks,
      ),
      _numberField(
        'Total marks',
        'e.g. 1100',
        initialValue: widget.demo?.totalMarks,
      ),
      _numberField(
        'Percentage',
        'e.g. 85',
        initialValue: widget.demo?.percentage,
      ),
    ];
  }

  Widget _numberField(String label, String hint, {String? initialValue}) =>
      TextFormField(
        initialValue: initialValue,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: InputDecoration(labelText: label, hintText: hint),
        validator: (v) => requiredText(v, label),
      );

  String? _validateYear(String? value) {
    final required = requiredText(value, 'Year');
    if (required != null) return required;
    final year = int.tryParse(value!);
    if (year == null || year < 1960 || year > DateTime.now().year + 8) {
      return 'Enter a valid year';
    }
    return null;
  }
}
