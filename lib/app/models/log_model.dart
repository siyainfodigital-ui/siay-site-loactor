class LogModel {
  final String? id;
  final String customerId;
  final String userName;
  final String userRole;
  final String action;
  final DateTime? createdAt;
  final String syncStatus; // 'synced' or 'pending' for offline support
  final String? offlineId;

  LogModel({
    this.id,
    required this.customerId,
    required this.userName,
    required this.userRole,
    required this.action,
    this.createdAt,
    this.syncStatus = 'synced',
    this.offlineId,
  });

  LogModel copyWith({
    String? id,
    String? customerId,
    String? userName,
    String? userRole,
    String? action,
    DateTime? createdAt,
    String? syncStatus,
    String? offlineId,
  }) {
    return LogModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      action: action ?? this.action,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      offlineId: offlineId ?? this.offlineId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      'user_name': userName,
      'user_role': userRole,
      'action': action,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }
  
  Map<String, dynamic> toLocalJson() {
    final json = toJson();
    json['sync_status'] = syncStatus;
    json['offline_id'] = offlineId;
    return json;
  }

  factory LogModel.fromJson(Map<String, dynamic> json) {
    return LogModel(
      id: json['id'] as String?,
      customerId: json['customer_id'] as String,
      userName: json['user_name'] as String,
      userRole: json['user_role'] as String,
      action: json['action'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      syncStatus: json['sync_status'] as String? ?? 'synced',
      offlineId: json['offline_id'] as String?,
    );
  }
}
