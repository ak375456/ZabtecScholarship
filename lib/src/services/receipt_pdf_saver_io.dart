import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(
      title: 'Save registration fee challan',
      subject: 'ZABTEC registration fee challan',
      files: [XFile(file.path, mimeType: 'application/pdf')],
      fileNameOverrides: [fileName],
    ),
  );
  return SavedReceipt(
    fileName: fileName,
    path: file.path,
    label: 'ready to save/share as $fileName',
  );
}
