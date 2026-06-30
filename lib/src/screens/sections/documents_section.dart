import 'package:flutter/material.dart';

import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/document_image_field.dart';

class DocumentsSection extends StatefulWidget {
  const DocumentsSection({
    super.key,
    required this.educationRequirements,
    required this.onSaved,
  });

  final List<EducationDocumentRequirement> educationRequirements;
  final VoidCallback onSaved;

  @override
  State<DocumentsSection> createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends State<DocumentsSection>
    with AutomaticKeepAliveClientMixin {
  final _key = GlobalKey<FormState>();
  final Set<int> _certificatePending = {};

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
                  eyebrow: 'Uploads',
                  title: 'Documents',
                  description:
                      'Keep identity, education and supporting images together in one secure place.',
                ),
                const SizedBox(height: 24),
                const FormCard(
                  title: 'Identity documents',
                  icon: Icons.badge_outlined,
                  child: Column(
                    children: [
                      DocumentImageField(
                        title: 'Applicant photograph',
                        description: 'Recent passport-style picture',
                        requiredDocument: true,
                      ),
                      SizedBox(height: 12),
                      DocumentImageField(
                        title: 'CNIC front',
                        description: 'Required',
                        requiredDocument: true,
                      ),
                      SizedBox(height: 12),
                      DocumentImageField(
                        title: 'CNIC back',
                        description: 'Required',
                        requiredDocument: true,
                      ),
                      SizedBox(height: 12),
                      DocumentImageField(
                        title: 'Domicile certificate',
                        description: 'Optional — add if available',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FormCard(
                  title: 'Education documents',
                  icon: Icons.school_outlined,
                  child: widget.educationRequirements.isEmpty
                      ? const _EducationDocumentEmptyState()
                      : Column(
                          children: widget.educationRequirements
                              .map(_educationDocumentGroup)
                              .toList(),
                        ),
                ),
                const SizedBox(height: 18),
                const FormCard(
                  title: 'Optional supporting documents',
                  icon: Icons.folder_copy_outlined,
                  child: Column(
                    children: [
                      DocumentImageField(
                        title: 'CV / résumé',
                        description: 'Optional',
                      ),
                      SizedBox(height: 12),
                      DocumentImageField(
                        title: 'Income certificate',
                        description: 'Optional supporting evidence',
                      ),
                      SizedBox(height: 12),
                      DocumentImageField(
                        title: 'Disability certificate',
                        description: 'Optional, if applicable',
                      ),
                      SizedBox(height: 12),
                      DocumentImageField(
                        title: 'Recommendation or award',
                        description: 'Optional',
                      ),
                      SizedBox(height: 12),
                      DocumentImageField(
                        title: 'Other supporting document',
                        description: 'Optional',
                      ),
                    ],
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
                      label: 'Save documents',
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

  Widget _educationDocumentGroup(EducationDocumentRequirement requirement) {
    final pending = _certificatePending.contains(requirement.id);
    return Container(
      key: ValueKey(requirement.id),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            requirement.level,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 3),
          Text(
            requirement.status,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          DocumentImageField(
            key: ValueKey('${requirement.id}-transcript'),
            title: '${requirement.level} transcript / result card',
            description: 'Required',
            requiredDocument: true,
          ),
          if (requirement.isCompleted) ...[
            const SizedBox(height: 10),
            CheckboxListTile(
              value: pending,
              onChanged: (value) => setState(() {
                if (value ?? false) {
                  _certificatePending.add(requirement.id);
                } else {
                  _certificatePending.remove(requirement.id);
                }
              }),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Certificate / degree not issued yet'),
              subtitle: const Text('Transcript remains required.'),
            ),
            if (!pending)
              DocumentImageField(
                key: ValueKey('${requirement.id}-certificate'),
                title: requirement.level.contains('BS')
                    ? 'BS degree / provisional certificate'
                    : '${requirement.level} certificate',
                description: 'Required when issued',
                requiredDocument: true,
              ),
          ],
        ],
      ),
    );
  }

  void _save() {
    if (_key.currentState!.validate()) widget.onSaved();
  }
}

class _EducationDocumentEmptyState extends StatelessWidget {
  const _EducationDocumentEmptyState();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF3FB),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Column(
      children: [
        Icon(Icons.school_outlined, color: AppColors.zaptecBlue, size: 34),
        SizedBox(height: 10),
        Text(
          'No education documents yet',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 5),
        Text(
          'Add a qualification in Education and its document slots will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
