class AdminOverview {
  const AdminOverview({
    required this.totalTenants,
    required this.activeTenants,
    required this.totalUsers,
    required this.totalProducts,
    required this.totalDocuments,
    required this.totalSyncErrors,
    required this.totalSyncConflicts,
    required this.trialTenants,
    required this.overdueTenants,
    required this.suspendedTenants,
    required this.cancelledTenants,
    this.latestActivityTime,
    this.latestSyncErrorTime,
  });

  final int totalTenants;
  final int activeTenants;
  final int totalUsers;
  final int totalProducts;
  final int totalDocuments;
  final int totalSyncErrors;
  final int totalSyncConflicts;
  final int trialTenants;
  final int overdueTenants;
  final int suspendedTenants;
  final int cancelledTenants;
  final DateTime? latestActivityTime;
  final DateTime? latestSyncErrorTime;
}

class AdminTenantOverview {
  const AdminTenantOverview({
    required this.tenantId,
    required this.tenantName,
    required this.status,
    this.ownerEmail,
    required this.userCount,
    required this.productCount,
    required this.documentCount,
    required this.syncErrorCount,
    required this.syncConflictCount,
    this.lastActivityDate,
    required this.createdAt,
  });

  final String tenantId;
  final String tenantName;
  final String status;
  final String? ownerEmail;
  final int userCount;
  final int productCount;
  final int documentCount;
  final int syncErrorCount;
  final int syncConflictCount;
  final DateTime? lastActivityDate;
  final DateTime createdAt;
}

class AdminTenantDetail {
  const AdminTenantDetail({
    required this.tenantInfo,
    required this.companyInfo,
    this.subscriptionInfo,
    required this.users,
    required this.counts,
    required this.recentErrors,
    required this.recentDocuments,
    required this.recentAuditEvents,
  });

  final Map<String, dynamic> tenantInfo;
  final Map<String, dynamic> companyInfo;
  final Map<String, dynamic>? subscriptionInfo;
  final List<Map<String, dynamic>> users;
  final Map<String, int> counts;
  final List<Map<String, dynamic>> recentErrors;
  final List<Map<String, dynamic>> recentDocuments;
  final List<Map<String, dynamic>> recentAuditEvents;
}

class AdminSyncHealth {
  const AdminSyncHealth({
    required this.errorsByTenant,
    required this.latestErrors,
    required this.latestConflicts,
    required this.errorsByCode,
  });

  final Map<String, List<Map<String, dynamic>>> errorsByTenant;
  final List<Map<String, dynamic>> latestErrors;
  final List<Map<String, dynamic>> latestConflicts;
  final Map<String, int> errorsByCode;
}
