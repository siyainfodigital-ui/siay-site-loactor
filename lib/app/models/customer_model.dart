class CustomerModel {
  final String id;
  final String? customerId;
  final String? consumerNo;
  final String name;
  final String mobile;
  final String? village;
  final String? taluka;
  final String? address;
  final double? solarKw;
  double? lat;
  double? lng;
  String? photoUrl;
  String status;
  String? installer;
  final DateTime? createdAt;
  final String syncStatus; // 'synced', 'pending', 'failed'
  final String? localPhotoPath;

  CustomerModel({
    required this.id,
    this.customerId,
    this.consumerNo,
    required this.name,
    required this.mobile,
    this.village,
    this.taluka,
    this.address,
    this.solarKw,
    this.lat,
    this.lng,
    this.photoUrl,
    this.status = 'P',
    this.installer,
    this.createdAt,
    this.syncStatus = 'synced',
    this.localPhotoPath,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? '',
      customerId: json['customer_id'],
      consumerNo: json['consumer_no'],
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      village: json['village'],
      taluka: json['taluka'],
      address: json['address'],
      solarKw: json['solar_kw'] != null
          ? double.tryParse(json['solar_kw'].toString())
          : null,
      lat: json['lat'] != null
          ? double.tryParse(json['lat'].toString())
          : null,
      lng: json['lng'] != null
          ? double.tryParse(json['lng'].toString())
          : null,
      photoUrl: json['photo_url'],
      status: json['status'] ?? 'P',
      installer: json['installer'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      syncStatus: json['sync_status'] ?? 'synced',
      localPhotoPath: json['local_photo_path'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (consumerNo != null) 'consumer_no': consumerNo,
      'name': name,
      'mobile': mobile,
      'village': village,
      'taluka': taluka,
      'address': address,
      'solar_kw': solarKw,
      'lat': lat,
      'lng': lng,
      'photo_url': photoUrl,
      'status': status,
      'installer': installer,
      'sync_status': syncStatus,
      if (localPhotoPath != null) 'local_photo_path': localPhotoPath,
    };
  }

  Map<String, dynamic> toInsertJson() {
    final map = toJson();
    map.remove('id'); // Let Supabase generate UUID
    map.remove('sync_status');
    map.remove('local_photo_path');
    return map;
  }

  CustomerModel copyWith({
    String? name,
    String? mobile,
    String? village,
    String? taluka,
    String? address,
    double? solarKw,
    double? lat,
    double? lng,
    String? photoUrl,
    String? status,
    String? installer,
    String? syncStatus,
    String? localPhotoPath,
  }) {
    return CustomerModel(
      id: id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      village: village ?? this.village,
      taluka: taluka ?? this.taluka,
      address: address ?? this.address,
      solarKw: solarKw ?? this.solarKw,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      installer: installer ?? this.installer,
      createdAt: createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'V':
        return 'Visited';
      case 'D':
        return 'Done';
      default:
        return 'Pending';
    }
  }

  bool get hasLocation => lat != null && lng != null;
  bool get hasPhoto => (photoUrl != null && photoUrl!.isNotEmpty) || (localPhotoPath != null && localPhotoPath!.isNotEmpty);
}
