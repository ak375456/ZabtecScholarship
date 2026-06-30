import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/demo_profile.dart';
import '../../data/pakistan_districts.dart';
import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class PersonalSection extends StatefulWidget {
  const PersonalSection({
    super.key,
    required this.account,
    required this.onSaved,
  });

  final Account account;
  final VoidCallback onSaved;

  @override
  State<PersonalSection> createState() => _PersonalSectionState();
}

class _PersonalSectionState extends State<PersonalSection>
    with AutomaticKeepAliveClientMixin {
  final _key = GlobalKey<FormState>();
  final _dob = TextEditingController();
  String? _gender;
  String? _marital;
  String? _domicileRegion;
  String? _domicileDistrict;
  String? _permanentRegion;
  String? _permanentDistrict;
  String? _currentRegion;
  String? _currentDistrict;
  String? _disability;
  bool _sameAddress = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!DemoProfile.enabled) return;
    _gender = DemoProfile.gender;
    _dob.text = DemoProfile.dob;
    _marital = DemoProfile.maritalStatus;
    _disability = DemoProfile.disabilityStatus;
    _domicileRegion = DemoProfile.domicileRegion;
    _domicileDistrict = DemoProfile.domicileDistrict;
    _permanentRegion = DemoProfile.permanentRegion;
    _permanentDistrict = DemoProfile.permanentDistrict;
    _currentRegion = DemoProfile.currentRegion;
    _currentDistrict = DemoProfile.currentDistrict;
  }

  @override
  void dispose() {
    _dob.dispose();
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
                      'Account identity is locked. Complete the remaining profile and address information below.',
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
                        items: ['Male', 'Female', 'Other', 'Prefer not to say']
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _gender = v),
                        validator: (v) => v == null ? 'Select an option' : null,
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
                        validator: (v) => requiredText(v, 'Date of birth'),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _marital,
                        decoration: const InputDecoration(
                          labelText: 'Marital status',
                        ),
                        items: ['Single', 'Married', 'Divorced', 'Widowed']
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _marital = v),
                        validator: (v) => v == null ? 'Select an option' : null,
                      ),
                      TextFormField(
                        initialValue: 'Pakistani',
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Nationality',
                        ),
                      ),
                      TextFormField(
                        initialValue: '',
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Other nationality (optional)',
                          hintText: 'Only if you hold dual nationality',
                        ),
                      ),
                      TextFormField(
                        initialValue: '',
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [LengthLimitingTextInputFormatter(20)],
                        decoration: const InputDecoration(
                          labelText: 'Passport number (optional)',
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _disability,
                        decoration: const InputDecoration(
                          labelText: 'Disability status',
                        ),
                        isExpanded: true,
                        items:
                            [
                                  'No disability',
                                  'Yes — physical',
                                  'Yes — visual',
                                  'Yes — hearing',
                                  'Yes — other',
                                ]
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) => setState(() => _disability = v),
                        validator: (v) => v == null ? 'Select an option' : null,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: _domicileRegion,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Domicile province / territory',
                        ),
                        items: _regionItems(),
                        onChanged: (v) => setState(() {
                          _domicileRegion = v;
                          _domicileDistrict = null;
                        }),
                        validator: (v) =>
                            v == null ? 'Select a province / territory' : null,
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
                            : (v) => setState(() => _domicileDistrict = v),
                        validator: (v) =>
                            v == null ? 'Select your domicile district' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FormCard(
                  title: 'Permanent address',
                  icon: Icons.home_outlined,
                  child: _addressFields(
                    keyPrefix: 'permanent',
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
                    subtitle: const Text(
                      'Untick this if you currently live somewhere else.',
                    ),
                  ),
                ),
                if (!_sameAddress) ...[
                  const SizedBox(height: 18),
                  FormCard(
                    title: 'Current address',
                    icon: Icons.location_on_outlined,
                    child: _addressFields(
                      keyPrefix: 'current',
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
                      label: 'Save profile',
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

  Widget _addressFields({
    required String keyPrefix,
    required String? region,
    required String? district,
    required ValueChanged<String?> onRegionChanged,
    required ValueChanged<String?> onDistrictChanged,
  }) => Column(
    children: [
      TextFormField(
        key: ValueKey('$keyPrefix-street'),
        initialValue: _demoAddressValue(keyPrefix, 'street'),
        maxLines: 2,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Street address',
          hintText: 'House, street and area',
        ),
        validator: (v) => requiredText(v, 'Street address'),
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
            validator: (v) =>
                v == null ? 'Select a province / territory' : null,
          ),
          DropdownButtonFormField<String>(
            key: ValueKey('$keyPrefix-district-$region'),
            initialValue: district,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'District'),
            items: _districtItems(region),
            onChanged: region == null ? null : onDistrictChanged,
            validator: (v) => v == null ? 'Select a district' : null,
          ),
          TextFormField(
            key: ValueKey('$keyPrefix-city'),
            initialValue: _demoAddressValue(keyPrefix, 'city'),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'City'),
            validator: (v) => requiredText(v, 'City'),
          ),
          TextFormField(
            key: ValueKey('$keyPrefix-postal'),
            initialValue: _demoAddressValue(keyPrefix, 'postal'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              DigitsOnlyFormatter(),
              LengthLimitingTextInputFormatter(5),
            ],
            decoration: const InputDecoration(labelText: 'Postal code'),
            validator: (v) => requiredText(v, 'Postal code'),
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
    final date = await pickAppDate(context);
    if (date != null) _dob.text = formatDate(date);
  }

  void _save() {
    if (_key.currentState!.validate()) widget.onSaved();
  }

  String? _demoAddressValue(String prefix, String field) {
    if (!DemoProfile.enabled) return null;
    return switch ((prefix, field)) {
      ('permanent', 'street') => DemoProfile.permanentStreet,
      ('permanent', 'city') => DemoProfile.permanentCity,
      ('permanent', 'postal') => DemoProfile.permanentPostalCode,
      ('current', 'street') => DemoProfile.currentStreet,
      ('current', 'city') => DemoProfile.currentCity,
      ('current', 'postal') => DemoProfile.currentPostalCode,
      _ => null,
    };
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
