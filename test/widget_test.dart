import 'package:flutter/material.dart'
    show MaterialApp, Scaffold, Size, StatefulBuilder, TextFormField;
import 'package:flutter_test/flutter_test.dart';
import 'package:zabtec_scholarship/src/app.dart';
import 'package:zabtec_scholarship/src/data/pakistan_districts.dart';
import 'package:zabtec_scholarship/src/models.dart';
import 'package:zabtec_scholarship/src/screens/sections/documents_section.dart';
import 'package:zabtec_scholarship/src/screens/sections/education_section.dart';
import 'package:zabtec_scholarship/src/screens/sections/personal_section.dart';
import 'package:zabtec_scholarship/src/screens/sections/services_section.dart';
import 'package:zabtec_scholarship/src/screens/portal_screen.dart';
import 'package:zabtec_scholarship/src/widgets/common.dart';

void main() {
  testWidgets('landing screen opens authentication', (tester) async {
    await tester.pumpWidget(const ScholarshipApp());
    await tester.pumpAndSettle();

    expect(find.text('Your potential.\nOur scholarship.'), findsOneWidget);
    expect(find.text('Begin application'), findsOneWidget);

    await tester.tap(find.text('Begin application'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('signup requests a password', (tester) async {
    await tester.pumpWidget(const ScholarshipApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Begin application'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
  });

  testWidgets('education starts with Pakistani demo qualifications', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EducationSection(onSaved: () {}, onRequirementsChanged: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Qualification 1'), findsOneWidget);
    expect(find.text('Qualification 2'), findsOneWidget);
    expect(find.text('Government Girls High School, Lahore'), findsOneWidget);
    expect(find.text('Punjab College for Women, Lahore'), findsOneWidget);
    expect(find.text('Add another qualification'), findsOneWidget);
    expect(find.text('Transcript / result card'), findsNothing);
  });

  testWidgets('documents are generated from education selections', (
    tester,
  ) async {
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
            onSaved: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CNIC front'), findsOneWidget);
    expect(find.text('CNIC back'), findsOneWidget);
    expect(
      find.text('BS / Bachelor’s transcript / result card'),
      findsOneWidget,
    );
    expect(find.text('BS degree / provisional certificate'), findsOneWidget);
    expect(find.text('Demo placeholder — upload later'), findsWidgets);
  });

  testWidgets('mobile portal uses a left menu and welcome empty state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const account = Account(
      fullName: 'Ayesha Khan',
      cnic: '3520212345671',
      phone: '+923311234567',
      email: 'ayesha@example.com',
      password: 'Scholar1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PortalScreen(account: account, onLogout: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Ayesha'), findsOneWidget);
    expect(find.text('No submitted application yet'), findsOneWidget);
    expect(find.byTooltip('Open menu'), findsOneWidget);

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Experience'), findsOneWidget);
    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Services'), findsOneWidget);
  });

  testWidgets(
    'services stay locked until required profile sections are saved',
    (tester) async {
      final progress = ApplicationProgress()
        ..personal = true
        ..education = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServicesSection(
              account: _account,
              progress: progress,
              receipt: null,
              onPaymentCompleted: (_) {},
              onOpenSection: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Services locked for now'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Pay PKR 1,500'), findsNothing);
    },
  );

  testWidgets('services unlock after dummy card payment', (tester) async {
    final progress = ApplicationProgress()
      ..personal = true
      ..family = true
      ..education = true
      ..documents = true;
    ActivationReceipt? receipt;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => ServicesSection(
              account: _account,
              progress: progress,
              receipt: receipt,
              onPaymentCompleted: (value) => setState(() {
                receipt = value;
                progress.servicePaymentComplete = true;
              }),
              onOpenSection: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile activation payment'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(1),
      '4242424242424242',
    );
    await tester.enterText(find.byType(TextFormField).at(2), '12/30');
    await tester.enterText(find.byType(TextFormField).at(3), '123');
    await tester.ensureVisible(find.text('Pay PKR 1,500'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pay PKR 1,500'));
    await tester.pumpAndSettle();

    expect(find.text('Profile active'), findsOneWidget);
    expect(find.text('Save receipt PDF'), findsOneWidget);
  });

  testWidgets('profile separates permanent and current address', (
    tester,
  ) async {
    const account = Account(
      fullName: 'Ayesha Khan',
      cnic: '3520212345671',
      phone: '+923311234567',
      email: 'ayesha@example.com',
      password: 'Scholar1',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PersonalSection(account: account, onSaved: () {}),
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
    await tester.pumpAndSettle();
    await tester.tap(sameAddress);
    await tester.pumpAndSettle();
    expect(find.text('Current address'), findsOneWidget);
  });

  for (final size in [
    const Size(390, 844),
    const Size(800, 600),
    const Size(1440, 900),
  ]) {
    testWidgets('renders without overflow at ${size.width.toInt()} px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const ScholarshipApp());
      await tester.pumpAndSettle();

      expect(find.text('Begin application'), findsOneWidget);
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
      paymentMethod: 'Card payment',
      cardLast4: '4242',
    );

    expect(receipt.amountLabel, 'PKR 1,500');
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
  fullName: 'Ayesha Khan',
  cnic: '3520212345671',
  phone: '+923311234567',
  email: 'ayesha@example.com',
  password: 'Scholar1',
);
