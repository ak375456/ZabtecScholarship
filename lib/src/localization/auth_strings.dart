enum AppLanguage {
  english('en', 'English'),
  urdu('ur', 'اردو'),
  italian('it', 'Italiano'),
  azerbaijani('az', 'Azərbaycanca'),
  french('fr', 'Français');

  const AppLanguage(this.code, this.label);

  final String code;
  final String label;

  bool get isRtl => this == AppLanguage.urdu;
}

class AuthStrings {
  const AuthStrings(this.language);

  final AppLanguage language;

  String get(String key) =>
      _values[language]?[key] ?? _values[AppLanguage.english]![key] ?? key;

  static const _values = <AppLanguage, Map<String, String>>{
    AppLanguage.english: {
      'language': 'Language',
      'signIn': 'Sign in',
      'signingIn': 'Signing in...',
      'loginHelp':
          'Students enter a CNIC. HEC and admin users enter an email address.',
      'identifier': 'CNIC or email address',
      'identifierHint': '3520212345671 or name@example.com',
      'identifierRequired': 'Enter your CNIC or email address',
      'identifierInvalid': 'Enter a valid 13-digit CNIC or email address',
      'password': 'Password',
      'passwordRequired': 'Enter Password',
      'showPassword': 'Show password',
      'hidePassword': 'Hide password',
      'studentApplicant': 'Student applicant?',
      'createAccount': 'Create account',
      'createStudentAccount': 'Create student account',
      'creatingAccount': 'Creating account...',
      'signupHelp': 'Admin and HEC accounts are created from the admin portal.',
      'fullName': 'Full name',
      'nameHint': 'Name as shown on CNIC',
      'completeName': 'Enter your complete name',
      'cnic': 'CNIC',
      'cnicHint': '13 digits without dashes',
      'cnicInvalid': 'Enter a valid 13-digit CNIC',
      'phone': 'Phone number',
      'phoneInvalid': 'Enter a valid Pakistani phone number after +92',
      'email': 'Email address',
      'emailInvalid': 'Enter a valid email address',
      'confirmPassword': 'Confirm password',
      'confirmRequired': 'Enter Password confirmation',
      'passwordsMismatch': 'Passwords do not match',
      'passwordHelp': '8+ characters with upper, lower-case and number',
      'passwordInvalid': 'Use 8+ characters with upper, lower-case and number',
      'alreadyRegistered': 'Already registered?',
      'legalNotice':
          'By continuing, you agree to our terms and acknowledge our privacy policy.',
      'terms': 'Terms & Conditions',
      'privacy': 'Privacy Policy',
      'openFailed': 'Could not open {page}. Please try again.',
      'connectionFailed':
          'Could not connect to the service. Check your internet connection or contact support.',
      'storyTitle':
          'One secure portal for students, HEC reviewers, and admins.',
      'storyBody':
          'Sign in securely, complete your application, upload documents, pay the activation fee, and track review decisions.',
      'secureSession': 'Secure account session',
      'liveStatus': 'Live application status',
      'rolePortals': 'Role-based portals after login',
    },
    AppLanguage.urdu: {
      'language': 'زبان',
      'signIn': 'سائن اِن',
      'signingIn': 'سائن اِن ہو رہا ہے...',
      'loginHelp':
          'طلبہ شناختی کارڈ نمبر درج کریں۔ HEC اور ایڈمن صارفین ای میل درج کریں۔',
      'identifier': 'شناختی کارڈ نمبر یا ای میل',
      'identifierHint': '3520212345671 یا name@example.com',
      'identifierRequired': 'اپنا شناختی کارڈ نمبر یا ای میل درج کریں',
      'identifierInvalid':
          'درست 13 ہندسوں کا شناختی کارڈ نمبر یا ای میل درج کریں',
      'password': 'پاس ورڈ',
      'passwordRequired': 'پاس ورڈ درج کریں',
      'showPassword': 'پاس ورڈ دکھائیں',
      'hidePassword': 'پاس ورڈ چھپائیں',
      'studentApplicant': 'طالب علم درخواست گزار؟',
      'createAccount': 'اکاؤنٹ بنائیں',
      'createStudentAccount': 'طالب علم کا اکاؤنٹ بنائیں',
      'creatingAccount': 'اکاؤنٹ بنایا جا رہا ہے...',
      'signupHelp': 'ایڈمن اور HEC اکاؤنٹس ایڈمن پورٹل سے بنائے جاتے ہیں۔',
      'fullName': 'پورا نام',
      'nameHint': 'شناختی کارڈ کے مطابق نام',
      'completeName': 'اپنا پورا نام درج کریں',
      'cnic': 'شناختی کارڈ نمبر',
      'cnicHint': 'بغیر ڈیش کے 13 ہندسے',
      'cnicInvalid': 'درست 13 ہندسوں کا شناختی کارڈ نمبر درج کریں',
      'phone': 'فون نمبر',
      'phoneInvalid': '+92 کے بعد درست پاکستانی فون نمبر درج کریں',
      'email': 'ای میل ایڈریس',
      'emailInvalid': 'درست ای میل ایڈریس درج کریں',
      'confirmPassword': 'پاس ورڈ کی تصدیق',
      'confirmRequired': 'پاس ورڈ کی تصدیق درج کریں',
      'passwordsMismatch': 'پاس ورڈ ایک جیسے نہیں ہیں',
      'passwordHelp': 'کم از کم 8 حروف، بڑے اور چھوٹے حروف اور ایک عدد',
      'passwordInvalid':
          'کم از کم 8 حروف، بڑے اور چھوٹے حروف اور ایک عدد استعمال کریں',
      'alreadyRegistered': 'پہلے سے رجسٹرڈ ہیں؟',
      'legalNotice':
          'جاری رکھ کر آپ ہماری شرائط اور رازداری کی پالیسی سے اتفاق کرتے ہیں۔',
      'terms': 'شرائط و ضوابط',
      'privacy': 'رازداری کی پالیسی',
      'openFailed': '{page} نہیں کھل سکا۔ دوبارہ کوشش کریں۔',
      'connectionFailed':
          'سروس سے رابطہ نہیں ہو سکا۔ انٹرنیٹ چیک کریں یا سپورٹ سے رابطہ کریں۔',
      'storyTitle': 'طلبہ، HEC جائزہ کاروں اور ایڈمن کے لیے ایک محفوظ پورٹل۔',
      'storyBody':
          'محفوظ طریقے سے سائن اِن کریں، درخواست مکمل کریں، دستاویزات اپ لوڈ کریں اور پیش رفت دیکھیں۔',
      'secureSession': 'محفوظ اکاؤنٹ سیشن',
      'liveStatus': 'درخواست کی تازہ صورتحال',
      'rolePortals': 'سائن اِن کے بعد کردار کے مطابق پورٹل',
    },
    AppLanguage.italian: {
      'language': 'Lingua',
      'signIn': 'Accedi',
      'signingIn': 'Accesso in corso...',
      'loginHelp':
          'Gli studenti inseriscono il CNIC. Gli utenti HEC e admin inseriscono un indirizzo email.',
      'identifier': 'CNIC o indirizzo email',
      'identifierHint': '3520212345671 o nome@esempio.com',
      'identifierRequired': 'Inserisci il CNIC o l’indirizzo email',
      'identifierInvalid':
          'Inserisci un CNIC valido di 13 cifre o un indirizzo email valido',
      'password': 'Password',
      'passwordRequired': 'Inserisci la password',
      'showPassword': 'Mostra password',
      'hidePassword': 'Nascondi password',
      'studentApplicant': 'Sei uno studente?',
      'createAccount': 'Crea account',
      'createStudentAccount': 'Crea un account studente',
      'creatingAccount': 'Creazione account...',
      'signupHelp':
          'Gli account admin e HEC vengono creati dal portale amministrativo.',
      'fullName': 'Nome completo',
      'nameHint': 'Nome riportato sul CNIC',
      'completeName': 'Inserisci il nome completo',
      'cnic': 'CNIC',
      'cnicHint': '13 cifre senza trattini',
      'cnicInvalid': 'Inserisci un CNIC valido di 13 cifre',
      'phone': 'Numero di telefono',
      'phoneInvalid': 'Inserisci un numero pakistano valido dopo +92',
      'email': 'Indirizzo email',
      'emailInvalid': 'Inserisci un indirizzo email valido',
      'confirmPassword': 'Conferma password',
      'confirmRequired': 'Conferma la password',
      'passwordsMismatch': 'Le password non corrispondono',
      'passwordHelp': 'Almeno 8 caratteri con maiuscola, minuscola e numero',
      'passwordInvalid':
          'Usa almeno 8 caratteri con maiuscola, minuscola e numero',
      'alreadyRegistered': 'Hai già un account?',
      'legalNotice':
          'Continuando, accetti i nostri termini e la nostra informativa sulla privacy.',
      'terms': 'Termini e condizioni',
      'privacy': 'Informativa sulla privacy',
      'openFailed': 'Impossibile aprire {page}. Riprova.',
      'connectionFailed':
          'Impossibile connettersi al servizio. Controlla Internet o contatta l’assistenza.',
      'storyTitle':
          'Un portale sicuro per studenti, revisori HEC e amministratori.',
      'storyBody':
          'Accedi in sicurezza, completa la domanda, carica i documenti e monitora le decisioni.',
      'secureSession': 'Sessione account sicura',
      'liveStatus': 'Stato della domanda in tempo reale',
      'rolePortals': 'Portali basati sul ruolo dopo l’accesso',
    },
    AppLanguage.azerbaijani: {
      'language': 'Dil',
      'signIn': 'Daxil ol',
      'signingIn': 'Daxil olunur...',
      'loginHelp':
          'Tələbələr CNIC, HEC və admin istifadəçiləri isə e-poçt ünvanı daxil edir.',
      'identifier': 'CNIC və ya e-poçt ünvanı',
      'identifierHint': '3520212345671 və ya ad@example.com',
      'identifierRequired': 'CNIC və ya e-poçt ünvanınızı daxil edin',
      'identifierInvalid':
          'Etibarlı 13 rəqəmli CNIC və ya e-poçt ünvanı daxil edin',
      'password': 'Şifrə',
      'passwordRequired': 'Şifrəni daxil edin',
      'showPassword': 'Şifrəni göstər',
      'hidePassword': 'Şifrəni gizlət',
      'studentApplicant': 'Tələbə müraciətçisiniz?',
      'createAccount': 'Hesab yarat',
      'createStudentAccount': 'Tələbə hesabı yarat',
      'creatingAccount': 'Hesab yaradılır...',
      'signupHelp': 'Admin və HEC hesabları admin portalından yaradılır.',
      'fullName': 'Tam ad',
      'nameHint': 'CNIC-də göstərilən ad',
      'completeName': 'Tam adınızı daxil edin',
      'cnic': 'CNIC',
      'cnicHint': 'Tiresiz 13 rəqəm',
      'cnicInvalid': 'Etibarlı 13 rəqəmli CNIC daxil edin',
      'phone': 'Telefon nömrəsi',
      'phoneInvalid': '+92-dən sonra etibarlı Pakistan nömrəsi daxil edin',
      'email': 'E-poçt ünvanı',
      'emailInvalid': 'Etibarlı e-poçt ünvanı daxil edin',
      'confirmPassword': 'Şifrəni təsdiqləyin',
      'confirmRequired': 'Şifrə təsdiqini daxil edin',
      'passwordsMismatch': 'Şifrələr uyğun gəlmir',
      'passwordHelp': 'Böyük, kiçik hərf və rəqəm ilə ən azı 8 simvol',
      'passwordInvalid':
          'Böyük, kiçik hərf və rəqəm ilə ən azı 8 simvol istifadə edin',
      'alreadyRegistered': 'Artıq qeydiyyatdan keçmisiniz?',
      'legalNotice':
          'Davam etməklə şərtlərimizi və məxfilik siyasətimizi qəbul edirsiniz.',
      'terms': 'Şərtlər və qaydalar',
      'privacy': 'Məxfilik siyasəti',
      'openFailed': '{page} açıla bilmədi. Yenidən cəhd edin.',
      'connectionFailed':
          'Xidmətə qoşulmaq mümkün olmadı. İnterneti yoxlayın və ya dəstəklə əlaqə saxlayın.',
      'storyTitle':
          'Tələbələr, HEC rəyçiləri və adminlər üçün vahid təhlükəsiz portal.',
      'storyBody':
          'Təhlükəsiz daxil olun, müraciəti tamamlayın, sənədləri yükləyin və qərarları izləyin.',
      'secureSession': 'Təhlükəsiz hesab sessiyası',
      'liveStatus': 'Canlı müraciət statusu',
      'rolePortals': 'Girişdən sonra rola uyğun portallar',
    },
    AppLanguage.french: {
      'language': 'Langue',
      'signIn': 'Se connecter',
      'signingIn': 'Connexion...',
      'loginHelp':
          'Les étudiants saisissent un CNIC. Les utilisateurs HEC et admin saisissent une adresse e-mail.',
      'identifier': 'CNIC ou adresse e-mail',
      'identifierHint': '3520212345671 ou nom@exemple.com',
      'identifierRequired': 'Saisissez votre CNIC ou votre adresse e-mail',
      'identifierInvalid':
          'Saisissez un CNIC valide à 13 chiffres ou une adresse e-mail valide',
      'password': 'Mot de passe',
      'passwordRequired': 'Saisissez le mot de passe',
      'showPassword': 'Afficher le mot de passe',
      'hidePassword': 'Masquer le mot de passe',
      'studentApplicant': 'Candidat étudiant ?',
      'createAccount': 'Créer un compte',
      'createStudentAccount': 'Créer un compte étudiant',
      'creatingAccount': 'Création du compte...',
      'signupHelp':
          'Les comptes admin et HEC sont créés depuis le portail administrateur.',
      'fullName': 'Nom complet',
      'nameHint': 'Nom figurant sur le CNIC',
      'completeName': 'Saisissez votre nom complet',
      'cnic': 'CNIC',
      'cnicHint': '13 chiffres sans tirets',
      'cnicInvalid': 'Saisissez un CNIC valide à 13 chiffres',
      'phone': 'Numéro de téléphone',
      'phoneInvalid': 'Saisissez un numéro pakistanais valide après +92',
      'email': 'Adresse e-mail',
      'emailInvalid': 'Saisissez une adresse e-mail valide',
      'confirmPassword': 'Confirmer le mot de passe',
      'confirmRequired': 'Confirmez le mot de passe',
      'passwordsMismatch': 'Les mots de passe ne correspondent pas',
      'passwordHelp':
          '8 caractères minimum avec majuscule, minuscule et chiffre',
      'passwordInvalid':
          'Utilisez au moins 8 caractères avec majuscule, minuscule et chiffre',
      'alreadyRegistered': 'Déjà inscrit ?',
      'legalNotice':
          'En continuant, vous acceptez nos conditions et notre politique de confidentialité.',
      'terms': 'Conditions générales',
      'privacy': 'Politique de confidentialité',
      'openFailed': 'Impossible d’ouvrir {page}. Veuillez réessayer.',
      'connectionFailed':
          'Impossible de se connecter au service. Vérifiez Internet ou contactez l’assistance.',
      'storyTitle':
          'Un portail sécurisé pour les étudiants, les évaluateurs HEC et les administrateurs.',
      'storyBody':
          'Connectez-vous en toute sécurité, complétez votre demande, téléversez vos documents et suivez les décisions.',
      'secureSession': 'Session de compte sécurisée',
      'liveStatus': 'Statut de la demande en direct',
      'rolePortals': 'Portails adaptés au rôle après connexion',
    },
  };
}
