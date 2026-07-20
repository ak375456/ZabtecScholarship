import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

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

Future<SavedReceipt> savePdfBytes(Uint8List bytes, String fileName) async {
  final parts = <web.BlobPart>[bytes.toJS].toJS;
  final blob = web.Blob(parts, web.BlobPropertyBag(type: 'application/pdf'));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName
    ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return SavedReceipt(
    fileName: fileName,
    path: fileName,
    label: 'downloaded as $fileName',
  );
}
