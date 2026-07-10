import 'dart:convert';
import 'dart:typed_data';

import '../models.dart';

abstract final class DemoProfile {
  static const enabled = bool.fromEnvironment('DEMO_DATA', defaultValue: false);

  static const account = Account(
    id: 'demo-student',
    fullName: 'Ayesha Fatima Khan',
    cnic: '3520212345671',
    phone: '+923331234567',
    email: 'ayesha.fatima@demo.pk',
    role: 'student',
    password: 'Scholar1',
  );

  static const signupPhoneDigits = '3331234567';
  static const dob = '14/08/2004';
  static const gender = 'Female';
  static const maritalStatus = 'Single';
  static const disabilityStatus = 'No disability';
  static const domicileRegion = 'Punjab';
  static const domicileDistrict = 'Lahore';

  static const permanentRegion = 'Punjab';
  static const permanentDistrict = 'Lahore';
  static const permanentStreet = 'House 42, Street 6, Johar Town';
  static const permanentCity = 'Lahore';
  static const permanentPostalCode = '54000';

  static const currentRegion = 'Punjab';
  static const currentDistrict = 'Lahore';
  static const currentStreet = permanentStreet;
  static const currentCity = permanentCity;
  static const currentPostalCode = permanentPostalCode;

  static const father = DemoParent(
    fullName: 'Muhammad Saleem Khan',
    cnic: '3520212345672',
    dob: '05/03/1974',
    education: 'Bachelor’s',
    occupation: 'School Teacher',
    monthlyIncome: '85000',
    phone: '3337654321',
  );

  static const mother = DemoParent(
    fullName: 'Nusrat Bibi',
    cnic: '3520212345673',
    dob: '11/09/1978',
    education: 'Intermediate / A-Level',
    occupation: 'Homemaker',
    monthlyIncome: '0',
    phone: '3329876543',
  );

  static const guardianName = 'Rashid Mahmood';
  static const guardianRelationship = 'Uncle';
  static const guardianCnic = '3520212345674';
  static const guardianPhone = '3341122334';
  static const householdMembers = '6';
  static const dependentMembers = '4';
  static const studentsInHousehold = '3';
  static const householdIncome = '85000';
  static const housingStatus = 'Rented';
  static const incomeSource = 'Salary';
  static const familyCircumstances =
      'Applicant is supported by a single household income and has two siblings currently studying.';

  static const education = [
    DemoEducation(
      level: 'Matric / SSC',
      status: 'Completed',
      programme: 'Science',
      institute: 'Government Girls High School, Lahore',
      board: 'BISE Lahore',
      registrationNumber: 'LHR-SSC-2022-44567',
      completionYear: '2022',
      grading: 'Percentage',
      obtainedMarks: '1020',
      totalMarks: '1100',
      percentage: '92.73',
    ),
    DemoEducation(
      level: 'FSc / HSSC',
      status: 'Completed',
      programme: 'Pre-Engineering',
      institute: 'Punjab College for Women, Lahore',
      board: 'BISE Lahore',
      registrationNumber: 'LHR-HSSC-2024-77881',
      completionYear: '2024',
      grading: 'Percentage',
      obtainedMarks: '996',
      totalMarks: '1100',
      percentage: '90.55',
    ),
  ];

  static const experience = DemoExperience(
    organization: 'Alkhidmat Foundation Lahore',
    role: 'Volunteer Tutor',
    type: 'Volunteer work',
    startDate: '06/2023',
    endDate: '08/2023',
    current: false,
    description:
        'Taught mathematics and computer basics to secondary school students during a summer learning camp.',
  );

  static const cardNumber = '4242424242424242';
  static const cardExpiry = '12/30';
  static const cardCvv = '123';

  static const documentPlaceholderName = 'Demo placeholder — upload later';
  static Uint8List get documentPlaceholderBytes => base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
  );
}

class DemoParent {
  const DemoParent({
    required this.fullName,
    required this.cnic,
    required this.dob,
    required this.education,
    required this.occupation,
    required this.monthlyIncome,
    required this.phone,
  });

  final String fullName;
  final String cnic;
  final String dob;
  final String education;
  final String occupation;
  final String monthlyIncome;
  final String phone;
}

class DemoEducation {
  const DemoEducation({
    required this.level,
    required this.status,
    required this.programme,
    required this.institute,
    required this.board,
    required this.registrationNumber,
    required this.completionYear,
    required this.grading,
    this.obtainedMarks,
    this.totalMarks,
    this.percentage,
    this.gpa,
    this.gpaScale,
    this.grade,
  });

  final String level;
  final String status;
  final String programme;
  final String institute;
  final String board;
  final String registrationNumber;
  final String completionYear;
  final String grading;
  final String? obtainedMarks;
  final String? totalMarks;
  final String? percentage;
  final String? gpa;
  final String? gpaScale;
  final String? grade;
}

class DemoExperience {
  const DemoExperience({
    required this.organization,
    required this.role,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.current,
    required this.description,
  });

  final String organization;
  final String role;
  final String type;
  final String startDate;
  final String endDate;
  final bool current;
  final String description;
}
