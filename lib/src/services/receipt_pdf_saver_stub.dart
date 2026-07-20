import 'dart:typed_data';

class SavedReceipt {
  const SavedReceipt({
    required this.fileName,
    required this.path,
    required this.label,
  });

  final String fileName;
  final String path;
  final String label;
}

Future<SavedReceipt> savePdfBytes(Uint8List bytes, String fileName) {
  throw UnsupportedError('PDF saving is not supported on this platform.');
}
