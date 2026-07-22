class Account {
  const Account({
    required this.id,
    required this.fullName,
    required this.cnic,
    required this.phone,
    required this.email,
    required this.role,
    this.isActive = true,
    this.isEmailVerified = false,
    this.createdAt,
    this.password,
  });

  final String id;
  final String fullName;
  final String cnic;
  final String phone;
  final String email;
  final String role;
  final bool isActive;
  final bool isEmailVerified;
  final DateTime? createdAt;

  @Deprecated('Passwords are never stored in production sessions.')
  final String? password;

  bool get isStudent => role == 'student';
  bool get isAdmin => role == 'admin';
  bool get isHec => role == 'hec';
  bool get isStaff => isAdmin || isHec;

  String get roleLabel => switch (role) {
    'admin' => 'Admin',
    'hec' => 'HEC',
    _ => 'Student',
  };

  String get initials {
    final words = fullName.trim().split(RegExp(r'\s+'));
    return words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0].toUpperCase())
        .join();
  }

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    id: _string(json['_id'] ?? json['id']),
    fullName: _string(json['fullName']),
    cnic: _string(json['cnic']),
    phone: _string(json['phone']),
    email: _string(json['email']),
    role: _string(json['role'], fallback: 'student'),
    isActive: json['isActive'] != false,
    isEmailVerified: json['isEmailVerified'] == true,
    createdAt: _date(json['createdAt']),
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'fullName': fullName,
    'cnic': cnic,
    'phone': phone,
    'email': email,
    'role': role,
    'isActive': isActive,
    'isEmailVerified': isEmailVerified,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final Account user;
  final String accessToken;
  final String refreshToken;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    user: Account.fromJson(_map(json['user'])),
    accessToken: _string(json['accessToken']),
    refreshToken: _string(json['refreshToken']),
  );

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}

class ApplicationProgress {
  ApplicationProgress({
    this.personal = false,
    this.family = false,
    this.education = false,
    this.experience = false,
    this.research = false,
    this.documents = false,
    this.payment = false,
    bool prefilled = false,
  }) {
    if (!prefilled) return;
    personal = true;
    family = true;
    education = true;
    experience = true;
    research = true;
    documents = true;
    payment = true;
  }

  bool personal;
  bool family;
  bool education;
  bool experience;
  bool research;
  bool documents;
  bool payment;

  bool get servicePaymentComplete => payment;
  set servicePaymentComplete(bool value) => payment = value;

  bool get coreProfileComplete =>
      personal && family && education && experience && research && documents;
  bool get paymentEligible => coreProfileComplete;
  bool get readyForSubmission => paymentEligible && payment;
  bool get servicesUnlocked => payment;

  List<String> get missingForPayment => [
    if (!personal) 'Profile',
    if (!family) 'Family',
    if (!education) 'Education',
    if (!experience) 'Experience declaration',
    if (!research) 'Research declaration',
    if (!documents) 'Required documents',
  ];

  List<String> get missingForSubmission => [
    ...missingForPayment,
    if (!payment) 'Registration fee challan',
  ];

  List<String> get missingForServices => missingForSubmission;

  double get value {
    const sectionWeight = 1 / 7;
    return (personal ? sectionWeight : 0) +
        (family ? sectionWeight : 0) +
        (education ? sectionWeight : 0) +
        (experience ? sectionWeight : 0) +
        (research ? sectionWeight : 0) +
        (documents ? sectionWeight : 0) +
        (payment ? sectionWeight : 0);
  }

  int get percent => (value * 100).round().clamp(0, 100);

