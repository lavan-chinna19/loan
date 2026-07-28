import 'package:flutter/material.dart';

enum AppLanguage { english, telugu }

class LanguageNotifier extends ChangeNotifier {
  AppLanguage _currentLanguage = AppLanguage.english;

  AppLanguage get currentLanguage => _currentLanguage;

  bool get isTelugu => _currentLanguage == AppLanguage.telugu;

  void toggleLanguage() {
    _currentLanguage = _currentLanguage == AppLanguage.english 
        ? AppLanguage.telugu 
        : AppLanguage.english;
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    _currentLanguage = language;
    notifyListeners();
  }

  String translate(String key) {
    return _translations[key]?[_currentLanguage] ?? key;
  }
}

// Global translations dictionary
final Map<String, Map<AppLanguage, String>> _translations = {
  'app_title': {
    AppLanguage.english: 'Loan Pro Management',
    AppLanguage.telugu: 'లోన్ ప్రో మేనేజ్‌మెంట్',
  },
  'login_title': {
    AppLanguage.english: 'Welcome Back',
    AppLanguage.telugu: 'స్వాగతం',
  },
  'login_subtitle': {
    AppLanguage.english: 'Sign in to manage loans and collections',
    AppLanguage.telugu: 'రుణాలు మరియు వసూళ్లను నిర్వహించడానికి సైన్ ఇన్ చేయండి',
  },
  'username': {
    AppLanguage.english: 'Username',
    AppLanguage.telugu: 'యూజర్ నేమ్',
  },
  'password': {
    AppLanguage.english: 'Password',
    AppLanguage.telugu: 'పాస్‌వర్డ్',
  },
  'login_button': {
    AppLanguage.english: 'LOGIN',
    AppLanguage.telugu: 'లాగిన్ అవ్వండి',
  },
  'logging_in': {
    AppLanguage.english: 'Logging in...',
    AppLanguage.telugu: 'లాగిన్ అవుతోంది...',
  },
  'dashboard': {
    AppLanguage.english: 'Dashboard',
    AppLanguage.telugu: 'డ్యాష్‌బోర్డ్',
  },
  'borrowers': {
    AppLanguage.english: 'Borrowers',
    AppLanguage.telugu: 'రుణగ్రహీతలు',
  },
  'loans': {
    AppLanguage.english: 'Loans',
    AppLanguage.telugu: 'రుణాలు',
  },
  'payments': {
    AppLanguage.english: 'Payments',
    AppLanguage.telugu: 'చెల్లింపులు',
  },
  'search_borrower_hint': {
    AppLanguage.english: 'Search by name or phone...',
    AppLanguage.telugu: 'పేరు లేదా ఫోన్ ద్వారా వెతకండి...',
  },
  'register_borrower': {
    AppLanguage.english: 'Register Borrower',
    AppLanguage.telugu: 'రుణగ్రహీత నమోదు',
  },
  'first_name': {
    AppLanguage.english: 'First Name',
    AppLanguage.telugu: 'మొదటి పేరు',
  },
  'last_name': {
    AppLanguage.english: 'Last Name',
    AppLanguage.telugu: 'చివరి పేరు',
  },
  'phone_number': {
    AppLanguage.english: 'Phone Number',
    AppLanguage.telugu: 'ఫోన్ నంబర్',
  },
  'alternative_phone': {
    AppLanguage.english: 'Alternative Phone',
    AppLanguage.telugu: 'ప్రత్యామ్నాయ ఫోన్',
  },
  'address': {
    AppLanguage.english: 'Address',
    AppLanguage.telugu: 'చిరునామా',
  },
  'submit': {
    AppLanguage.english: 'Submit',
    AppLanguage.telugu: 'సమర్పించండి',
  },
  'create_loan': {
    AppLanguage.english: 'Create New Loan',
    AppLanguage.telugu: 'కొత్త రుణం సృష్టించండి',
  },
  'principal_amount': {
    AppLanguage.english: 'Principal Amount (₹)',
    AppLanguage.telugu: 'అసలు మొత్తం (₹)',
  },
  'interest_model': {
    AppLanguage.english: 'Interest Model',
    AppLanguage.telugu: 'వడ్డీ మోడల్',
  },
  'model_a_label': {
    AppLanguage.english: 'Model A: Flat EMI (Monthly)',
    AppLanguage.telugu: 'మోడల్ ఎ: ఫ్లాట్ ఈఎంఐ (నెలవారీ)',
  },
  'model_b_label': {
    AppLanguage.english: 'Model B: 10-for-12 (Weekly)',
    AppLanguage.telugu: 'మోడల్ బి: 10-కి-12 (వారపు)',
  },
  'interest_rate_monthly': {
    AppLanguage.english: 'Monthly Interest Rate (%)',
    AppLanguage.telugu: 'నెలవారీ వడ్డీ రేటు (%)',
  },
  'tenure': {
    AppLanguage.english: 'Tenure',
    AppLanguage.telugu: 'వ్యవధి',
  },
  'preview_schedule': {
    AppLanguage.english: 'Preview Schedule',
    AppLanguage.telugu: 'షెడ్యూల్ ప్రివ్యూ',
  },
  'disburse_date': {
    AppLanguage.english: 'Disbursement Date',
    AppLanguage.telugu: 'పంపిణీ తేదీ',
  },
  'total_repayable': {
    AppLanguage.english: 'Total Repayable',
    AppLanguage.telugu: 'మొత్తం చెల్లించవలసినది',
  },
  'save_loan': {
    AppLanguage.english: 'Create Loan (Pending)',
    AppLanguage.telugu: 'రుణాన్ని సృష్టించండి (పెండింగ్)',
  },
  'approve_loan': {
    AppLanguage.english: 'Approve & Disburse Loan',
    AppLanguage.telugu: 'రుణాన్ని ఆమోదించండి & పంపిణీ చేయండి',
  },
  'loan_status_pending': {
    AppLanguage.english: 'PENDING',
    AppLanguage.telugu: 'పెండింగ్',
  },
  'loan_status_active': {
    AppLanguage.english: 'ACTIVE',
    AppLanguage.telugu: 'యాక్టివ్',
  },
  'loan_status_fully_paid': {
    AppLanguage.english: 'FULLY PAID',
    AppLanguage.telugu: 'పూర్తిగా చెల్లించబడింది',
  },
  'loan_status_defaulted': {
    AppLanguage.english: 'DEFAULTED',
    AppLanguage.telugu: 'డిఫాల్ట్ అయింది',
  },
  'collect_payment': {
    AppLanguage.english: 'Collect Payment',
    AppLanguage.telugu: 'వసూలు చేయండి',
  },
  'amount_to_pay': {
    AppLanguage.english: 'Amount to Collect (₹)',
    AppLanguage.telugu: 'వసూలు చేయాల్సిన మొత్తం (₹)',
  },
  'payment_method': {
    AppLanguage.english: 'Payment Method',
    AppLanguage.telugu: 'చెల్లింపు పద్ధతి',
  },
  'cash': {
    AppLanguage.english: 'Cash',
    AppLanguage.telugu: 'నగదు',
  },
  'upi': {
    AppLanguage.english: 'UPI / Digital',
    AppLanguage.telugu: 'UPI / డిజిటల్',
  },
  'reference_no': {
    AppLanguage.english: 'UPI Ref No (Optional)',
    AppLanguage.telugu: 'UPI రిఫరెన్స్ నంబర్',
  },
  'remarks': {
    AppLanguage.english: 'Remarks',
    AppLanguage.telugu: 'వ్యాఖ్యలు',
  },
  'payment_saved': {
    AppLanguage.english: 'Payment recorded successfully!',
    AppLanguage.telugu: 'చెల్లింపు విజయవంతంగా నమోదు చేయబడింది!',
  },
  'share_whatsapp': {
    AppLanguage.english: 'Share Receipt on WhatsApp',
    AppLanguage.telugu: 'వాట్సాప్‌లో రశీదును షేర్ చేయండి',
  },
  'outstanding_balance': {
    AppLanguage.english: 'Outstanding Balance',
    AppLanguage.telugu: 'బకాయి బ్యాలెన్స్',
  },
  'total_collected': {
    AppLanguage.english: 'Total Collected',
    AppLanguage.telugu: 'మొత్తం వసూలు చేసింది',
  },
  'installment_no': {
    AppLanguage.english: 'Inst #',
    AppLanguage.telugu: 'వాయిదా #',
  },
  'due_date': {
    AppLanguage.english: 'Due Date',
    AppLanguage.telugu: 'గడువు తేదీ',
  },
  'status': {
    AppLanguage.english: 'Status',
    AppLanguage.telugu: 'స్థితి',
  },
  'trigger_rollovers': {
    AppLanguage.english: 'Trigger Rollover Check',
    AppLanguage.telugu: 'రోల్‌ఓవర్ తనిఖీని రన్ చేయి',
  },
  'logout': {
    AppLanguage.english: 'Logout',
    AppLanguage.telugu: 'లాగ్ అవుట్',
  },
};
