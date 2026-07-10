import 'package:flutter/material.dart';

import '../../data/pakistan_districts.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class PersonalSection extends StatefulWidget {
  const PersonalSection({
    super.key,
    required this.account,
    required this.application,
    required this.onSaved,
  });

  final Account account;
  final ScholarshipApplication? application;
  final Future<void> Function(Map<String, dynamic> payload) onSaved;

  @override
  State<PersonalSection> createState() => _PersonalSectionState();
}

class _PersonalSectionState extends State<PersonalSection>
    with AutomaticKeepAliveClientMixin {
  final _key = GlobalKey<FormState>();
  final _dob = TextEditingController();
  final _permanentAddress = TextEditingController();
  final _currentAddress = TextEditingController();
  final _disabilityDetails = TextEditingController();
  String? _gender;
  String? _marital;
  String? _domicileRegion;
  String? _domicileDistrict;
  String? _permanentRegion;
  String? _permanentDistrict;
  String? _currentRegion;
  String? _currentDistrict;
  bool _hasDisability = false;
  bool _sameAddress = true;
  bool _saving = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  @override
  void didUpdateWidget(covariant PersonalSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.application?.id != widget.application?.id) _hydrate();
  }

  @override
  void dispose() {
    _dob.dispose();
    _permanentAddress.dispose();
    _currentAddress.dispose();
    _disabilityDetails.dispose();
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
                  eyebrow: 'Your profile',
                  title: 'Personal information',
                  description:
                      'Your account identity is secured. Complete the remaining profile and address information below.',
                ),
                const SizedBox(height: 24),
                FormCard(
                  title: 'Account identity',
                  icon: Icons.lock_person_outlined,
                  child: FormGrid(
                    children: [
                      _LockedField(
                        label: 'Full name',
                        value: widget.account.fullName,
                      ),
                      _LockedField(label: 'CNIC', value: widget.account.cnic),
                      _LockedField(label: 'Email', value: widget.account.email),
                      _LockedField(label: 'Phone', value: widget.account.phone),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FormCard(
                  title: 'Personal details',
                  icon: Icons.person_outline_rounded,
                  child: FormGrid(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender / sex',
                        ),
                        items: const ['Male', 'Female', 'Other']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _gender = value),
                        validator: (value) =>
                            value == null ? 'Select an option' : null,
                      ),
                      TextFormField(
                        controller: _dob,
                        readOnly: true,
                        onTap: _selectDob,
                        decoration: const InputDecoration(
                          labelText: 'Date of birth',
                          hintText: 'DD/MM/YYYY',
                          suffixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        validator: (value) =>
                            requiredText(value, 'Date of birth'),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _marital,
                        decoration: const InputDecoration(
                          labelText: 'Marital status',
                        ),
                        items:
                            const ['Single', 'Married', 'Divorced', 'Widowed']
                                .map(
                                  (value) => DropdownMenuItem(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) => setState(() => _marital = value),
                      ),
                      SwitchListTile(
                        value: _hasDisability,
                        onChanged: (value) =>
                            setState(() => _hasDisability = value),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Has disability'),
                      ),
                      TextFormField(
                        controller: _disabilityDetails,
                        enabled: _hasDisability,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Disability details',
                          hintText: 'Optional',
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _domicileRegion,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Domicile province / territory',
                        ),
                        items: _regionItems(),
                        onChanged: (value) => setState(() {
                          _domicileRegion = value;
                          _domicileDistrict = null;
                        }),
                        validator: (value) => value == null
                            ? 'Select a province / territory'
                            : null,
                      ),
                      DropdownButtonFormField<String>(
                        key: ValueKey('domicile-$_domicileRegion'),
                        initialValue: _domicileDistrict,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Domicile district',
                        ),
                        items: _districtItems(_domicileRegion),
                        onChanged: _domicileRegion == null
                            ? null
                            : (value) =>
                                  setState(() => _domicileDistrict = value),
                        validator: (value) => value == null
                            ? 'Select your domicile district'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FormCard(
                  title: 'Permanent address',
                  icon: Icons.home_outlined,
                  child: _addressFields(
                    controller: _permanentAddress,
                    region: _permanentRegion,
                    district: _permanentDistrict,
                    onRegionChanged: (value) => setState(() {
                      _permanentRegion = value;
                      _permanentDistrict = null;
                    }),
                    onDistrictChanged: (value) =>
                        setState(() => _permanentDistrict = value),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: CheckboxListTile(
                    value: _sameAddress,
                    onChanged: (value) =>
                        setState(() => _sameAddress = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text(
                      'Current address is the same as permanent address',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                if (!_sameAddress) ...[
                  const SizedBox(height: 18),
                  FormCard(
                    title: 'Current address',
                    icon: Icons.location_on_outlined,
                    child: _addressFields(
                      controller: _currentAddress,
                      region: _currentRegion,
                      district: _currentDistrict,
                      onRegionChanged: (value) => setState(() {
                        _currentRegion = value;
                        _currentDistrict = null;
                      }),
                      onDistrictChanged: (value) =>
                          setState(() => _currentDistrict = value),
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
                      label: _saving ? 'Saving...' : 'Save profile',
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

  Widget _addressFields({
    required TextEditingController controller,
    required String? region,
    required String? district,
    required ValueChanged<String?> onRegionChanged,
    required ValueChanged<String?> onDistrictChanged,
  }) => Column(
    children: [
      TextFormField(
        controller: controller,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Full address',
          hintText: 'House, street, area, city and postal code',
        ),
        validator: (value) => requiredText(value, 'Full address'),
      ),
      const SizedBox(height: 16),
      FormGrid(
        children: [
          DropdownButtonFormField<String>(
            initialValue: region,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Province / territory',
            ),
            items: _regionItems(),
            onChanged: onRegionChanged,
            validator: (value) =>
                value == null ? 'Select a province / territory' : null,
          ),
          DropdownButtonFormField<String>(
            key: ValueKey('address-district-$region'),
            initialValue: district,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'District'),
            items: _districtItems(region),
            onChanged: region == null ? null : onDistrictChanged,
            validator: (value) => value == null ? 'Select a district' : null,
          ),
        ],
      ),
    ],
  );

  List<DropdownMenuItem<String>> _regionItems() => pakistanRegions
      .map(
        (region) => DropdownMenuItem(
          value: region,
          child: Text(region, overflow: TextOverflow.ellipsis),
        ),
      )
      .toList();

  List<DropdownMenuItem<String>> _districtItems(String? region) =>
      (pakistanDistricts[region] ?? const <String>[])
          .map(
            (district) => DropdownMenuItem(
              value: district,
              child: Text(district, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList();

  Future<void> _selectDob() async {
    final initial = parseAppDate(_dob.text) ?? DateTime(2000);
    final date = await pickAppDate(context, initial: initial);
    if (date != null) _dob.text = formatDate(date);
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final dob = parseAppDate(_dob.text);
      final currentRegion = _sameAddress ? _permanentRegion : _currentRegion;
      final currentDistrict = _sameAddress
          ? _permanentDistrict
          : _currentDistrict;
      final currentAddress = _sameAddress
          ? _permanentAddress.text
          : _currentAddress.text;
      await widget.onSaved({
        'dateOfBirth': dob?.toIso8601String(),
        'gender': _gender?.toLowerCase(),
        'maritalStatus': _marital,
        'hasDisability': _hasDisability,
        'disabilityDetails': _hasDisability
            ? _disabilityDetails.text.trim()
            : '',
        'domicileProvince': _domicileRegion,
        'domicileDistrict': _domicileDistrict,
        'permanentAddress': {
          'province': _permanentRegion,
          'district': _permanentDistrict,
          'fullAddress': _permanentAddress.text.trim(),
        },
        'currentAddress': {
          'province': currentRegion,
          'district': currentDistrict,
          'fullAddress': currentAddress.trim(),
        },
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _hydrate() {
    final personal = widget.application?.personal ?? const {};
    final permanent = _asMap(personal['permanentAddress']);
    final current = _asMap(personal['currentAddress']);
    _dob.text = formatBackendDate(personal['dateOfBirth']);
    _gender = _label(personal['gender']);
    _marital = _stringOrNull(personal['maritalStatus']);
    _hasDisability = personal['hasDisability'] == true;
    _disabilityDetails.text =
        _stringOrNull(personal['disabilityDetails']) ?? '';
    _domicileRegion = _stringOrNull(personal['domicileProvince']);
    _domicileDistrict = _stringOrNull(personal['domicileDistrict']);
    _permanentRegion = _stringOrNull(permanent['province']);
    _permanentDistrict = _stringOrNull(permanent['district']);
    _permanentAddress.text = _stringOrNull(permanent['fullAddress']) ?? '';
    _currentRegion = _stringOrNull(current['province']);
    _currentDistrict = _stringOrNull(current['district']);
    _currentAddress.text = _stringOrNull(current['fullAddress']) ?? '';
    _sameAddress =
        _currentAddress.text.isEmpty ||
        (_currentAddress.text == _permanentAddress.text &&
            _currentRegion == _permanentRegion &&
            _currentDistrict == _permanentDistrict);
  }
}

class _LockedField extends StatelessWidget {
  const _LockedField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: value,
    readOnly: true,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
    ),
  );
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String? _label(Object? value) {
  final text = _stringOrNull(value);
  if (text == null) return null;
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}
