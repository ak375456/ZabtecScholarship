import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models.dart';
import '../../widgets/common.dart';

class FamilySection extends StatefulWidget {
  const FamilySection({
    super.key,
    required this.application,
    required this.onSaved,
  });

  final ScholarshipApplication? application;
  final Future<void> Function(Map<String, dynamic> payload) onSaved;

  @override
  State<FamilySection> createState() => _FamilySectionState();
}

class _FamilySectionState extends State<FamilySection>
    with AutomaticKeepAliveClientMixin {
  final _key = GlobalKey<FormState>();
  final _father = _ParentControllers();
  final _mother = _ParentControllers();
  final _guardian = _ParentControllers(requiredName: false);
  final _householdMembers = TextEditingController();
  final _dependents = TextEditingController();
  final _studentsInFamily = TextEditingController();
  final _circumstances = TextEditingController();
  bool _saving = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  @override
  void didUpdateWidget(covariant FamilySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.application?.id != widget.application?.id) _hydrate();
  }

  @override
  void dispose() {
    _father.dispose();
    _mother.dispose();
    _guardian.dispose();
    _householdMembers.dispose();
    _dependents.dispose();
    _studentsInFamily.dispose();
    _circumstances.dispose();
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
                  eyebrow: 'Household profile',
                  title: 'Family details',
                  description:
                      'Household information helps assess financial need fairly and consistently.',
                ),
                const SizedBox(height: 24),
                _ParentCard(title: 'Father information', controllers: _father),
                const SizedBox(height: 18),
                _ParentCard(title: 'Mother information', controllers: _mother),
                const SizedBox(height: 18),
                _ParentCard(
                  title: 'Guardian (if applicable)',
                  controllers: _guardian,
                  optional: true,
                ),
                const SizedBox(height: 18),
                FormCard(
                  title: 'Household & financial information',
                  icon: Icons.account_balance_wallet_outlined,
                  child: FormGrid(
                    children: [
                      _numberField(
                        controller: _householdMembers,
                        label: 'Total household members',
                        required: true,
                      ),
                      _numberField(
                        controller: _dependents,
                        label: 'Dependent family members',
                      ),
                      _numberField(
                        controller: _studentsInFamily,
                        label: 'Students in household',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FormCard(
                  title: 'Additional circumstances',
                  icon: Icons.notes_rounded,
                  child: TextFormField(
                    controller: _circumstances,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText:
                          'Anything the selection team should know? (optional)',
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
                      label: _saving ? 'Saving...' : 'Save family',
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

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    bool required = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [DigitsOnlyFormatter()],
    decoration: InputDecoration(labelText: label),
    validator: required ? (value) => requiredText(value, label) : null,
  );

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSaved({
        'father': _father.payload(),
        'mother': _mother.payload(),
        'guardian': _guardian.payload(includeEmpty: false),
        'householdMembers': int.tryParse(_householdMembers.text) ?? 0,
        'dependents': int.tryParse(_dependents.text) ?? 0,
        'studentsInFamily': int.tryParse(_studentsInFamily.text) ?? 0,
        'familyCircumstances': _circumstances.text.trim(),
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _hydrate() {
    final family = widget.application?.family ?? const {};
    _father.hydrate(_asMap(family['father']));
    _mother.hydrate(_asMap(family['mother']));
    _guardian.hydrate(_asMap(family['guardian']));
    _householdMembers.text = _text(family['householdMembers']);
    _dependents.text = _text(family['dependents']);
    _studentsInFamily.text = _text(family['studentsInFamily']);
    _circumstances.text = _text(family['familyCircumstances']);
  }
}

class _ParentCard extends StatelessWidget {
  const _ParentCard({
    required this.title,
    required this.controllers,
    this.optional = false,
  });

  final String title;
  final _ParentControllers controllers;
  final bool optional;

  @override
  Widget build(BuildContext context) => FormCard(
    title: title,
    icon: Icons.family_restroom_rounded,
    child: FormGrid(
      children: [
        TextFormField(
          controller: controllers.name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: optional ? 'Full name (optional)' : 'Full name',
          ),
          validator: optional
              ? null
              : (value) => requiredText(value, 'Full name'),
        ),
        TextFormField(
          controller: controllers.cnic,
          keyboardType: TextInputType.number,
          inputFormatters: [
            DigitsOnlyFormatter(),
            LengthLimitingTextInputFormatter(13),
          ],
          decoration: const InputDecoration(
            labelText: 'CNIC',
            hintText: '13 digits',
          ),
          validator: (value) =>
              value != null && value.isNotEmpty ? validateCnic(value) : null,
        ),
        TextFormField(
          controller: controllers.dateOfBirth,
          readOnly: true,
          onTap: () async {
            final date = await pickAppDate(
              context,
              initial:
                  parseAppDate(controllers.dateOfBirth.text) ?? DateTime(1970),
            );
            if (date != null) controllers.dateOfBirth.text = formatDate(date);
          },
          decoration: const InputDecoration(
            labelText: 'Date of birth',
            suffixIcon: Icon(Icons.calendar_today_outlined),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: controllers.education,
          decoration: const InputDecoration(labelText: 'Highest education'),
          isExpanded: true,
          items: _educationLevels
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) => controllers.education = value,
        ),
        TextFormField(
          controller: controllers.occupation,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Occupation'),
        ),
        TextFormField(
          controller: controllers.monthlyIncome,
          keyboardType: TextInputType.number,
          inputFormatters: [DigitsOnlyFormatter()],
          decoration: const InputDecoration(
            labelText: 'Monthly income',
            prefixText: 'PKR  ',
          ),
        ),
      ],
    ),
  );
}

class _ParentControllers {
  _ParentControllers({this.requiredName = true});

  final bool requiredName;
  final name = TextEditingController();
  final cnic = TextEditingController();
  final dateOfBirth = TextEditingController();
  final occupation = TextEditingController();
  final monthlyIncome = TextEditingController();
  String? education;

  void hydrate(Map<String, dynamic> json) {
    name.text = _text(json['name']);
    cnic.text = _text(json['cnic']);
    dateOfBirth.text = formatBackendDate(json['dateOfBirth']);
    education = _stringOrNull(json['education']);
    occupation.text = _text(json['occupation']);
    monthlyIncome.text = _text(json['monthlyIncome']);
  }

  Map<String, dynamic> payload({bool includeEmpty = true}) {
    final data = {
      'name': name.text.trim(),
      'cnic': cnic.text.trim(),
      'dateOfBirth': parseAppDate(dateOfBirth.text)?.toIso8601String(),
      'education': education,
      'occupation': occupation.text.trim(),
      'monthlyIncome': int.tryParse(monthlyIncome.text) ?? 0,
    };
    if (includeEmpty || data.values.any((value) => _text(value).isNotEmpty)) {
      return data;
    }
    return {};
  }

  void dispose() {
    name.dispose();
    cnic.dispose();
    dateOfBirth.dispose();
    occupation.dispose();
    monthlyIncome.dispose();
  }
}

const _educationLevels = [
  'No formal education',
  'Primary',
  'Middle',
  'Matric / O-Level',
  'Intermediate / A-Level',
  'Bachelor’s',
  'Master’s or higher',
];

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
