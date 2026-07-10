import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models.dart';
import '../services/api_client.dart';
import '../theme.dart';

class DocumentImageField extends StatefulWidget {
  const DocumentImageField({
    super.key,
    required this.title,
    required this.description,
    required this.documentType,
    required this.onUpload,
    required this.onDelete,
    this.document,
    this.requiredDocument = false,
  });

  final String title;
  final String description;
  final String documentType;
  final StudentDocument? document;
  final bool requiredDocument;
  final Future<void> Function(String documentType, UploadFilePayload file)
  onUpload;
  final Future<void> Function(StudentDocument document) onDelete;

  @override
  State<DocumentImageField> createState() => _DocumentImageFieldState();
}

class _DocumentImageFieldState extends State<DocumentImageField> {
  Uint8List? _previewBytes;
  String? _pickedFileName;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final hasFile = document != null || _pickedFileName != null;
    final hasError = widget.requiredDocument && document == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: hasError ? const Color(0xFFFFF3F3) : AppColors.canvas,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: hasError ? const Color(0xFFC73838) : AppColors.border,
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
                child: _previewBytes != null
                    ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                    : Icon(
                        _isPdf(document?.mimeType)
                            ? Icons.picture_as_pdf_outlined
                            : Icons.description_outlined,
                        color: AppColors.zaptecBlue,
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (document?.isVerified == true)
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.leafGreen,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      document?.originalName ??
                          _pickedFileName ??
                          widget.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (document?.rejectionReason != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        document!.rejectionReason!,
                        style: const TextStyle(
                          color: Color(0xFFC73838),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _pickFile,
                          icon: _loading
                              ? const SizedBox.square(
                                  dimension: 15,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  hasFile
                                      ? Icons.swap_horiz_rounded
                                      : Icons.upload_file_outlined,
                                  size: 18,
                                ),
                          label: Text(hasFile ? 'Replace' : 'Upload'),
                        ),
                        if (document != null)
                          TextButton.icon(
                            onPressed: _loading
                                ? null
                                : () => _delete(document),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Remove'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              'Please upload ${widget.title.toLowerCase()}',
              style: const TextStyle(color: Color(0xFFC73838), fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickFile() async {
    final source = await showModalBottomSheet<_DocumentSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file_outlined),
                title: const Text('Choose file'),
                subtitle: const Text('JPEG, PNG, WebP or PDF'),
                onTap: () => Navigator.pop(context, _DocumentSource.file),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Photos'),
                subtitle: const Text('JPEG, PNG or WebP image'),
                onTap: () => Navigator.pop(context, _DocumentSource.photos),
              ),
              ListTile(
                leading: const Icon(Icons.document_scanner_outlined),
                title: const Text('Take document photo'),
                onTap: () => Navigator.pop(context, _DocumentSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _loading = true);
    try {
      final payload = switch (source) {
        _DocumentSource.file => await _filePayload(),
        _DocumentSource.photos => await _imagePayload(ImageSource.gallery),
        _DocumentSource.camera => await _imagePayload(ImageSource.camera),
      };
      if (payload == null) return;
      if (payload.bytes.lengthInBytes > 5 * 1024 * 1024) {
        _message('Use a file smaller than 5 MB.');
        return;
      }
      await widget.onUpload(widget.documentType, payload);
      if (!mounted) return;
      setState(() {
        _pickedFileName = payload.filename;
        _previewBytes = _looksLikeImage(payload.filename)
            ? payload.bytes
            : null;
      });
      _message('${widget.title} uploaded.');
    } catch (error) {
      _message('Could not upload ${widget.title.toLowerCase()}: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<UploadFilePayload?> _filePayload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );
    final file = result?.files.single;
    final bytes = file?.bytes;
    if (file == null || bytes == null) return null;
    return UploadFilePayload(
      bytes: bytes,
      filename: file.name,
      mimeType: _mimeFor(file.name),
    );
  }

  Future<UploadFilePayload?> _imagePayload(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2000,
    );
    if (file == null) return null;
    final filename = _supportedImageName(file.name);
    return UploadFilePayload(
      bytes: await file.readAsBytes(),
      filename: filename,
      mimeType: _mimeFor(filename) ?? 'image/jpeg',
    );
  }

  Future<void> _delete(StudentDocument document) async {
    setState(() => _loading = true);
    try {
      await widget.onDelete(document);
      _message('${widget.title} removed.');
    } catch (error) {
      _message('Could not remove ${widget.title.toLowerCase()}: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isPdf(String? mimeType) => mimeType == 'application/pdf';

  bool _looksLikeImage(String filename) =>
      RegExp(r'\.(jpe?g|png|webp)$', caseSensitive: false).hasMatch(filename);

  String? _mimeFor(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return null;
  }

  String _supportedImageName(String filename) {
    if (_looksLikeImage(filename)) return filename;
    final dot = filename.lastIndexOf('.');
    final stem = dot <= 0 ? filename : filename.substring(0, dot);
    final safeStem = stem.trim().isEmpty ? 'document-photo' : stem.trim();
    return '$safeStem.jpg';
  }
}

enum _DocumentSource { file, photos, camera }
