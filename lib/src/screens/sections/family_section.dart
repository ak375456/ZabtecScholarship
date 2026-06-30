import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/demo_profile.dart';
import '../../widgets/common.dart';

class FamilySection extends StatefulWidget {
  const FamilySection({super.key, required this.onSaved});
  final VoidCallback onSaved;

  @override
  State<FamilySection> createState() => _FamilySectionState();
}

class _FamilySectionState extends State<FamilySection>
    with AutomaticKeepAliveClientMixin {
  final _key = GlobalKey<FormState>();
  final _fatherDob = TextEditingController();
  final _motherDob = TextEditingController();
  String _fatherStatus = 'Alive';
  String _motherStatus = 'Alive';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!DemoProfile.enabled) return;
    _fatherDob.text = DemoProfile.father.dob;
    _motherDob.text = DemoProfile.mother.dob;
  }

  @override
  void dispose() {
    _fatherDob.dispose();
    _motherDob.dispose();
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
                _ParentCard(
                  title: 'Father’s information',
                  icon: Icons.man_rounded,
                  status: _fatherStatus,
                  dobController: _fatherDob,
                  demoParent: DemoProfile.enabled ? DemoProfile.father : null,
                  onStatusChanged: (v) => setState(() => _fatherStatus = v!),
                  onPickDate: () => _pickDate(_fatherDob),
                ),
                const SizedBox(height: 18),
                _ParentCard(
                  title: 'Mother’s information',
                  icon: Icons.woman_rounded,
                  status: _motherStatus,
                  dobController: _motherDob,
                  demoParent: DemoProfile.enabled ? DemoProfile.mother : null,
                  onStatusChanged: (v) => setState(() => _motherStatus = v!),
                  onPickDate: () => _pickDate(_motherDob),
                ),
                const SizedBox(height: 18),
                FormCard(
                  title: 'Guardian (if applicable)',
                  icon: Icons.supervisor_account_outlined,
                  child: FormGrid(
                    children: [
                      TextFormField(
                        initialValue: DemoProfile.enabled
                            ? DemoProfile.guardianName
                            : null,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Guardian full name',
                          hintText: 'Optional',
                        ),
                      ),
                      TextFormField(
                        initialValue: DemoProfile.enabled
                            ? DemoProfile.guardianRelationship
                            : null,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Relationship',
                          hintText: 'e.g. Uncle',
                        ),
                      ),
                      TextFormField(
                        initialValue: DemoProfile.enabled
                            ? DemoProfile.guardianCnic
                            : null,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          DigitsOnlyFormatter(),
                          LengthLimitingTextInputFormatter(13),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Guardian CNIC',
                          hintText: '13 digits',
                        ),
                        validator: (v) =>
                            v != null && v.isNotEmpty ? validateCnic(v) : null,
                      ),
                      TextFormField(
                        initialValue: DemoProfile.enabled
                            ? DemoProfile.guardianPhone
                            : null,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          DigitsOnlyFormatter(),
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Guardian phone',
                          prefixText: '+92  ',
                          hintText: '3XX XXXXXXX',
                        ),
                        validator: (v) => v != null && v.isNotEmpty
                            ? validatePakPhone(v)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FormCard(
                  title: 'Household & financial information',
                  icon: Icons.account_balance_wallet_outlined,
                  child: FormGrid(
                    children: [
                      TextFormField(
                        initialValue: DemoProfile.enabled
                            ? DemoProfile.householdMembers
                            : null,
                        keyboardType: TextInputType.number,
                        inputFormatters: [DigitsOnlyFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Total household members',
                          hintText: 'Including applicant',
                        ),
                        validator: (v) => requiredText(v, 'Household members'),
                      ),
                      TextFormField(
                        initialValue: DemoProfile.enabled
                            ? DemoProfile.dependentMembers
                            : null,
                        keyboardType: TextInputType.number,
                        inputFormatters: [DigitsOnlyFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Dependent family members',
                        ),
                        validator: (v) => requiredText(v, 'Dependent members'),
                      ),
                      TextFormField(
                        initialValue: DemoProfile.enabled
                            ? DemoProfile.studentsInHousehold
                            : null,
                        keyboardType: TextInputType.number,
                        inputFormatters: [DigitsOnlyFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Students in household',
                        ),
                        validator: (v) =>
                            requiredText(v, 'Students in household'),
                      ),
                      TextFormField(
                        initialValue: DemoProfile.enabled
                            ? DemoProfile.householdIncome
                            : null,
                        keyboardType: TextInputType.number,
                        inputFormatters: [DigitsOnlyFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Total monthly household income',
                          prefixText: 'PKR  ',
                        ),
                        validator: (v) => requiredText(v, 'Monthly income'),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: DemoProfile.enabled
                            ? DemoProfile.housingStatus
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Housing status',
                        ),
                        items:
                            [
                                  'Owned',
                                  'Rented',
                                  'Employer provided',
                                  'Shared / family owned',
                                  'Other',
                                ]
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v),
                                  ),
                                )
                                .toList(),
                        onChanged: (_) {},
                        validator: (v) =>
                            v == null ? 'Select housing status' : null,
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: DemoProfile.enabled
                            ? DemoProfile.incomeSource
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Primary income source',
                        ),
                        isExpanded: true,
                        items:
                            [
                                  'Salary',
                                  'Business',
                                  'Agriculture',
                                  'Daily wage',
                                  'Pension',
                                  'Remittance',
                                  'Other',
                                ]
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v),
                                  ),
                                )
                                .toList(),
                        onChanged: (_) {},
                        validator: (v) =>
                            v == null ? 'Select an income source' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FormCard(
                  title: 'Additional circumstances',
                  icon: Icons.notes_rounded,
                  child: TextFormField(
                    initialValue: DemoProfile.enabled
                        ? DemoProfile.familyCircumstances
                        : null,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText:
                          'Anything the selection team should know? (optional)',
                      hintText:
                          'Medical expenses, loss of income, special dependents, or other circumstances',
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
                      label: 'Save & continue',
                      icon: Icons.arrow_forward_rounded,
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

  Future<void> _pickDate(TextEditingController controller) async {
    final date = await pickAppDate(context, initial: DateTime(1970));
    if (date != null) controller.text = formatDate(date);
  }

  void _save() {
    if (_key.currentState!.validate()) widget.onSaved();
  }
}

class _ParentCard extends StatelessWidget {
  const _ParentCard({
    required this.title,
    required this.icon,
    required this.status,
    required this.dobController,
    required this.demoParent,
    required this.onStatusChanged,
    required this.onPickDate,
  });
  final String title;
  final IconData icon;
  final String status;
  final TextEditingController dobController;
  final DemoParent? demoParent;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) => FormCard(
    title: title,
    icon: icon,
    child: FormGrid(
      children: [
        TextFormField(
          initialValue: demoParent?.fullName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Full name',
            hintText: 'As shown on CNIC',
          ),
          validator: (v) => requiredText(v, 'Full name'),
        ),
        DropdownButtonFormField<String>(
          initialValue: status,
          decoration: const InputDecoration(labelText: 'Life status'),
          items: [
            'Alive',
            'Deceased',
            'Unknown',
          ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
          onChanged: onStatusChanged,
        ),
        TextFormField(
          initialValue: demoParent?.cnic,
          keyboardType: TextInputType.number,
          inputFormatters: [
            DigitsOnlyFormatter(),
            LengthLimitingTextInputFormatter(13),
          ],
          decoration: InputDecoration(
            labelText: 'CNIC',
            hintText: 'Optional — 13 digits',
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty) return validateCnic(value);
            return null;
          },
        ),
        TextFormField(
          controller: dobController,
          readOnly: true,
          onTap: onPickDate,
          decoration: const InputDecoration(
            labelText: 'Date of birth',
            suffixIcon: Icon(Icons.calendar_today_outlined),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: demoParent?.education,
          decoration: const InputDecoration(labelText: 'Highest education'),
          isExpanded: true,
          items:
              [
                    'No formal education',
                    'Primary',
                    'Middle',
                    'Matric / O-Level',
                    'Intermediate / A-Level',
                    'Bachelor’s',
                    'Master’s or higher',
                  ]
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
          onChanged: (_) {},
          validator: (v) => v == null ? 'Select education level' : null,
        ),
        TextFormField(
          initialValue: demoParent?.occupation,
          enabled: status == 'Alive',
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Occupation',
            hintText: 'Current occupation',
          ),
          validator: status == 'Alive'
              ? (v) => requiredText(v, 'Occupation')
              : null,
        ),
        TextFormField(
          initialValue: demoParent?.monthlyIncome,
          enabled: status == 'Alive',
          keyboardType: TextInputType.number,
          inputFormatters: [DigitsOnlyFormatter()],
          decoration: const InputDecoration(
            labelText: 'Monthly income',
            prefixText: 'PKR  ',
          ),
          validator: status == 'Alive'
              ? (v) => requiredText(v, 'Monthly income')
              : null,
        ),
        TextFormField(
          initialValue: demoParent?.phone,
          enabled: status == 'Alive',
          keyboardType: TextInputType.phone,
          inputFormatters: [
            DigitsOnlyFormatter(),
            LengthLimitingTextInputFormatter(10),
          ],
          decoration: const InputDecoration(
            labelText: 'Phone number (optional)',
            prefixText: '+92  ',
            hintText: '3XX XXXXXXX',
          ),
          validator: (v) =>
              v != null && v.isNotEmpty ? validatePakPhone(v) : null,
        ),
      ],
    ),
  );
}