  factory ApplicationProgress.fromJson(Object? value) {
    final json = _map(value);
    return ApplicationProgress(
      personal: json['personal'] == true,
      family: json['family'] == true,
      education: json['education'] == true,
      experience: json['experience'] == true,
      research: json['research'] == true,
      documents: json['documents'] == true,
      payment: json['payment'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'personal': personal,
    'family': family,
    'education': education,
    'experience': experience,
    'research': research,
    'documents': documents,
    'payment': payment,
  };
}

class ScholarshipApplication {
  const ScholarshipApplication({
    required this.id,
    required this.status,
    required this.progress,
    this.applicationNumber,
    this.student,
    this.reviewedBy,
    this.reviewNotes,
    this.personal = const {},
    this.family = const {},
    this.education = const [],
    this.experience = const {},
    this.research = const {},
    this.submittedAt,
    this.createdAt,
  });

  final String id;
  final String? applicationNumber;
  final String status;
  final Account? student;
  final Account? reviewedBy;
  final String? reviewNotes;
  final Map<String, dynamic> personal;
  final Map<String, dynamic> family;
  final List<Map<String, dynamic>> education;
  final Map<String, dynamic> experience;
  final Map<String, dynamic> research;
  final ApplicationProgress progress;
  final DateTime? submittedAt;
  final DateTime? createdAt;

  bool get isDraft => status == 'draft';

  String get statusLabel => switch (status) {
    'under_review' => 'Under review',
    'waitlisted' => 'Waitlisted',
    'approved' => 'Approved',
    'rejected' => 'Rejected',
    'submitted' => 'Submitted',
    _ => 'Draft',
  };

  factory ScholarshipApplication.fromJson(Map<String, dynamic> json) {
    final studentValue = json['student'];
    final reviewedByValue = json['reviewedBy'];
    return ScholarshipApplication(
      id: _string(json['_id'] ?? json['id']),
      applicationNumber: _nullableString(json['applicationNumber']),
      status: _string(json['status'], fallback: 'draft'),
      student: studentValue is Map
          ? Account.fromJson(_map(studentValue))
          : null,
      reviewedBy: reviewedByValue is Map
          ? Account.fromJson(_map(reviewedByValue))
          : null,
      reviewNotes: _nullableString(json['reviewNotes']),
      personal: _map(json['personal']),
      family: _map(json['family']),
      education: _list(json['education']).map(_map).toList(),
      experience: _map(json['experience']),
      research: _map(json['research']),
      progress: ApplicationProgress.fromJson(json['progress']),
      submittedAt: _date(json['submittedAt']),
      createdAt: _date(json['createdAt']),
    );
  }
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

  bool get isCompleted => status == 'Completed' || status == 'completed';
}

class StudentDocument {
  const StudentDocument({
    required this.id,
    required this.documentType,
    required this.filename,
    required this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    required this.url,
    required this.isVerified,
    this.rejectionReason,
    this.createdAt,
  });

  final String id;
  final String documentType;
  final String filename;
  final String originalName;
  final String mimeType;
  final int sizeBytes;
  final String url;
  final bool isVerified;
  final String? rejectionReason;
  final DateTime? createdAt;

  factory StudentDocument.fromJson(Map<String, dynamic> json) =>
      StudentDocument(
        id: _string(json['_id'] ?? json['id']),
        documentType: _string(json['documentType']),
        filename: _string(json['filename']),
        originalName: _string(json['originalName']),
        mimeType: _string(json['mimeType']),
        sizeBytes: _int(json['sizeBytes']),
        url: _string(json['url']),
        isVerified: json['isVerified'] == true,
        rejectionReason: _nullableString(json['rejectionReason']),
        createdAt: _date(json['createdAt']),
      );
}

class ActivationReceipt {
  const ActivationReceipt({
    required this.receiptNumber,
    required this.account,
    required this.issuedAt,
    required this.amountPkr,
    required this.paymentMethod,
    required this.cardLast4,
    this.currency = 'PKR',
    this.status = 'awaiting_payment',
    this.applicationNumber,
    this.proofOriginalName,
    this.proofMimeType,
    this.proofSubmittedAt,
    this.rejectionReason,
    this.reviewedAt,
  });

  final String receiptNumber;
  final Account account;
  final DateTime issuedAt;
  final int amountPkr;
  final String currency;
  final String paymentMethod;
  final String cardLast4;
  final String status;
  final String? applicationNumber;
  final String? proofOriginalName;
  final String? proofMimeType;
  final DateTime? proofSubmittedAt;
  final String? rejectionReason;
  final DateTime? reviewedAt;

  bool get isApproved => status == 'approved' || status == 'completed';
  bool get isPendingReview => status == 'proof_submitted';
  bool get isRejected => status == 'rejected';
  bool get canUploadProof =>
      status == 'awaiting_payment' || status == 'pending' || isRejected;
  bool get hasProof => proofOriginalName?.isNotEmpty == true;

  String get statusLabel => switch (status) {
    'approved' || 'completed' => 'Payment approved',
    'proof_submitted' => 'Pending ZABTEC verification',
    'rejected' => 'Stamped challan rejected',
    _ => 'Awaiting bank payment',
  };

  String get amountLabel => '$currency ${_formatAmount(amountPkr)}';
  String get challanNumber {
    final digits = receiptNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 15) return digits;
    if (digits.length > 15) return digits.substring(digits.length - 15);

    var hash = 0;
    for (final unit in receiptNumber.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    final prefix = issuedAt.millisecondsSinceEpoch.toString();
    final suffix = hash.toString().padLeft(10, '0');
    return '$prefix$suffix'.substring(0, 15);
  }

  factory ActivationReceipt.fromJson(
    Map<String, dynamic> json, {
    required Account account,
  }) {
    final proof = _map(json['proof']);
    return ActivationReceipt(
      receiptNumber: _string(json['receiptNumber']),
      account: account,
      issuedAt:
          _date(json['createdAt']) ?? _date(json['paidAt']) ?? DateTime.now(),
      amountPkr: _int(json['amount'], fallback: 1500),
      currency: _string(json['currency'], fallback: 'PKR'),
      paymentMethod: _string(json['method'], fallback: 'bank_transfer'),
      cardLast4: _string(json['cardLast4']),
      status: _string(json['status'], fallback: 'awaiting_payment'),
      applicationNumber: _nullableString(json['applicationNumber']),
      proofOriginalName: _nullableString(proof['originalName']),
      proofMimeType: _nullableString(proof['mimeType']),
      proofSubmittedAt: _date(proof['uploadedAt']),
      rejectionReason: _nullableString(json['rejectionReason']),
      reviewedAt: _date(json['reviewedAt']),
    );
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
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.body,
    required this.senderRole,
    required this.createdAt,
    this.senderName,
  });

  final String id;
  final String body;
  final String senderRole;
  final DateTime createdAt;
  final String? senderName;

  bool get isFromStudent => senderRole == 'student';

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    final sender = _map(json['sender']);
    return SupportMessage(
      id: _string(json['_id'] ?? json['id']),
      body: _string(json['body']),
      senderRole: _string(json['senderRole'], fallback: 'admin'),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      senderName: _nullableString(sender['fullName']),
    );
  }
}

