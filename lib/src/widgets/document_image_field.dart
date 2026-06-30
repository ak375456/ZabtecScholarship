import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/demo_profile.dart';
import '../theme.dart';

class DocumentImageField extends StatefulWidget {
  const DocumentImageField({
    super.key,
    required this.title,
    required this.description,
    this.requiredDocument = false,
  });

  final String title;
  final String description;
  final bool requiredDocument;

  @override
  State<DocumentImageField> createState() => _DocumentImageFieldState();
}

class _DocumentImageFieldState extends State<DocumentImageField> {
  Uint8List? _bytes;
  String? _fileName;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (DemoProfile.enabled && widget.requiredDocument) {
      _bytes = DemoProfile.documentPlaceholderBytes;
      _fileName = DemoProfile.documentPlaceholderName;
    }
  }

  @override
  Widget build(BuildContext context) => FormField<Uint8List>(
    initialValue: _bytes,
    validator: (value) => widget.requiredDocument && value == null
        ? 'Please add ${widget.title.toLowerCase()}'
        : null,
    builder: (field) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: field.hasError ? const Color(0xFFFFF3F3) : AppColors.canvas,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: field.hasError
                  ? const Color(0xFFC73838)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 66,
                height: 66,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: AppColors.border),
                ),
                child: _bytes == null
                    ? const Icon(
                        Icons.image_outlined,
                        color: AppColors.zaptecBlue,
                      )
                    : Image.memory(_bytes!, fit: BoxFit.cover),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _fileName ?? widget.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : () => _pickImage(field),
                      icon: _loading
                          ? const SizedBox.square(
                              dimension: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_a_photo_outlined, size: 18),
                      label: Text(_bytes == null ? 'Add image' : 'Replace'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (field.hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              field.errorText!,
              style: const TextStyle(color: Color(0xFFC73838), fontSize: 12),
            ),
          ),
        ],
      ],
    ),
  );

  Future<void> _pickImage(FormFieldState<Uint8List> field) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: const Text('Take document photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _loading = true);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2000,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Use an image smaller than 10 MB.')),
          );
        }
        return;
      }
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _fileName = file.name;
        });
        field.didChange(bytes);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the camera or photo library.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
