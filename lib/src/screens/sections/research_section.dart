import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

class ResearchSection extends StatefulWidget {
  const ResearchSection({
    super.key,
    required this.application,
    required this.onSaved,
  });

  final ScholarshipApplication? application;
  final Future<void> Function(Map<String, dynamic> payload) onSaved;

  @override
  State<ResearchSection> createState() => _ResearchSectionState();
}

class _ResearchSectionState extends State<ResearchSection>
    with AutomaticKeepAliveClientMixin {
  final _key = GlobalKey<FormState>();
  final List<_PublicationData> _publications = [];
  bool? _hasResearch;
  bool _attempted = false;
  bool _saving = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  @override
  void didUpdateWidget(covariant ResearchSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.application?.id != widget.application?.id) _hydrate();
  }

  @override
  void dispose() {
    for (final publication in _publications) {
      publication.dispose();
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
                  eyebrow: 'Academic background',
                  title: 'Research & publications',
                  description:
                      'Tell us about published work, or declare that you do not have any yet.',
                ),
                const SizedBox(height: 24),
                FormCard(
                  title: 'Research declaration',
                  icon: Icons.science_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Have you authored or co-authored a published research paper?',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.check_rounded),
                            label: Text('Yes'),
                          ),
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.close_rounded),
                            label: Text('Not yet'),
                          ),
                        ],
                        selected: _hasResearch == null
                            ? <bool>{}
                            : {_hasResearch!},
                        emptySelectionAllowed: true,
                        onSelectionChanged: (value) => setState(() {
                          _hasResearch = value.first;
                          if (_hasResearch == true && _publications.isEmpty) {
                            _publications.add(_PublicationData());
                          }
                        }),
                      ),
                      if (_hasResearch == null && _attempted) ...[
                        const SizedBox(height: 9),
                        const Text(
                          'Please choose one option.',
                          style: TextStyle(
                            color: Color(0xFFC73838),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_hasResearch == true) ...[
                  const SizedBox(height: 18),
                  for (var index = 0; index < _publications.length; index++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: _PublicationCard(
                        data: _publications[index],
                        number: index + 1,
                        canRemove: _publications.length > 1,
                        onRemove: () => _removePublication(index),
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _publications.length >= 5
                        ? null
                        : () => setState(
                            () => _publications.add(_PublicationData()),
                          ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add another publication'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
                if (_hasResearch == false) ...[
                  const SizedBox(height: 18),
                  FormCard(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppColors.leafGreen,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Research experience is not required. This declaration will still be saved.',
                              style: TextStyle(
                                color: AppColors.pakistanGreen,
                                height: 1.45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
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
                      label: _saving ? 'Saving...' : 'Save research',
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

  void _removePublication(int index) {
    final removed = _publications.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    if (_hasResearch == null) {
      setState(() => _attempted = true);
      return;
    }
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSaved({
        'hasResearch': _hasResearch,
        'publicationCount': _hasResearch == true ? _publications.length : 0,
        'publications': _hasResearch == true
            ? _publications.map((publication) => publication.payload()).toList()
            : <Map<String, dynamic>>[],
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _hydrate() {
    for (final publication in _publications) {
      publication.dispose();
    }
    _publications.clear();
    final research = widget.application?.research ?? const {};
    _hasResearch = research['hasResearch'] is bool
        ? research['hasResearch'] as bool
        : null;
    final publications = research['publications'] is List
        ? research['publications'] as List
        : const [];
    for (final publication in publications) {
      _publications.add(_PublicationData.fromJson(_asMap(publication)));
    }
    if (_hasResearch == true && _publications.isEmpty) {
      _publications.add(_PublicationData());
    }
  }
}

class _PublicationCard extends StatelessWidget {
  const _PublicationCard({
    required this.data,
    required this.number,
    required this.canRemove,
    required this.onRemove,
  });

  final _PublicationData data;
  final int number;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => FormCard(
    title: 'Publication $number',
    icon: Icons.article_outlined,
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
        TextFormField(
          controller: data.title,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Paper title'),
          validator: (value) => requiredText(value, 'Paper title'),
        ),
        const SizedBox(height: 16),
        FormGrid(
          children: [
            TextFormField(
              controller: data.journal,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Journal / conference',
              ),
              validator: (value) => requiredText(value, 'Journal / conference'),
            ),
            TextFormField(
              controller: data.year,
              keyboardType: TextInputType.number,
              inputFormatters: [
                DigitsOnlyFormatter(),
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: const InputDecoration(labelText: 'Publication year'),
              validator: (value) => requiredText(value, 'Publication year'),
            ),
            TextFormField(
              controller: data.doi,
              decoration: const InputDecoration(
                labelText: 'DOI (optional)',
                hintText: '10.xxxx/xxxxx',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PublicationData {
  _PublicationData();

  factory _PublicationData.fromJson(Map<String, dynamic> json) =>
      _PublicationData()
        ..title.text = _text(json['title'])
        ..journal.text = _text(json['journal'])
        ..year.text = _text(json['year'])
        ..doi.text = _text(json['doi']);

  final title = TextEditingController();
  final journal = TextEditingController();
  final year = TextEditingController();
  final doi = TextEditingController();

  Map<String, dynamic> payload() => {
    'title': title.text.trim(),
    'journal': journal.text.trim(),
    'year': int.tryParse(year.text),
    'doi': doi.text.trim(),
  };

  void dispose() {
    title.dispose();
    journal.dispose();
    year.dispose();
    doi.dispose();
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

String _text(Object? value) => value?.toString() ?? '';