class SupportThread {
  const SupportThread({
    required this.id,
    required this.status,
    required this.messages,
    required this.unreadForAdmin,
    required this.unreadForStudent,
    this.student,
    this.lastMessageAt,
    this.lastMessagePreview = '',
  });

  final String id;
  final String status;
  final Account? student;
  final List<SupportMessage> messages;
  final int unreadForAdmin;
  final int unreadForStudent;
  final DateTime? lastMessageAt;
  final String lastMessagePreview;

  bool get isClosed => status == 'closed';

  factory SupportThread.fromJson(Map<String, dynamic> json) {
    final student = json['student'];
    return SupportThread(
      id: _string(json['_id'] ?? json['id']),
      status: _string(json['status'], fallback: 'open'),
      student: student is Map ? Account.fromJson(_map(student)) : null,
      messages: _list(
        json['messages'],
      ).map((item) => SupportMessage.fromJson(_map(item))).toList(),
      unreadForAdmin: _int(json['unreadForAdmin']),
      unreadForStudent: _int(json['unreadForStudent']),
      lastMessageAt: _date(json['lastMessageAt']),
      lastMessagePreview: _string(json['lastMessagePreview']),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<dynamic> _list(Object? value) => value is List ? value : const [];

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString();
  return text == null || text.isEmpty ? fallback : text;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _date(Object? value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}
