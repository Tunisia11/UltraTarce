import 'package:supabase_flutter/supabase_flutter.dart';

class TrialRequest {
  const TrialRequest({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.companyName,
    this.message,
    required this.status,
    required this.createdAt,
    this.internalNotes,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String companyName;
  final String? message;
  final String status;
  final DateTime createdAt;
  final String? internalNotes;

  factory TrialRequest.fromMap(Map<String, dynamic> map) {
    return TrialRequest(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      companyName: map['company_name'] as String,
      message: map['message'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'].toString()),
      internalNotes: map['internal_notes'] as String?,
    );
  }
}

class AdminTrialRequestRepository {
  const AdminTrialRequestRepository(this._client);

  final SupabaseClient _client;

  Future<List<TrialRequest>> getTrialRequests() async {
    final response = await _client
        .from('trial_requests')
        .select()
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => TrialRequest.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateStatus(String id, String status) async {
    await _client
        .from('trial_requests')
        .update({'status': status})
        .eq('id', id);
  }

  Future<void> updateInternalNotes(String id, String notes) async {
    await _client
        .from('trial_requests')
        .update({'internal_notes': notes})
        .eq('id', id);
  }
}
