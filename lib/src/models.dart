class Account {
  const Account({
    required this.fullName,
    required this.cnic,
    required this.phone,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String cnic;
  final String phone;
  final String email;
  final String password;

  String get initials {
    final words = fullName.trim().split(RegExp(r'\s+'));
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}

class ApplicationProgress {
  ApplicationProgress({bool prefilled = false}) {
    if (!prefilled) return;
    personal = true;
    family = true;
    education = true;
    experience = true;
    research = true;
    documents = true;
  }

  bool personal = false;
  bool family = false;
  bool education = false;
  bool experience = false;
  bool research = false;
  bool documents = false;
  bool servicePaymentComplete = false;

  bool get coreProfileComplete => personal && family && education && documents;
  bool get servicesUnlocked => coreProfileComplete && servicePaymentComplete;

  List<String> get missingForServices => [
    if (!personal) 'Profile',
    if (!family) 'Family',
    if (!education) 'Education',
    if (!documents) 'Documents',
  ];

  double get value =>
      .15 +
      (personal ? .15 : 0) +
      (family ? .15 : 0) +
      (education ? .20 : 0) +
      (experience ? .10 : 0) +
      (research ? .10 : 0) +
      (documents ? .15 : 0);
  int get percent => (value * 100).round();
}

class EducationDocumentRequirement {
  const EducationDocumentRequirement({
    required this.id,
    required this.level,
    required this.status,
  });

  final int id;
  final String level;
  final String status;

  bool get isCompleted => status == 'Completed';
}

class ActivationReceipt {
  const ActivationReceipt({
    required this.receiptNumber,
    required this.account,
    required this.issuedAt,
    required this.amountPkr,
    required this.paymentMethod,
    required this.cardLast4,
  });

  final String receiptNumber;
  final Account account;
  final DateTime issuedAt;
  final int amountPkr;
  final String paymentMethod;
  final String cardLast4;

  String get amountLabel => 'PKR ${_formatAmount(amountPkr)}';

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
}
