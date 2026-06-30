import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models.dart';

class ReceiptPdfService {
  const ReceiptPdfService._();

  static const activationFeePkr = 1500;

  static Future<File> saveActivationReceipt(ActivationReceipt receipt) async {
    final bytes = await buildActivationReceiptBytes(receipt);
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/zabtec_activation_${receipt.receiptNumber}.pdf',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<Uint8List> buildActivationReceiptBytes(
    ActivationReceipt receipt,
  ) async {
    final pdf = pw.Document(
      title: 'ZABTEC scholarship activation receipt',
      author: 'ZABTEC Scholarship Pakistan',
      subject: 'Profile activation fee receipt',
    );

    final zabtecLogo = await _loadAssetImage('assets/ZABTec, logo.jpg');
    final hecLogo = await _loadAssetImage('assets/hec-logo.png');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromHex('#DDE4EA')),
            borderRadius: pw.BorderRadius.circular(18),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(26),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _receiptHeader(zabtecLogo, hecLogo),
                pw.SizedBox(height: 24),
                pw.Container(
                  padding: const pw.EdgeInsets.all(18),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#EAF3FB'),
                    borderRadius: pw.BorderRadius.circular(14),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Activation receipt',
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('#062F66'),
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Receipt No. ${receipt.receiptNumber}',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#647181'),
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#01411C'),
                          borderRadius: pw.BorderRadius.circular(999),
                        ),
                        child: pw.Text(
                          'PAID',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),
                _receiptGrid(receipt),
                pw.SizedBox(height: 22),
                pw.Container(
                  padding: const pw.EdgeInsets.all(18),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColor.fromHex('#DDE4EA')),
                    borderRadius: pw.BorderRadius.circular(14),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Activation note',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#172331'),
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Your ZABTEC Scholarship profile and services are active after the PKR 1,500 profile activation payment is recorded.',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#647181'),
                          lineSpacing: 4,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'This frontend build uses a dummy card payment flow. Final production release should verify this receipt with the payment gateway/backend.',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#647181'),
                          fontSize: 10,
                          lineSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),
                pw.Divider(color: PdfColor.fromHex('#DDE4EA')),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Generated by ZABTEC Scholarship Pakistan mobile app',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: PdfColor.fromHex('#647181'),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _receiptHeader(
    pw.MemoryImage? zabtecLogo,
    pw.MemoryImage? hecLogo,
  ) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      if (zabtecLogo != null) _logoBox(zabtecLogo),
      pw.SizedBox(width: 12),
      if (hecLogo != null) _logoBox(hecLogo),
      pw.SizedBox(width: 16),
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'ZABTEC × HEC',
              style: pw.TextStyle(
                color: PdfColor.fromHex('#062F66'),
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Scholarship Profile Activation',
              style: pw.TextStyle(color: PdfColor.fromHex('#647181')),
            ),
          ],
        ),
      ),
    ],
  );

  static pw.Widget _logoBox(pw.MemoryImage image) => pw.Container(
    width: 56,
    height: 56,
    padding: const pw.EdgeInsets.all(6),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      border: pw.Border.all(color: PdfColor.fromHex('#DDE4EA')),
      borderRadius: pw.BorderRadius.circular(13),
    ),
    child: pw.Image(image, fit: pw.BoxFit.contain),
  );

  static pw.Widget _receiptGrid(ActivationReceipt receipt) => pw.Table(
    border: pw.TableBorder.all(color: PdfColor.fromHex('#DDE4EA'), width: .8),
    columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(1.5)},
    children: [
      _row('Student name', receipt.account.fullName),
      _row('CNIC', receipt.account.cnic),
      _row('Email', receipt.account.email),
      _row('Phone', receipt.account.phone),
      _row('Amount', receipt.amountLabel),
      _row(
        'Payment method',
        '${receipt.paymentMethod} •••• ${receipt.cardLast4}',
      ),
      _row('Paid on', _formatDateTime(receipt.issuedAt)),
      _row('Status', 'Profile active / services unlocked'),
    ],
  );

  static pw.TableRow _row(String label, String value) => pw.TableRow(
    children: [
      pw.Container(
        color: PdfColor.fromHex('#F6F8FA'),
        padding: const pw.EdgeInsets.all(10),
        child: pw.Text(
          label,
          style: pw.TextStyle(
            color: PdfColor.fromHex('#647181'),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Text(
          value,
          style: pw.TextStyle(color: PdfColor.fromHex('#172331')),
        ),
      ),
    ],
  );

  static Future<pw.MemoryImage?> _loadAssetImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date at $time';
  }
}
