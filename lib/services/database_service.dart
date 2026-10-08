import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final _supabase = Supabase.instance.client;

  // Members operations
  Future<Map<String, dynamic>> getMember(String userId) async {
    final response = await _supabase
        .from('members')
        .select()
        .eq('user_id', userId)
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getAllMembers() async {
    final response = await _supabase.from('members').select();
    return response;
  }

  Future<void> updateMember(String memberId, Map<String, dynamic> data) async {
    await _supabase.from('members').update(data).eq('member_id', memberId);
  }

  // Loan applications operations
  Future<List<Map<String, dynamic>>> getLoanApplications(String userId) async {
    final member = await getMember(userId);
    final response = await _supabase
        .from('loan_applications')
        .select()
        .eq('member_id', member['id'])
        .order('date_submitted', ascending: false);
    return response;
  }

  Future<Map<String, dynamic>> getLoanApplication(String applicationId) async {
    final response = await _supabase
        .from('loan_applications')
        .select()
        .eq('application_id', applicationId)
        .single();
    return response;
  }

  Future<void> createLoanApplication(Map<String, dynamic> data) async {
    await _supabase.from('loan_applications').insert(data);
  }

  Future<void> submitLoanApplication({
    required String applicationId,
    required String loanType,
    required double amount,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before submitting a loan application.');
    }

    final member = await getMember(user.id);
    await _supabase.from('loan_applications').insert({
      'application_id': applicationId,
      'member_id': member['id'],
      'member_name': '${member['first_name']} ${member['last_name']}',
      'loan_type': loanType.replaceFirst(RegExp(r'\s+Loan$'), ''),
      'amount': amount,
      'status': 'pending',
      'date_submitted': DateTime.now().toIso8601String().split('T').first,
    });
  }

  Future<void> updateLoanApplication(
    String applicationId,
    Map<String, dynamic> data,
  ) async {
    await _supabase
        .from('loan_applications')
        .update(data)
        .eq('application_id', applicationId);
  }

  // Loan payments operations
  Future<List<Map<String, dynamic>>> getLoanPayments(
    String loanApplicationId,
  ) async {
    final response = await _supabase
        .from('loan_payments')
        .select()
        .eq('loan_application_id', loanApplicationId)
        .order('payment_date', ascending: false);
    return response;
  }

  Future<void> createLoanPayment(Map<String, dynamic> data) async {
    await _supabase.from('loan_payments').insert(data);
  }

  // Savings accounts operations
  Future<List<Map<String, dynamic>>> getSavingsAccounts(String userId) async {
    final member = await getMember(userId);
    final response = await _supabase
        .from('savings_accounts')
        .select()
        .eq('member_id', member['id']);
    return response;
  }

  Future<Map<String, dynamic>> getSavingsAccount(String accountNumber) async {
    final response = await _supabase
        .from('savings_accounts')
        .select()
        .eq('account_number', accountNumber)
        .single();
    return response;
  }

  // Notifications operations
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return response;
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId);
  }

  // Database function calls
  Future<Map<String, dynamic>> checkLoanEligibility({
    required String memberId,
    required String loanType,
    required double amount,
  }) async {
    final response = await _supabase.functions.invoke(
      'loan-eligibility',
      body: {'member_id': memberId, 'loan_type': loanType, 'amount': amount},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw StateError(
      'Loan eligibility service returned an unexpected response.',
    );
  }

  Future<List<Map<String, dynamic>>> calculatePaymentSchedule({
    required double loanAmount,
    required double interestRate,
    required int termMonths,
  }) async {
    final response = await _supabase.rpc(
      'calculate_payment_schedule',
      params: {
        'p_loan_amount': loanAmount,
        'p_interest_rate': interestRate,
        'p_term_months': termMonths,
      },
    );
    return response;
  }

  // Edge function calls
  Future<FunctionResponse> processLoanApproval({
    required String applicationId,
    required String approvedBy,
    String? notes,
  }) async {
    final response = await _supabase.functions.invoke(
      'loan-approval',
      body: {
        'application_id': applicationId,
        'approved_by': approvedBy,
        'notes': notes,
      },
    );
    return response;
  }

  Future<FunctionResponse> releaseLoan({required String applicationId}) async {
    final response = await _supabase.functions.invoke(
      'loan-release',
      body: {'application_id': applicationId},
    );
    return response;
  }

  Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'info',
  }) async {
    await _supabase.functions.invoke(
      'notifications',
      body: {
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
      },
    );
  }
}
