import 'package:flutter/material.dart'
    show MaterialApp, Scaffold, Size, StatefulBuilder;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zabtec_scholarship/src/app.dart';
import 'package:zabtec_scholarship/src/data/pakistan_districts.dart';
import 'package:zabtec_scholarship/src/models.dart';
import 'package:zabtec_scholarship/src/screens/auth_screen.dart';
import 'package:zabtec_scholarship/src/screens/sections/documents_section.dart';
import 'package:zabtec_scholarship/src/screens/sections/education_section.dart';
import 'package:zabtec_scholarship/src/screens/sections/personal_section.dart';
import 'package:zabtec_scholarship/src/screens/sections/services_section.dart';
import 'package:zabtec_scholarship/src/services/api_client.dart';
import 'package:zabtec_scholarship/src/widgets/common.dart';

void main() {
  test('API client defaults to the live production backend', () {
    expect(ApiClient().baseUrl, 'https://apiapply.zabtec.co/api/v1');
  });

  testWidgets('app opens the unified backend login screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ScholarshipApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('CNIC'), findsOneWidget);
    expect(find.text('Student'), findsNothing);
    expect(find.text('HEC / Admin'), findsNothing);
  });

  testWidgets('login presents a student-only sign-in experience', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          api: ApiClient(baseUrl: 'http://localhost:5000/api/v1'),
          onAuthenticated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CNIC'), findsOneWidget);
    expect(
      find.text(
        'Enter your CNIC and password to access your scholarship application.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('HEC'), findsNothing);
    expect(find.textContaining('admin'), findsNothing);
  });

  testWidgets('authentication supports five languages', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          api: ApiClient(baseUrl: 'http://localhost:5000/api/v1'),
          onAuthenticated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    for (final language in ['اردو', 'Italiano', 'Azərbaycanca', 'Français']) {
      expect(find.text(language), findsOneWidget);
    }

    await tester.tap(find.text('Français').last);
    await tester.pumpAndSettle();
    expect(find.text('Se connecter'), findsWidgets);
    expect(find.text('CNIC'), findsOneWidget);
  });

  testWidgets('student signup requests password confirmation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          api: ApiClient(baseUrl: 'http://localhost:5000/api/v1'),
          onAuthenticated: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });

  testWidgets('education starts with one backend entry form', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EducationSection(
            application: null,
            onSaved: (_) async {},
            onRequirementsChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Qualification 1'), findsOneWidget);
    expect(find.text('Add another qualification'), findsOneWidget);
  });

  testWidgets('documents render backend document slots', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DocumentsSection(
            educationRequirements: const [
              EducationDocumentRequirement(
                id: 1,
                level: 'BS / Bachelor’s',
                status: 'Completed',
              ),
            ],
            documents: const [],
            onUpload: (_, _) async {},
            onDelete: (_) async {},
            onSaved: () async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CNIC front'), findsOneWidget);
    expect(find.text('CNIC back'), findsOneWidget);
    expect(find.text('Bachelor’s certificate'), findsOneWidget);
  });

  testWidgets('challan generation waits for stamped-copy approval', (
    tester,
  ) async {
    final progress = ApplicationProgress()
      ..personal = true
      ..family = true
      ..education = true
      ..experience = true
      ..research = true
      ..documents = true;
    ActivationReceipt? receipt;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ServicesSection(
              account: _account,
              application: null,
              progress: progress,
              receipt: receipt,
              onPaymentChanged: (value) => setState(() => receipt = value),
              onPayActivation: ({method = 'bank_transfer'}) async =>
                  ActivationReceipt(
                    receiptNumber: '2606170000303',
                    account: _account,
                    issuedAt: DateTime(2026, 6, 25),
                    amountPkr: 1500,
                    paymentMethod: method,
                    cardLast4: '',
                  ),
              onUploadProof: (_) async => receipt!,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Registration fee challan'), findsWidgets);
    await tester.ensureVisible(find.text('Generate challan'));
    await tester.tap(find.text('Generate challan'));
    await tester.pumpAndSettle();

    expect(find.text('Awaiting bank payment'), findsWidgets);
    expect(find.text('Save challan PDF'), findsOneWidget);
    expect(find.text('Upload stamped challan'), findsOneWidget);
    expect(progress.payment, isFalse);
  });

  testWidgets('profile separates permanent and current address', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PersonalSection(
            account: _account,
            application: null,
            onSaved: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Permanent address'), findsOneWidget);
    expect(find.text('Current address'), findsNothing);
    final sameAddress = find.text(
      'Current address is the same as permanent address',
    );
    await tester.ensureVisible(sameAddress);
    await tester.tap(sameAddress);
    await tester.pumpAndSettle();
    expect(find.text('Current address'), findsOneWidget);
  });

  for (final size in [
    const Size(390, 844),
    const Size(800, 600),
    const Size(1440, 900),
  ]) {
    testWidgets('login renders without overflow at ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const ScholarshipApp());
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsWidgets);
    });
  }

  test('validates Pakistani identity fields', () {
    expect(validateCnic('3520212345671'), isNull);
    expect(validateCnic('352021234567'), isNotNull);
    expect(validatePakPhone('3311234567'), isNull);
    expect(validatePakPhone('0311234567'), isNotNull);
    expect(validateEmail('student@example.com'), isNull);
    expect(validateEmail('student@'), isNotNull);
    expect(validatePassword('Scholar1'), isNull);
    expect(validatePassword('password'), isNotNull);
  });

  test('formats activation receipt amount', () {
    final receipt = ActivationReceipt(
      receiptNumber: 'ZAB-1',
      account: _account,
      issuedAt: DateTime(2026, 6, 25),
      amountPkr: 1500,
      paymentMethod: 'bank_transfer',
      cardLast4: '',
    );

    expect(receipt.amountLabel, 'PKR 1,500');
  });

  test('payment unlocks only after ZABTEC approval', () {
    ActivationReceipt payment(String status) => ActivationReceipt(
      receiptNumber: '2606170000303',
      account: _account,
      issuedAt: DateTime(2026, 6, 25),
      amountPkr: 1500,
      paymentMethod: 'bank_transfer',
      cardLast4: '',
      status: status,
    );

    expect(payment('awaiting_payment').isApproved, isFalse);
    expect(payment('proof_submitted').isApproved, isFalse);
    expect(payment('rejected').isApproved, isFalse);
    expect(payment('approved').isApproved, isTrue);
  });

  test('includes the official district dataset by region', () {
    expect(pakistanDistricts.keys, containsAll(pakistanRegions));
    expect(
      pakistanDistricts.values.fold<int>(
        0,
        (total, list) => total + list.length,
      ),
      156,
    );
    expect(pakistanDistricts['Punjab'], contains('Lahore'));
    expect(pakistanDistricts['Gilgit-Baltistan'], contains('Skardu'));
  });
}

const _account = Account(
  id: 'student-1',
  fullName: 'Ayesha Khan',
  cnic: '3520212345671',
  phone: '+923311234567',
  email: 'ayesha@example.com',
  role: 'student',
);
