import 'package:flutter/material.dart';

import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ExperienceSection extends StatefulWidget {
  const ExperienceSection({
    super.key,
    required this.application,
    required this.onSaved,
  });

  final ScholarshipApplication? application;
  final Future<void> Function(Map<String, dynamic> payload) onSaved;

  @override
  State<ExperienceSection> createState() => _ExperienceSectionState();
}

class _ExperienceSectionState extends State<ExperienceSection>
    with AutomaticKeepAliveClientMixin {
  final _key = GlobalKey<FormState>();
  final List<_ExperienceRecordData> _records = [];
  int _nextId = 0;
  bool? _hasExperience;
  bool _saving = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  @override
  void didUpdateWidget(covariant ExperienceSection oldWidget) {
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
                        onSelectionChanged: (value) => setState(() {
                          _hasExperience = value.first;
                          if (_hasExperience == true && _records.isEmpty) {
                            _addRecord();
                          }
                        }),
                      ),
                    ],
                  ),
                ),
                if (_hasExperience == true) ...[
                  const SizedBox(height: 18),
                  for (var index = 0; index < _records.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _ExperienceRecord(
                        key: ValueKey(_records[index].id),
                        data: _records[index],
                        number: index + 1,
                        canRemove: _records.length > 1,
                        onRemove: () => _removeRecord(index),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _records.length >= 6 ? null : _addRecord,
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
                            'Experience is optional. This declaration will still be saved.',
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
                      label: _saving ? 'Saving...' : 'Save experience',
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
    setState(() => _records.add(_ExperienceRecordData(id: _nextId++)));
  }

  void _removeRecord(int index) {
    final removed = _records.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    if (_hasExperience == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Yes or Not yet.')),
      );
      return;
    }
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSaved({
        'hasExperience': _hasExperience,
        'entries': _hasExperience == true
            ? _records.map((record) => record.payload()).toList()
            : <Map<String, dynamic>>[],
      });
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
    final experience = widget.application?.experience ?? const {};
    _hasExperience = experience['hasExperience'] is bool
        ? experience['hasExperience'] as bool
        : null;
    final entries = experience['entries'] is List
        ? experience['entries'] as List
        : const [];
    for (final entry in entries) {
      _records.add(
        _ExperienceRecordData.fromJson(id: _nextId++, json: _asMap(entry)),
      );
    }
    if (_hasExperience == true && _records.isEmpty) {
      _records.add(_ExperienceRecordData(id: _nextId++));
    }
  }
}

class _ExperienceRecord extends StatefulWidget {
  const _ExperienceRecord({
    super.key,
    required this.data,
    required this.number,
    required this.canRemove,
    required this.onRemove,
  });

  final _ExperienceRecordData data;
  final int number;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  State<_ExperienceRecord> createState() => _ExperienceRecordState();
}

class _ExperienceRecordState extends State<_ExperienceRecord> {
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
              controller: widget.data.organization,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Organization'),
              validator: (value) => requiredText(value, 'Organization'),
            ),
            TextFormField(
              controller: widget.data.role,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Role / title'),
              validator: (value) => requiredText(value, 'Role / title'),
            ),
            DropdownButtonFormField<String>(
              initialValue: widget.data.type,
              decoration: const InputDecoration(labelText: 'Experience type'),
              items: _types.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: (value) => widget.data.type = value,
              validator: (value) =>
                  value == null ? 'Select experience type' : null,
            ),
            TextFormField(
              controller: widget.data.startDate,
              decoration: const InputDecoration(
                labelText: 'Start date',
                hintText: 'MM/YYYY',
              ),
              validator: (value) => requiredText(value, 'Start date'),
            ),
            if (!widget.data.isCurrent)
              TextFormField(
                controller: widget.data.endDate,
                decoration: const InputDecoration(
                  labelText: 'End date',
                  hintText: 'MM/YYYY',
                ),
                validator: (value) => requiredText(value, 'End date'),
              ),
          ],
        ),
        CheckboxListTile(
          value: widget.data.isCurrent,
          onChanged: (value) =>
              setState(() => widget.data.isCurrent = value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text('I currently work here'),
        ),
        TextFormField(
          controller: widget.data.description,
          minLines: 3,
          maxLines: 5,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Responsibilities and achievements',
          ),
          validator: (value) => requiredText(value, 'Experience description'),
        ),
      ],
    ),
  );
}

class _ExperienceRecordData {
  _ExperienceRecordData({required this.id});

  factory _ExperienceRecordData.fromJson({
    required int id,
    required Map<String, dynamic> json,
  }) {
    final data = _ExperienceRecordData(id: id);
    data.organization.text = _text(json['organization']);
    data.role.text = _text(json['role']);
    data.type = _stringOrNull(json['type']);
    data.startDate.text = _monthYear(json['startDate']);
    data.endDate.text = _monthYear(json['endDate']);
    data.isCurrent = json['isCurrent'] == true;
    data.description.text = _text(json['description']);
    return data;
  }

  final int id;
  final organization = TextEditingController();
  final role = TextEditingController();
  final startDate = TextEditingController();
  final endDate = TextEditingController();
  final description = TextEditingController();
  String? type;
  bool isCurrent = false;

  Map<String, dynamic> payload() => {
    'organization': organization.text.trim(),
    'role': role.text.trim(),
    'type': type,
    'startDate': _parseMonthYear(startDate.text)?.toIso8601String(),
    'endDate': isCurrent
        ? null
        : _parseMonthYear(endDate.text)?.toIso8601String(),
    'isCurrent': isCurrent,
    'description': description.text.trim(),
  };

  void dispose() {
    organization.dispose();
    role.dispose();
    startDate.dispose();
    endDate.dispose();
    description.dispose();
  }
}

const _types = {
  'work': 'Employment',
  'internship': 'Internship',
  'volunteer': 'Volunteer work',
  'freelance': 'Freelance',
  'leadership': 'Leadership',
  'other': 'Other',
};

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

String _text(Object? value) => value?.toString() ?? '';

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _parseMonthYear(String value) {
  final match = RegExp(r'^(\d{1,2})/(\d{4})$').firstMatch(value.trim());
  if (match == null) return DateTime.tryParse(value);
  final month = int.tryParse(match.group(1)!);
  final year = int.tryParse(match.group(2)!);
  if (month == null || year == null || month < 1 || month > 12) return null;
  return DateTime(year, month);
}

String _monthYear(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return '';
  return '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
