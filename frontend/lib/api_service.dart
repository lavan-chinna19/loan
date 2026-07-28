import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String? _token;
  static String? _userRole;
  static String? _userName;

  static String? get token => _token;
  static String? get userRole => _userRole;
  static String? get userName => _userName;

  // In-Memory Database for Mock UI Mode
  static final List<Map<String, dynamic>> _borrowers = [];
  static final List<Map<String, dynamic>> _loans = [];
  static final List<Map<String, dynamic>> _schedules = [];
  static final List<Map<String, dynamic>> _payments = [];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    _userRole = prefs.getString('user_role');
    _userName = prefs.getString('user_name');

    // Prepopulate database with mock data if empty
    if (_borrowers.isEmpty) {
      _prepopulateDatabase();
    }
  }

  static void _prepopulateDatabase() {
    // 1. Seed Borrowers
    final b1Id = 'b1-uuid-123456';
    final b2Id = 'b2-uuid-123456';
    final b3Id = 'b3-uuid-123456';

    _borrowers.addAll([
      {
        'id': b1Id,
        'first_name_en': 'Ramesh',
        'last_name_en': 'Yadav',
        'phone_number': '9988776655',
        'alternative_phone': '9876543210',
        'address_en': 'Door No 4-12, Main Road, Guntur, AP',
        'status': 'ACTIVE',
      },
      {
        'id': b2Id,
        'first_name_en': 'Venkat',
        'last_name_en': 'Reddy',
        'phone_number': '9988776644',
        'alternative_phone': '9876543211',
        'address_en': 'Plot 45, Jubilee Hills, Hyderabad, TS',
        'status': 'ACTIVE',
      },
      {
        'id': b3Id,
        'first_name_en': 'Rajesh',
        'last_name_en': 'Naidu',
        'phone_number': '9988776633',
        'alternative_phone': null,
        'address_en': 'Ganga Street, Nellore, AP',
        'status': 'ACTIVE',
      }
    ]);

    // 2. Seed a Pending Loan for Ramesh (Model A)
    final l1Id = 'l1-uuid-123456';
    _loans.add({
      'id': l1Id,
      'borrower_id': b1Id,
      'principal_amount': 50000.0,
      'interest_model': 'MODEL_A',
      'interest_rate': 3.0,
      'tenure_value': 12,
      'tenure_unit': 'MONTHS',
      'total_repayable_amount': 68000.0, // 50000 + 18000 interest
      'status': 'PENDING',
      'disbursement_date': DateTime.now().toIso8601String().substring(0, 10),
      'created_by': 'admin-uuid',
      'approved_by': null,
      'created_at': DateTime.now().toIso8601String(),
    });
    // Generate pending schedule (Model A)
    _generateMockSchedules(l1Id, 50000.0, 'MODEL_A', 3.0, 12, DateTime.now());

    // 3. Seed an Active Loan for Venkat (Model B - Weekly 10-for-12)
    final l2Id = 'l2-uuid-123456';
    final l2DisbDate = DateTime.now().subtract(const Duration(days: 14));
    _loans.add({
      'id': l2Id,
      'borrower_id': b2Id,
      'principal_amount': 10000.0,
      'interest_model': 'MODEL_B',
      'interest_rate': 0.0,
      'tenure_value': 12,
      'tenure_unit': 'WEEKS',
      'total_repayable_amount': 12000.0, // 10000 * 1.2
      'status': 'ACTIVE',
      'disbursement_date': l2DisbDate.toIso8601String().substring(0, 10),
      'created_by': 'collector-uuid',
      'approved_by': 'admin-uuid',
      'created_at': l2DisbDate.toIso8601String(),
    });
    // Generate active schedules (Model B) starting 2 weeks ago
    _generateMockSchedules(l2Id, 10000.0, 'MODEL_B', 0.0, 12, l2DisbDate);
    
    // Simulate that the first installment was fully paid, and the second is pending
    final schedules = _schedules.where((s) => s['loan_id'] == l2Id).toList();
    if (schedules.isNotEmpty) {
      schedules[0]['amount_paid'] = 1000.0;
      schedules[0]['status'] = 'PAID';
      
      _payments.add({
        'id': 'p1-uuid-123456',
        'loan_id': l2Id,
        'payment_schedule_id': schedules[0]['id'],
        'collected_by': 'collector-uuid',
        'amount_paid': 1000.0,
        'payment_date': l2DisbDate.add(const Duration(days: 7)).toIso8601String(),
        'payment_method': 'CASH',
        'reference_no': null,
        'remarks': 'First installment paid on time',
        'created_at': l2DisbDate.add(const Duration(days: 7)).toIso8601String(),
      });
    }
  }

  static void _generateMockSchedules(
    String loanId,
    double principal,
    String model,
    double rate,
    int tenure,
    DateTime disbDate
  ) {
    if (model == 'MODEL_A') {
      final totalInterest = principal * (rate / 100) * tenure;
      final totalRepayable = principal + totalInterest;
      
      final double monthlyInterest = (principal * (rate / 100)).roundToDouble();
      final double monthlyPrincipal = (principal / tenure).roundToDouble();
      
      double runningPrincipal = 0.0;
      double runningInterest = 0.0;
      
      for (int i = 1; i <= tenure; i++) {
        final dueDate = DateTime(disbDate.year, disbDate.month + i, disbDate.day);
        
        double pDue = monthlyPrincipal;
        double iDue = monthlyInterest;
        
        if (i < tenure) {
          runningPrincipal += pDue;
          runningInterest += iDue;
        } else {
          // Final adjustment
          pDue = principal - runningPrincipal;
          iDue = totalInterest - runningInterest;
        }
        
        _schedules.add({
          'id': 'sched-${loanId}-$i',
          'loan_id': loanId,
          'installment_no': i,
          'due_date': dueDate.toIso8601String().substring(0, 10),
          'principal_due': pDue,
          'interest_due': iDue,
          'fee_due': 0.0,
          'total_due': pDue + iDue,
          'amount_paid': 0.0,
          'status': 'PENDING',
          'rolled_over_date': null,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } else {
      // Model B - Weekly Fixed Premium 10-for-12
      final totalRepayable = principal * 1.2;
      final totalInterest = totalRepayable - principal;
      
      final double weeklyPrincipal = (principal / tenure).roundToDouble();
      final double weeklyInterest = (totalInterest / tenure).roundToDouble();
      
      double runningPrincipal = 0.0;
      double runningInterest = 0.0;
      
      for (int i = 1; i <= tenure; i++) {
        final dueDate = disbDate.add(Duration(days: 7 * i));
        
        double pDue = weeklyPrincipal;
        double iDue = weeklyInterest;
        
        if (i < tenure) {
          runningPrincipal += pDue;
          runningInterest += iDue;
        } else {
          pDue = principal - runningPrincipal;
          iDue = totalInterest - runningInterest;
        }
        
        _schedules.add({
          'id': 'sched-${loanId}-$i',
          'loan_id': loanId,
          'installment_no': i,
          'due_date': dueDate.toIso8601String().substring(0, 10),
          'principal_due': pDue,
          'interest_due': iDue,
          'fee_due': 0.0,
          'total_due': pDue + iDue,
          'amount_paid': 0.0,
          'status': 'PENDING',
          'rolled_over_date': null,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  // Auth APIs
  static Future<bool> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate networking
    if (username == 'admin' && password == 'admin123') {
      _token = 'mock-jwt-token-admin';
      _userName = 'Srinivas Rao (Admin)';
      _userRole = 'ADMIN';
    } else if (username == 'collector' && password == 'collector123') {
      _token = 'mock-jwt-token-collector';
      _userName = 'Kalyan Kumar (Collector)';
      _userRole = 'COLLECTOR';
    } else {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', _token!);
    await prefs.setString('user_name', _userName!);
    await prefs.setString('user_role', _userRole!);
    return true;
  }

  static Future<void> logout() async {
    _token = null;
    _userName = null;
    _userRole = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_name');
    await prefs.remove('user_role');
  }

  // Borrower CRUD
  static Future<List<dynamic>> getBorrowers({String? query}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (query == null || query.isEmpty) {
      return _borrowers;
    }
    final q = query.toLowerCase();
    return _borrowers.where((b) {
      final firstName = b['first_name_en'].toString().toLowerCase();
      final lastName = b['last_name_en'].toString().toLowerCase();
      final phone = b['phone_number'].toString();
      return firstName.contains(q) || lastName.contains(q) || phone.contains(q);
    }).toList();
  }

  static Future<Map<String, dynamic>> createBorrower(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final phone = data['phone_number'];
    
    if (_borrowers.any((b) => b['phone_number'] == phone)) {
      throw Exception('Borrower with this phone number already exists.');
    }
    
    final newId = 'borrower-id-${DateTime.now().millisecondsSinceEpoch}';
    final borrower = {
      'id': newId,
      'first_name_en': data['first_name_en'],
      'last_name_en': data['last_name_en'],
      'phone_number': phone,
      'alternative_phone': data['alternative_phone'],
      'address_en': data['address_en'],
      'status': 'ACTIVE',
      'created_at': DateTime.now().toIso8601String(),
    };
    
    _borrowers.add(borrower);
    return borrower;
  }

  static Future<Map<String, dynamic>> getBorrowerDetail(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _borrowers.firstWhere(
      (b) => b['id'] == id,
      orElse: () => throw Exception('Borrower not found'),
    );
  }

  // Loan APIs
  static Future<List<dynamic>> getBorrowerLoans(String borrowerId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _loans.where((l) => l['borrower_id'] == borrowerId).toList();
  }

  static Future<Map<String, dynamic>> getLoanDetails(String loanId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final loan = _loans.firstWhere(
      (l) => l['id'] == loanId,
      orElse: () => throw Exception('Loan not found'),
    );
    final schedules = _schedules.where((s) => s['loan_id'] == loanId).toList();
    
    // Sort schedules by installment_no
    schedules.sort((a, b) => (a['installment_no'] as int).compareTo(b['installment_no'] as int));

    return {
      ...loan,
      'schedules': schedules,
    };
  }

  static Future<Map<String, dynamic>> previewLoan(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 250));
    
    final double principal = data['principal_amount'];
    final String model = data['interest_model'];
    final double rate = data['interest_rate'];
    final int tenure = data['tenure_value'];
    
    double totalRepayable = 0.0;
    final List<Map<String, dynamic>> schedulesPreview = [];
    final disbDate = DateTime.now();

    if (model == 'MODEL_A') {
      final totalInterest = principal * (rate / 100) * tenure;
      totalRepayable = principal + totalInterest;
      
      final double monthlyInterest = (principal * (rate / 100)).roundToDouble();
      final double monthlyPrincipal = (principal / tenure).roundToDouble();
      double runningP = 0.0;
      double runningI = 0.0;
      
      for (int i = 1; i <= tenure; i++) {
        final dueDate = DateTime(disbDate.year, disbDate.month + i, disbDate.day);
        double pDue = monthlyPrincipal;
        double iDue = monthlyInterest;
        if (i < tenure) {
          runningP += pDue;
          runningI += iDue;
        } else {
          pDue = principal - runningP;
          iDue = totalInterest - runningI;
        }
        schedulesPreview.add({
          'installment_no': i,
          'due_date': dueDate.toIso8601String().substring(0, 10),
          'principal_due': pDue,
          'interest_due': iDue,
          'fee_due': 0.0,
          'total_due': pDue + iDue,
        });
      }
    } else {
      totalRepayable = principal * 1.2;
      final totalInterest = totalRepayable - principal;
      final double weeklyPrincipal = (principal / tenure).roundToDouble();
      final double weeklyInterest = (totalInterest / tenure).roundToDouble();
      double runningP = 0.0;
      double runningI = 0.0;

      for (int i = 1; i <= tenure; i++) {
        final dueDate = disbDate.add(Duration(days: 7 * i));
        double pDue = weeklyPrincipal;
        double iDue = weeklyInterest;
        if (i < tenure) {
          runningP += pDue;
          runningI += iDue;
        } else {
          pDue = principal - runningP;
          iDue = totalInterest - runningI;
        }
        schedulesPreview.add({
          'installment_no': i,
          'due_date': dueDate.toIso8601String().substring(0, 10),
          'principal_due': pDue,
          'interest_due': iDue,
          'fee_due': 0.0,
          'total_due': pDue + iDue,
        });
      }
    }

    return {
      'principal_amount': principal,
      'interest_model': model,
      'interest_rate': rate,
      'tenure_value': tenure,
      'tenure_unit': model == 'MODEL_A' ? 'MONTHS' : 'WEEKS',
      'total_repayable_amount': totalRepayable,
      'schedules': schedulesPreview,
    };
  }

  static Future<Map<String, dynamic>> createLoan(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final double principal = data['principal_amount'];
    final String model = data['interest_model'];
    final double rate = data['interest_rate'];
    final int tenure = data['tenure_value'];
    
    double totalRepayable = model == 'MODEL_A' 
        ? principal + (principal * (rate / 100) * tenure) 
        : principal * 1.2;

    final loanId = 'loan-id-${DateTime.now().millisecondsSinceEpoch}';
    final newLoan = {
      'id': loanId,
      'borrower_id': data['borrower_id'],
      'principal_amount': principal,
      'interest_model': model,
      'interest_rate': rate,
      'tenure_value': tenure,
      'tenure_unit': model == 'MODEL_A' ? 'MONTHS' : 'WEEKS',
      'total_repayable_amount': totalRepayable,
      'status': 'PENDING',
      'disbursement_date': DateTime.now().toIso8601String().substring(0, 10),
      'created_by': _userName ?? 'Admin',
      'approved_by': null,
      'created_at': DateTime.now().toIso8601String(),
    };

    _loans.add(newLoan);
    _generateMockSchedules(loanId, principal, model, rate, tenure, DateTime.now());
    
    return newLoan;
  }

  static Future<Map<String, dynamic>> approveLoan(String loanId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final loan = _loans.firstWhere(
      (l) => l['id'] == loanId,
      orElse: () => throw Exception('Loan not found'),
    );
    
    if (loan['status'] != 'PENDING') {
      throw Exception('Only pending loans can be approved.');
    }

    loan['status'] = 'ACTIVE';
    loan['approved_by'] = _userName ?? 'Admin';
    loan['disbursement_date'] = DateTime.now().toIso8601String().substring(0, 10);
    
    // Clear old pending schedules and regenerate from today's actual date
    _schedules.removeWhere((s) => s['loan_id'] == loanId);
    _generateMockSchedules(
      loanId, 
      loan['principal_amount'], 
      loan['interest_model'], 
      loan['interest_rate'], 
      loan['tenure_value'], 
      DateTime.now()
    );

    return loan;
  }

  // Payment APIs
  static Future<Map<String, dynamic>> collectPayment(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final String loanId = data['loan_id'];
    final String? scheduleId = data['payment_schedule_id'];
    final double amountPaid = data['amount_paid'];
    
    final loan = _loans.firstWhere((l) => l['id'] == loanId);
    double remaining = amountPaid;
    
    final newPaymentId = 'pay-id-${DateTime.now().millisecondsSinceEpoch}';

    if (scheduleId != null) {
      // Pay specific installment
      final sched = _schedules.firstWhere((s) => s['id'] == scheduleId);
      final double due = sched['total_due'];
      final double paid = sched['amount_paid'];
      final double oustanding = due - paid;
      
      if (remaining >= oustanding) {
        sched['amount_paid'] = due;
        sched['status'] = 'PAID';
      } else {
        sched['amount_paid'] = paid + remaining;
        sched['status'] = 'PARTIALLY_PAID';
      }
    } else {
      // Auto distribution: pay oldest unpaid first
      final loanSchedules = _schedules.where((s) => s['loan_id'] == loanId && s['status'] != 'PAID').toList();
      loanSchedules.sort((a, b) => (a['installment_no'] as int).compareTo(b['installment_no'] as int));
      
      for (final sched in loanSchedules) {
        if (remaining <= 0) break;
        final double due = sched['total_due'];
        final double paid = sched['amount_paid'];
        final double outstanding = due - paid;
        
        if (remaining >= outstanding) {
          sched['amount_paid'] = due;
          sched['status'] = 'PAID';
          remaining -= outstanding;
        } else {
          sched['amount_paid'] = paid + remaining;
          sched['status'] = 'PARTIALLY_PAID';
          remaining = 0.0;
        }
      }
    }

    // Check if entire loan is fully paid
    final allSchedules = _schedules.where((s) => s['loan_id'] == loanId).toList();
    final allPaid = allSchedules.every((s) => s['status'] == 'PAID');
    if (allPaid) {
      loan['status'] = 'FULLY_PAID';
    }

    final paymentRecord = {
      'id': newPaymentId,
      'loan_id': loanId,
      'payment_schedule_id': scheduleId,
      'collected_by': _userName ?? 'Collector',
      'amount_paid': amountPaid,
      'payment_date': DateTime.now().toIso8601String(),
      'payment_method': data['payment_method'],
      'reference_no': data['reference_no'],
      'remarks': data['remarks'],
      'created_at': DateTime.now().toIso8601String(),
    };

    _payments.add(paymentRecord);
    return paymentRecord;
  }

  static Future<Map<String, dynamic>> getWhatsAppReceipt(String paymentId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final payment = _payments.firstWhere((p) => p['id'] == paymentId);
    final loan = _loans.firstWhere((l) => l['id'] == payment['loan_id']);
    final borrower = _borrowers.firstWhere((b) => b['id'] == loan['borrower_id']);
    
    // Calculate current outstanding balance
    final allSchedules = _schedules.where((s) => s['loan_id'] == loan['id']).toList();
    final totalDue = allSchedules.fold(0.0, (sum, item) => sum + item['total_due']);
    final totalPaid = allSchedules.fold(0.0, (sum, item) => sum + item['amount_paid']);
    final outstandingBalance = totalDue - totalPaid;

    final receiptDate = DateTime.parse(payment['payment_date']);
    final formattedDate = '${receiptDate.day.toString().padLeft(2, '0')}-${receiptDate.month.toString().padLeft(2, '0')}-${receiptDate.year}';

    final receiptText = 
        '💸 *LOAN PAYMENT CONFIRMATION*\n\n'
        'Dear ${borrower['first_name_en']} ${borrower['last_name_en']},\n'
        'We have successfully received your payment:\n\n'
        '• *Amount Paid:* ₹${payment['amount_paid'].toStringAsFixed(2)}\n'
        '• *Date:* $formattedDate\n'
        '• *Payment Mode:* ${payment['payment_method']}\n'
        '• *Receipt No:* ${payment['id'].toString().substring(0, 8).toUpperCase()}\n'
        '• *Outstanding Balance:* ₹${outstandingBalance.toStringAsFixed(2)}\n\n'
        'Thank you for your business!';

    var cleanPhone = borrower['phone_number'].toString().replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }

    final encodedText = Uri.encodeComponent(receiptText);
    final shareUrl = 'https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedText';

    return {
      'receipt_text': receiptText,
      'share_url': shareUrl,
    };
  }

  // Admin Rollovers manually triggered
  static Future<int> triggerRollovers() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Simulate current date being 6 days after first unpaid schedule due date
    // To make it functional in mock mode: find any pending schedules past their due date (or simulate it for anything due today/yesterday)
    final now = DateTime.now();
    int rolledCount = 0;

    // Find any schedule where due_date + 5 days <= today, status is PENDING or PARTIALLY_PAID
    for (int i = 0; i < _schedules.length; i++) {
      final sched = _schedules[i];
      if (sched['status'] == 'PENDING' || sched['status'] == 'PARTIALLY_PAID') {
        final dueDate = DateTime.parse(sched['due_date']);
        
        // In mock mode, we will simulate rollover for any schedule that has a due date before today
        if (dueDate.isBefore(now.subtract(const Duration(days: 5)))) {
          final loanId = sched['loan_id'];
          final installmentNo = sched['installment_no'];
          final unpaid = sched['total_due'] - sched['amount_paid'];

          if (unpaid > 0) {
            // Find next installment
            final nextSchedIndex = _schedules.indexWhere(
              (s) => s['loan_id'] == loanId && s['installment_no'] == installmentNo + 1
            );

            if (nextSchedIndex != -1) {
              sched['status'] = 'ROLLED_OVER';
              sched['rolled_over_date'] = now.toIso8601String().substring(0, 10);
              
              _schedules[nextSchedIndex]['fee_due'] = _schedules[nextSchedIndex]['fee_due'] + unpaid;
              _schedules[nextSchedIndex]['total_due'] = 
                  _schedules[nextSchedIndex]['principal_due'] + 
                  _schedules[nextSchedIndex]['interest_due'] + 
                  _schedules[nextSchedIndex]['fee_due'];
              
              rolledCount++;
            } else {
              sched['status'] = 'OVERDUE';
              // Set loan status to defaulted
              final loanIndex = _loans.indexWhere((l) => l['id'] == loanId);
              if (loanIndex != -1) {
                _loans[loanIndex]['status'] = 'DEFAULTED';
              }
            }
          }
        }
      }
    }

    return rolledCount;
  }
}
