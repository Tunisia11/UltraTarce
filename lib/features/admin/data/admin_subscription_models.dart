class AdminTenantSubscription {
  const AdminTenantSubscription({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.plan,
    required this.status,
    required this.billingCycle,
    this.priceTnd,
    this.seatsLimit,
    this.trialStartedAt,
    this.trialEndsAt,
    this.currentPeriodStartedAt,
    this.currentPeriodEndsAt,
    this.suspendedAt,
    this.cancelledAt,
    this.adminNotes,
    required this.updatedAt,
    this.updatedBy,
    this.ownerEmail,
    this.userCount = 0,
    this.documentCount = 0,
    this.lastActivityDate,
  });

  final String id;
  final String tenantId;
  final String tenantName;
  final String plan;
  final String status;
  final String billingCycle;
  final double? priceTnd;
  final int? seatsLimit;
  final DateTime? trialStartedAt;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodStartedAt;
  final DateTime? currentPeriodEndsAt;
  final DateTime? suspendedAt;
  final DateTime? cancelledAt;
  final String? adminNotes;
  final DateTime updatedAt;
  final String? updatedBy;

  // Extra fields for the admin list view
  final String? ownerEmail;
  final int userCount;
  final int documentCount;
  final DateTime? lastActivityDate;
}
