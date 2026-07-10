import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class EducationSection extends StatefulWidget {
  const EducationSection({
    super.key,
    required this.application,
    required this.onSaved,
    required this.onRequirementsChanged,
  });

  final ScholarshipApplication? application;
  final Future<void> Function(List<Map<String, dynamic>> entries) onSaved;
  final ValueChanged<List<EducationDocumentRequirement>> onRequirementsChanged;

  @override
  State<EducationSection> createState() => _EducationSectionState();
}

class _EducationSectionState extends State<EducationSection>
    with AutomaticKeepAliveClientMixin {
  final _key = GlobalKey<FormState>();
  final List<_EducationRecordData> _records = [];
  int _nextId = 0;
  bool _saving = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  @override
  void didUpdateWidget(covariant EducationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.application?.id != widget.application?.id) _hydrate();
  }

  @override
  void dispose() {
    for (final record in _records) {
      record.dispose();
    }
    super.dispose();
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
                      'Add the qualifications you have studied. Academic documents are uploaded in Documents.',
                ),
                const SizedBox(height: 24),
                for (var index = 0; index < _records.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _EducationRecord(
                      key: ValueKey(_records[index].id),
                      data: _records[index],
                      number: index + 1,
                      canRemove: _records.length > 1,
                      onChanged: _notifyRequirements,
                      onRemove: () => _removeRecord(index),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _records.length >= 8 ? null : _addRecord,
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
                      label: _saving ? 'Saving...' : 'Save education',
                      icon: Icons.check_rounded,
                      onPressed: _saving ? null : _save,
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

  void _addRecord() {
    setState(() => _records.add(_EducationRecordData(id: _nextId++)));
    _notifyRequirements();
  }

  void _removeRecord(int index) {
    final removed = _records.removeAt(index);
    removed.dispose();
    setState(() {});
    _notifyRequirements();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSaved(_records.map((record) => record.payload()).toList());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _hydrate() {
    for (final record in _records) {
      record.dispose();
    }
    _records.clear();
    _nextId = 0;
    final entries = widget.application?.education ?? const [];
    if (entries.isEmpty) {
      _records.add(_EducationRecordData(id: _nextId++));
    } else {
      for (final entry in entries) {
        _records.add(_EducationRecordData.fromJson(id: _nextId++, json: entry));
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifyRequirements();
    });
  }

  void _notifyRequirements() {
    widget.onRequirementsChanged(
      _records
          .where((record) => record.level != null)
          .map(
            (record) => EducationDocumentRequirement(
              id: record.id,
              level: record.level!,
              status: record.status,
            ),
          )
          .toList(),
    );
  }
}

class _EducationRecord extends StatelessWidget {
  const _EducationRecord({
    super.key,
    required this.data,
    required this.number,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final _EducationRecordData data;
  final int number;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => FormCard(
    title: 'Qualification $number',
    icon: Icons.school_outlined,
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
        FormGrid(
          children: [
            DropdownButtonFormField<String>(
              initialValue: data.level,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Qualification level',
              ),
              items: _levels
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                data.level = value;
                onChanged();
              },
              validator: (value) =>
                  value == null ? 'Select qualification level' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: data.status,
              decoration: const InputDecoration(labelText: 'Study status'),
              items: const ['Completed', 'In progress', 'Awaiting result']
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                data.status = value ?? 'Completed';
                onChanged();
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedValue(data.programme),
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Programme / group'),
              items: _itemsWithCurrent(_programmes, data.programme)
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) => data.programme.text = value ?? '',
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Select programme / group'
                  : null,
            ),
            TextFormField(
              controller: data.institute,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Institute name'),
              validator: (value) => requiredText(value, 'Institute name'),
            ),
            DropdownButtonFormField<String>(
              initialValue: _selectedValue(data.board),
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Board / university',
              ),
              items: _itemsWithCurrent(_pakistanBoards, data.board)
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) => data.board.text = value ?? '',
            ),
            TextFormField(
              controller: data.registrationNumber,
              decoration: const InputDecoration(
                labelText: 'Roll / registration number',
              ),
            ),
            TextFormField(
              controller: data.completionYear,
              keyboardType: TextInputType.number,
              inputFormatters: [
                DigitsOnlyFormatter(),
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                labelText: data.status == 'Completed'
                    ? 'Completion year'
                    : 'Expected completion year',
                hintText: '2026',
              ),
              validator: _validateYear,
            ),
            TextFormField(
              controller: data.obtainedMarks,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(labelText: 'Obtained marks'),
              validator: (value) => _validateObtainedMarks(value, data),
            ),
            TextFormField(
              controller: data.totalMarks,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(labelText: 'Total marks'),
              validator: (value) => _validateTotalMarks(value, data),
            ),
            TextFormField(
              controller: data.percentage,
              readOnly: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Percentage',
                hintText: 'Auto calculated',
                suffixText: '%',
              ),
            ),
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
                  'Certificates and result cards are uploaded from Documents.',
                  style: TextStyle(color: AppColors.deepBlue, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
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

  String? _validateObtainedMarks(String? value, _EducationRecordData data) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final obtained = double.tryParse(text);
    if (obtained == null || obtained < 0) return 'Enter valid obtained marks';

    final totalText = data.totalMarks.text.trim();
    if (totalText.isEmpty) return 'Enter total marks first';
    final total = double.tryParse(totalText);
    if (total == null || total <= 0) return 'Enter valid total marks';
    if (obtained > total) {
      return 'Obtained marks cannot be greater than total marks';
    }
    return null;
  }

  String? _validateTotalMarks(String? value, _EducationRecordData data) {
    final text = value?.trim() ?? '';
    final obtainedText = data.obtainedMarks.text.trim();
    if (text.isEmpty) {
      return obtainedText.isEmpty ? null : 'Enter total marks';
    }
    final total = double.tryParse(text);
    if (total == null || total <= 0) return 'Enter valid total marks';

    final obtained = double.tryParse(obtainedText);
    if (obtained != null && obtained > total) {
      return 'Total marks must be equal to or greater than obtained marks';
    }
    return null;
  }

  String? _selectedValue(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  List<String> _itemsWithCurrent(
    List<String> options,
    TextEditingController controller,
  ) {
    final current = controller.text.trim();
    if (current.isEmpty || options.contains(current)) return options;
    return [current, ...options];
  }
}

class _EducationRecordData {
  _EducationRecordData({required this.id}) {
    obtainedMarks.addListener(_updatePercentage);
    totalMarks.addListener(_updatePercentage);
  }

  factory _EducationRecordData.fromJson({
    required int id,
    required Map<String, dynamic> json,
  }) {
    final data = _EducationRecordData(id: id);
    data.level = _stringOrNull(json['level']);
    data.status = _stringOrNull(json['status']) ?? 'Completed';
    data.programme.text = _text(json['programme']);
    data.institute.text = _text(json['institute']);
    data.board.text = _text(json['board']);
    data.registrationNumber.text = _text(json['registrationNumber']);
    data.completionYear.text = _text(json['completionYear']);
    data.totalMarks.text = _text(json['totalMarks']);
    data.obtainedMarks.text = _text(json['obtainedMarks']);
    data.percentage.text = _text(json['percentage']);
    return data;
  }

  final int id;
  String? level;
  String status = 'Completed';
  final programme = TextEditingController();
  final institute = TextEditingController();
  final board = TextEditingController();
  final registrationNumber = TextEditingController();
  final completionYear = TextEditingController();
  final totalMarks = TextEditingController();
  final obtainedMarks = TextEditingController();
  final percentage = TextEditingController();

  Map<String, dynamic> payload() => {
    'level': level,
    'programme': programme.text.trim(),
    'institute': institute.text.trim(),
    'board': board.text.trim(),
    'registrationNumber': registrationNumber.text.trim(),
    'completionYear': int.tryParse(completionYear.text),
    'totalMarks': double.tryParse(totalMarks.text),
    'obtainedMarks': double.tryParse(obtainedMarks.text),
    'percentage': double.tryParse(percentage.text),
  };

  void _updatePercentage() {
    final obtained = double.tryParse(obtainedMarks.text);
    final total = double.tryParse(totalMarks.text);
    if (obtained == null || total == null || total <= 0 || obtained > total) {
      percentage.clear();
      return;
    }
    final value = (obtained / total) * 100;
    percentage.text = value.toStringAsFixed(2);
  }

  void dispose() {
    obtainedMarks.removeListener(_updatePercentage);
    totalMarks.removeListener(_updatePercentage);
    programme.dispose();
    institute.dispose();
    board.dispose();
    registrationNumber.dispose();
    completionYear.dispose();
    totalMarks.dispose();
    obtainedMarks.dispose();
    percentage.dispose();
  }
}

const _levels = [
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

const _programmes = [
  'Science',
  'General Science',
  'Computer Science',
  'Arts / Humanities',
  'Commerce',
  'Pre-Medical',
  'Pre-Engineering',
  'ICS - Computer Science',
  'ICS - Physics',
  'ICS - Statistics',
  'I.Com',
  'FA',
  'FSc',
  'O-Level Science',
  'O-Level Commerce',
  'O-Level Humanities',
  'A-Level Science',
  'A-Level Commerce',
  'A-Level Humanities',
  'DAE - Civil Technology',
  'DAE - Electrical Technology',
  'DAE - Electronics Technology',
  'DAE - Mechanical Technology',
  'DAE - Auto & Diesel Technology',
  'DAE - Chemical Technology',
  'DAE - Computer Information Technology',
  'DAE - Architecture Technology',
  'DAE - Textile Technology',
  'Associate Degree in Arts',
  'Associate Degree in Science',
  'Associate Degree in Commerce',
  'Associate Degree in Education',
  'ADP Computer Science',
  'ADP Business Administration',
  'BS Computer Science',
  'BS Software Engineering',
  'BS Information Technology',
  'BS Data Science',
  'BS Artificial Intelligence',
  'BS Cyber Security',
  'BS Electrical Engineering',
  'BS Mechanical Engineering',
  'BS Civil Engineering',
  'BS Chemical Engineering',
  'BS Biomedical Engineering',
  'BS Architecture',
  'BBA',
  'BS Accounting & Finance',
  'BS Commerce',
  'BS Economics',
  'BS English',
  'BS Education',
  'BS Psychology',
  'BS Sociology',
  'BS Political Science',
  'BS International Relations',
  'BS Mass Communication',
  'BS Islamic Studies',
  'BS Mathematics',
  'BS Statistics',
  'BS Physics',
  'BS Chemistry',
  'BS Biology',
  'BS Botany',
  'BS Zoology',
  'BS Environmental Science',
  'BS Public Health',
  'BS Nursing',
  'Doctor of Physical Therapy',
  'Pharm-D',
  'LLB',
  'MBBS',
  'BDS',
  'BS Agriculture',
  'Doctor of Veterinary Medicine',
  'MSc',
  'MA',
  'MBA',
  'M.Com',
  'MS Computer Science',
  'MS Software Engineering',
  'MS Management Sciences',
  'MS Engineering',
  'MPhil',
  'PhD',
  'Other',
];

const _pakistanBoards = [
  'Federal Board of Intermediate and Secondary Education, Islamabad',
  'BISE Abbottabad',
  'BISE Bahawalpur',
  'BISE Bannu',
  'BISE Dera Ghazi Khan',
  'BISE Dera Ismail Khan',
  'BISE Faisalabad',
  'BISE Gujranwala',
  'BISE Hyderabad',
  'BISE Kohat',
  'BISE Lahore',
  'BISE Larkana',
  'BISE Malakand',
  'BISE Mardan',
  'BISE Mirpur AJK',
  'BISE Mirpurkhas',
  'BISE Multan',
  'BISE Peshawar',
  'BISE Quetta',
  'BISE Rawalpindi',
  'BISE Sahiwal',
  'BISE Sargodha',
  'BISE Shaheed Benazirabad',
  'BISE Sukkur',
  'BISE Swat',
  'Board of Secondary Education Karachi',
  'Board of Intermediate Education Karachi',
  'Aga Khan University Examination Board',
  'Punjab Board of Technical Education',
  'Sindh Board of Technical Education',
  'Khyber Pakhtunkhwa Board of Technical Education',
  'Balochistan Board of Technical Education',
  'Punjab University',
  'University of Karachi',
  'University of Sindh',
  'University of Peshawar',
  'University of Balochistan',
  'Allama Iqbal Open University',
  'Virtual University of Pakistan',
  'HEC-recognized university',
  'Cambridge Assessment International Education',
  'Pearson Edexcel',
  'International Baccalaureate',
  'Other',
];

String _text(Object? value) => value?.toString() ?? '';

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
