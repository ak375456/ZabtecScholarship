import 'package:flutter/material.dart';

import '../../models.dart';
import '../../services/api_client.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/document_image_field.dart';

class DocumentsSection extends StatelessWidget {
  const DocumentsSection({
    super.key,
    required this.educationRequirements,
    required this.documents,
    required this.onUpload,
    required this.onDelete,
    required this.onSaved,
  });

  final List<EducationDocumentRequirement> educationRequirements;
  final List<StudentDocument> documents;
  final Future<void> Function(String documentType, UploadFilePayload file)
  onUpload;
  final Future<void> Function(StudentDocument document) onDelete;
  final Future<void> Function() onSaved;

  @override
  Widget build(BuildContext context) {
    final byType = {
      for (final document in documents) document.documentType: document,
    };
    final educationTypes = _educationTypes();
    return SingleChildScrollView(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 520 ? 18 : 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionHeader(
                eyebrow: 'Uploads',
                title: 'Documents',
                description:
                    'Upload identity and academic evidence required for your scholarship application.',
              ),
              const SizedBox(height: 24),
              FormCard(
                title: 'Identity documents',
                icon: Icons.badge_outlined,
                child: Column(
                  children: [
                    _slot(
                      title: 'Applicant photograph',
                      description: 'Recent passport-style picture',
                      type: 'photograph',
                      required: true,
                      byType: byType,
                    ),
                    const SizedBox(height: 12),
                    _slot(
                      title: 'CNIC front',
                      description: 'Required',
                      type: 'cnic_front',
                      required: true,
                      byType: byType,
                    ),
                    const SizedBox(height: 12),
                    _slot(
                      title: 'CNIC back',
                      description: 'Required',
                      type: 'cnic_back',
                      required: true,
                      byType: byType,
                    ),
                    const SizedBox(height: 12),
                    _slot(
                      title: 'Domicile certificate',
                      description: 'Optional',
                      type: 'domicile',
                      byType: byType,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FormCard(
                title: 'Education documents',
                icon: Icons.school_outlined,
                child: educationTypes.isEmpty
                    ? const _EducationDocumentEmptyState()
                    : Column(
                        children: educationTypes
                            .map(
                              (type) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _slot(
                                  title: _documentTitle(type),
                                  description: 'Required academic evidence',
                                  type: type,
                                  required: true,
                                  byType: byType,
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 18),
              FormCard(
                title: 'Optional supporting document',
                icon: Icons.folder_copy_outlined,
                child: _slot(
                  title: 'Other supporting document',
                  description: 'Income proof, award, recommendation or CV',
                  type: 'other',
                  byType: byType,
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
                    label: 'Confirm documents',
                    icon: Icons.check_rounded,
                    onPressed: () => _save(context, byType),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slot({
    required String title,
    required String description,
    required String type,
    required Map<String, StudentDocument> byType,
    bool required = false,
  }) => DocumentImageField(
    title: title,
    description: description,
    documentType: type,
    document: byType[type],
    requiredDocument: required,
    onUpload: onUpload,
    onDelete: onDelete,
  );

  Set<String> _educationTypes() {
    final types = <String>{};
    for (final requirement in educationRequirements) {
      final level = requirement.level.toLowerCase();
      if (level.contains('matric') || level.contains('ssc')) {
        types.add('matric_certificate');
      } else if (level.contains('fsc') ||
          level.contains('hssc') ||
          level.contains('a-level') ||
          level.contains('o-level')) {
        types.add('fsc_certificate');
      } else if (level.contains('master') || level.contains('mphil')) {
        types.add('masters_certificate');
      } else if (level.contains('bs') ||
          level.contains('bachelor') ||
          level.contains('associate')) {
        types.add('bachelors_certificate');
      } else {
        types.add('other');
      }
    }
    return types;
  }

  Future<void> _save(
    BuildContext context,
    Map<String, StudentDocument> byType,
  ) async {
    final missing = [
      if (!byType.containsKey('photograph')) 'photograph',
      if (!byType.containsKey('cnic_front')) 'CNIC front',
      if (!byType.containsKey('cnic_back')) 'CNIC back',
      for (final type in _educationTypes())
        if (!byType.containsKey(type)) _documentTitle(type),
    ];
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Missing required documents: ${missing.join(', ')}'),
        ),
      );
      return;
    }
    await onSaved();
  }

  String _documentTitle(String type) => switch (type) {
    'matric_certificate' => 'Matric certificate / result',
    'fsc_certificate' => 'FSc / HSSC certificate or result',
    'bachelors_certificate' => 'Bachelor’s certificate',
    'masters_certificate' => 'Master’s certificate',
    _ => 'Other academic document',
  };
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
          'Add a qualification in Education and its required document slot will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    ),
  );
}
