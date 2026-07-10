import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models.dart';
import 'receipt_pdf_saver.dart';

class ReceiptPdfService {
  const ReceiptPdfService._();

  static const activationFeePkr = 1500;
  static const bankName = 'FAYSAL BANK';
  static const accountTitle = 'Zabtec Enterprise';
  static const accountNumber = '12345678901234';
  static const iban = 'PK00FAYS0000000000000000';

  static Future<SavedReceipt> saveActivationReceipt(
    ActivationReceipt receipt, {
    ScholarshipApplication? application,
  }) async {
    final bytes = await buildActivationReceiptBytes(
      receipt,
      application: application,
    );
    return savePdfBytes(
      bytes,
      'zabtec_registration_challan_${receipt.challanNumber}.pdf',
    );
  }

  static Future<Uint8List> buildActivationReceiptBytes(
    ActivationReceipt receipt, {
    ScholarshipApplication? application,
  }) async {
    final pdf = pw.Document(
      title: 'ZABTEC registration fee challan',
      author: 'ZABTEC Scholarship Pakistan',
      subject: 'Registration fee bank challan',
    );

    final zabtecLogo = await _loadAssetImage('assets/ZABTec, logo.jpg');
    final faysalLogo = await _loadAssetImage('assets/onelink.png');
    final dueDate = receipt.issuedAt.add(const Duration(days: 7));
    final fatherName = _fatherName(application);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.fromLTRB(17, 18, 17, 18),
        build: (context) => pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _challanCopy(
              copyTitle: 'BANK COPY',
              receipt: receipt,
              fatherName: fatherName,
              dueDate: dueDate,
              logo: zabtecLogo,
              bankLogo: faysalLogo,
            ),
            pw.SizedBox(width: 10),
            _challanCopy(
              copyTitle: 'OFFICE COPY',
              receipt: receipt,
              fatherName: fatherName,
              dueDate: dueDate,
              logo: zabtecLogo,
              bankLogo: faysalLogo,
            ),
            pw.SizedBox(width: 10),
            _challanCopy(
              copyTitle: 'STUDENT COPY',
              receipt: receipt,
              fatherName: fatherName,
              dueDate: dueDate,
              logo: zabtecLogo,
              bankLogo: faysalLogo,
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _challanCopy({
    required String copyTitle,
    required ActivationReceipt receipt,
    required String fatherName,
    required DateTime dueDate,
    required pw.MemoryImage? logo,
    required pw.MemoryImage? bankLogo,
  }) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.black,
          width: .8,
          style: pw.BorderStyle.dashed,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _copyLabel(copyTitle),
          _challanHeader(logo, bankLogo),
          pw.SizedBox(height: 5),
          _studentTable(receipt, fatherName, dueDate),
          pw.SizedBox(height: 8),
          _feeDetails(receipt),
          pw.SizedBox(height: 6),
          _amountInWords(receipt.amountPkr),
          pw.SizedBox(height: 5),
          _termsBox(),
          pw.Spacer(),
          _signatureRow(),
        ],
      ),
    ),
  );

  static pw.Widget _copyLabel(String copyTitle) => pw.Align(
    alignment: pw.Alignment.centerLeft,
    child: pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700, width: .7),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Text(
        copyTitle,
        style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
      ),
    ),
  );

  static pw.Widget _challanHeader(
    pw.MemoryImage? logo,
    pw.MemoryImage? bankLogo,
  ) => pw.Container(
    height: 86,
    padding: const pw.EdgeInsets.only(top: 2),
    child: pw.Stack(
      children: [
        pw.Positioned(
          left: 2,
          top: 32,
          child: logo == null
              ? pw.SizedBox(width: 54, height: 35)
              : pw.Image(logo, width: 54, height: 35, fit: pw.BoxFit.contain),
        ),
        pw.Positioned(
          right: 3,
          top: 37,
          child: bankLogo == null
              ? pw.SizedBox(width: 62, height: 22)
              : pw.Image(
                  bankLogo,
                  width: 62,
                  height: 22,
                  fit: pw.BoxFit.contain,
                ),
        ),
        pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(
                'ZABTEC ENTERPRISE',
                style: pw.TextStyle(
                  fontSize: 14.5,
                  color: PdfColor.fromHex('#17217B'),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 9),
              pw.Text(
                'FEE CHALLAN',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColor.fromHex('#DF1F26'),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              _accountLine('A/C Title:', accountTitle),
              _accountLine('Bank:', bankName),
              _accountLine('A/C No:', accountNumber),
              _accountLine('IBAN:', iban),
            ],
          ),
        ),
      ],
    ),
  );

  static pw.Widget _accountLine(String label, String value) => pw.RichText(
    text: pw.TextSpan(
      children: [
        pw.TextSpan(
          text: '$label ',
          style: pw.TextStyle(fontSize: 7.6, fontWeight: pw.FontWeight.bold),
        ),
        pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 7.6)),
      ],
    ),
  );

  static pw.Widget _studentTable(
    ActivationReceipt receipt,
    String fatherName,
    DateTime dueDate,
  ) => pw.Table(
    border: pw.TableBorder.all(color: PdfColors.black, width: .65),
    columnWidths: const {
      0: pw.FlexColumnWidth(.9),
      1: pw.FlexColumnWidth(2.65),
    },
    children: [
      _detailRow('Due Date', _formatDate(dueDate), redValue: true),
      _detailRow('Name', receipt.account.fullName),
      _detailRow('CNIC', receipt.account.cnic),
      _detailRow('Father Name', fatherName),
      _detailRow('Challan No.', receipt.challanNumber),
    ],
  );

  static pw.TableRow _detailRow(
    String label,
    String value, {
    bool redValue = false,
  }) => pw.TableRow(
    children: [
      _detailCell(label, bold: true, shaded: true),
      _detailCell(value, red: redValue),
    ],
  );

  static pw.Widget _detailCell(
    String text, {
    bool bold = false,
    bool shaded = false,
    bool red = false,
  }) => pw.Container(
    color: shaded ? PdfColor.fromHex('#F0F0F0') : null,
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
    child: pw.Text(
      text,
      maxLines: 2,
      style: pw.TextStyle(
        fontSize: 7.7,
        color: red ? PdfColor.fromHex('#E31D24') : PdfColors.black,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  static pw.Widget _feeDetails(ActivationReceipt receipt) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Center(
        child: pw.Text(
          'FEE DETAILS',
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            decoration: pw.TextDecoration.underline,
          ),
        ),
      ),
      pw.SizedBox(height: 4),
      _feeRow('REGISTRATION FEE', _formatAmount(receipt.amountPkr)),
      pw.SizedBox(height: 8),
      _feeRow(
        'GRAND TOTAL',
        _formatAmount(receipt.amountPkr),
        shaded: true,
        bold: true,
      ),
    ],
  );

  static pw.Widget _feeRow(
    String label,
    String amount, {
    bool shaded = false,
    bool bold = false,
  }) => pw.Table(
    border: pw.TableBorder.all(color: PdfColors.black, width: .55),
    columnWidths: const {
      0: pw.FlexColumnWidth(2.8),
      1: pw.FlexColumnWidth(1.2),
    },
    children: [
      pw.TableRow(
        children: [
          _feeCell(label, shaded: shaded, bold: bold),
          _feeCell(amount, shaded: shaded, bold: true, alignRight: true),
        ],
      ),
    ],
  );

  static pw.Widget _feeCell(
    String text, {
    bool shaded = false,
    bool bold = false,
    bool alignRight = false,
  }) => pw.Container(
    color: shaded ? PdfColor.fromHex('#EDEDED') : null,
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
    child: pw.Text(
      text,
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        fontSize: 7.8,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  static pw.Widget _amountInWords(int amount) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400, width: .5),
    ),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: 'Amount in Words: ',
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(
            text: '${_amountWords(amount)} Rupees Only',
            style: const pw.TextStyle(fontSize: 7),
          ),
        ],
      ),
    ),
  );

  static pw.Widget _termsBox() => pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(10, 8, 8, 8),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#FFFDEA'),
      border: pw.Border.all(color: PdfColors.black, width: .7),
      borderRadius: pw.BorderRadius.circular(2),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Terms & Conditions:',
          style: pw.TextStyle(
            fontSize: 7.5,
            color: PdfColor.fromHex('#9A6A00'),
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 7),
        _term('1. Pay through any Faysal Bank branch in the country.'),
        _term(
          '2. Registration fee must be deposited on or before the due date.',
        ),
        _term('3. Keep the student copy for your record.'),
        _term('4. Submit the bank stamped office copy if requested by ZABTEC.'),
      ],
    ),
  );

  static pw.Widget _term(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 5),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 6.8,
        color: PdfColor.fromHex('#333333'),
        lineSpacing: 1.7,
      ),
    ),
  );

  static pw.Widget _signatureRow() => pw.Padding(
    padding: const pw.EdgeInsets.fromLTRB(8, 0, 8, 3),
    child: pw.Row(
      children: [
        _signature('BANK OFFICIAL'),
        pw.SizedBox(width: 48),
        _signature('ACCOUNTS OFFICER'),
      ],
    ),
  );

  static pw.Widget _signature(String label) => pw.Expanded(
    child: pw.Column(
      children: [
        pw.Container(height: .8, color: PdfColors.black),
        pw.SizedBox(height: 3),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );

  static Future<pw.MemoryImage?> _loadAssetImage(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  static String _fatherName(ScholarshipApplication? application) {
    final father = application?.family['father'];
    if (father is Map) {
      final name = father['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return 'Not provided';
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }

  static String _formatAmount(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final fromEnd = text.length - i;
      buffer.write(text[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }

  static String _amountWords(int amount) {
    if (amount == 0) return 'Zero';
    final parts = <String>[];
    var value = amount;
    final millions = value ~/ 1000000;
    if (millions > 0) {
      parts.add('${_underThousand(millions)} Million');
      value %= 1000000;
    }
    final thousands = value ~/ 1000;
    if (thousands > 0) {
      parts.add('${_underThousand(thousands)} Thousand');
      value %= 1000;
    }
    if (value > 0) parts.add(_underThousand(value));
    return parts.join(' ');
  }

  static String _underThousand(int value) {
    const ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    const tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    final parts = <String>[];
    var remaining = value;
    final hundreds = remaining ~/ 100;
    if (hundreds > 0) {
      parts.add('${ones[hundreds]} Hundred');
      remaining %= 100;
    }
    if (remaining >= 20) {
      final ten = remaining ~/ 10;
      final one = remaining % 10;
      parts.add(one == 0 ? tens[ten] : '${tens[ten]} ${ones[one]}');
    } else if (remaining > 0) {
      parts.add(ones[remaining]);
    }
    return parts.join(' ');
  }
}
