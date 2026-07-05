import 'dart:convert';

class InstallationModel {
  final String? id;
  final String customerId;
  
  // Photos
  final String? structurePhotoUrl;
  final List<String>? panelPhotoUrls;
  final String? inverterPhotoUrl;
  final String? meterPhotoUrl;
  final String? finalPhotoUrl;
  
  // Geo
  final double? lat;
  final double? lng;
  
  // Equipment
  final String? inverterBrand;
  final String? inverterSerial;
  final String? panelBrand;
  final int? panelCount;
  final List<String>? panelSerials;
  final String? generationMeterNo;
  
  // Individual Photo Statuses (P = Pending, S = Submitted, A = Approved, R = Rejected)
  final String? structurePhotoStatus;
  final String? panelPhotoStatus;
  final String? inverterPhotoStatus;
  final String? meterPhotoStatus;
  final String? finalPhotoStatus;

  // Admin
  final String? adminVerifiedPhotoUrl;
  final String verificationStatus; // P = Pending, S = Submitted, V = Verified, R = Rejected, A = Approved
  final String? adminRemark;
  
  // Timestamps
  final DateTime? submittedAt;
  final DateTime? verifiedAt;

  InstallationModel({
    this.id,
    required this.customerId,
    this.structurePhotoUrl,
    this.panelPhotoUrls,
    this.inverterPhotoUrl,
    this.meterPhotoUrl,
    this.finalPhotoUrl,
    this.lat,
    this.lng,
    this.inverterBrand,
    this.inverterSerial,
    this.panelBrand,
    this.panelCount,
    this.panelSerials,
    this.generationMeterNo,
    this.structurePhotoStatus = 'P',
    this.panelPhotoStatus = 'P',
    this.inverterPhotoStatus = 'P',
    this.meterPhotoStatus = 'P',
    this.finalPhotoStatus = 'P',
    this.adminVerifiedPhotoUrl,
    this.verificationStatus = 'P',
    this.adminRemark,
    this.submittedAt,
    this.verifiedAt,
  });

  InstallationModel copyWith({
    String? id,
    String? customerId,
    String? structurePhotoUrl,
    List<String>? panelPhotoUrls,
    String? inverterPhotoUrl,
    String? meterPhotoUrl,
    String? finalPhotoUrl,
    double? lat,
    double? lng,
    String? inverterBrand,
    String? inverterSerial,
    String? panelBrand,
    int? panelCount,
    List<String>? panelSerials,
    String? generationMeterNo,
    String? structurePhotoStatus,
    String? panelPhotoStatus,
    String? inverterPhotoStatus,
    String? meterPhotoStatus,
    String? finalPhotoStatus,
    String? adminVerifiedPhotoUrl,
    String? verificationStatus,
    String? adminRemark,
    DateTime? submittedAt,
    DateTime? verifiedAt,
  }) {
    return InstallationModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      structurePhotoUrl: structurePhotoUrl ?? this.structurePhotoUrl,
      panelPhotoUrls: panelPhotoUrls ?? this.panelPhotoUrls,
      inverterPhotoUrl: inverterPhotoUrl ?? this.inverterPhotoUrl,
      meterPhotoUrl: meterPhotoUrl ?? this.meterPhotoUrl,
      finalPhotoUrl: finalPhotoUrl ?? this.finalPhotoUrl,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      inverterBrand: inverterBrand ?? this.inverterBrand,
      inverterSerial: inverterSerial ?? this.inverterSerial,
      panelBrand: panelBrand ?? this.panelBrand,
      panelCount: panelCount ?? this.panelCount,
      panelSerials: panelSerials ?? this.panelSerials,
      generationMeterNo: generationMeterNo ?? this.generationMeterNo,
      structurePhotoStatus: structurePhotoStatus ?? this.structurePhotoStatus,
      panelPhotoStatus: panelPhotoStatus ?? this.panelPhotoStatus,
      inverterPhotoStatus: inverterPhotoStatus ?? this.inverterPhotoStatus,
      meterPhotoStatus: meterPhotoStatus ?? this.meterPhotoStatus,
      finalPhotoStatus: finalPhotoStatus ?? this.finalPhotoStatus,
      adminVerifiedPhotoUrl: adminVerifiedPhotoUrl ?? this.adminVerifiedPhotoUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      adminRemark: adminRemark ?? this.adminRemark,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customer_id': customerId,
      if (structurePhotoUrl != null) 'structure_photo_url': structurePhotoUrl,
      if (panelPhotoUrls != null) 'panel_photo_url': jsonEncode(panelPhotoUrls),
      if (inverterPhotoUrl != null) 'inverter_photo_url': inverterPhotoUrl,
      if (meterPhotoUrl != null) 'meter_photo_url': meterPhotoUrl,
      if (finalPhotoUrl != null) 'final_photo_url': finalPhotoUrl,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (inverterBrand != null) 'inverter_brand': inverterBrand,
      if (inverterSerial != null) 'inverter_serial': inverterSerial,
      if (panelBrand != null) 'panel_brand': panelBrand,
      if (panelCount != null) 'panel_count': panelCount,
      if (panelSerials != null) 'panel_serials': jsonEncode(panelSerials),
      if (generationMeterNo != null) 'generation_meter_no': generationMeterNo,
      'structure_photo_status': structurePhotoStatus,
      'panel_photo_status': panelPhotoStatus,
      'inverter_photo_status': inverterPhotoStatus,
      'meter_photo_status': meterPhotoStatus,
      'final_photo_status': finalPhotoStatus,
      if (adminVerifiedPhotoUrl != null) 'admin_verified_photo_url': adminVerifiedPhotoUrl,
      'verification_status': verificationStatus,
      if (adminRemark != null) 'admin_remark': adminRemark,
      if (submittedAt != null) 'submitted_at': submittedAt?.toIso8601String(),
      if (verifiedAt != null) 'verified_at': verifiedAt?.toIso8601String(),
    };
  }

  factory InstallationModel.fromJson(Map<String, dynamic> json) {
    List<String>? parsedPanelSerials;
    if (json['panel_serials'] != null) {
      if (json['panel_serials'] is String) {
        parsedPanelSerials = List<String>.from(jsonDecode(json['panel_serials']));
      } else if (json['panel_serials'] is List) {
        parsedPanelSerials = List<String>.from(json['panel_serials']);
      }
    }

    List<String>? parsedPanelPhotoUrls;
    if (json['panel_photo_url'] != null) {
      if (json['panel_photo_url'] is String) {
        final str = json['panel_photo_url'] as String;
        if (str.startsWith('[')) {
          try {
            parsedPanelPhotoUrls = List<String>.from(jsonDecode(str));
          } catch (_) {
            parsedPanelPhotoUrls = [str];
          }
        } else {
          parsedPanelPhotoUrls = [str];
        }
      } else if (json['panel_photo_url'] is List) {
        parsedPanelPhotoUrls = List<String>.from(json['panel_photo_url']);
      }
    }

    return InstallationModel(
      id: json['id'] as String?,
      customerId: json['customer_id'] as String,
      structurePhotoUrl: json['structure_photo_url'] as String?,
      panelPhotoUrls: parsedPanelPhotoUrls,
      inverterPhotoUrl: json['inverter_photo_url'] as String?,
      meterPhotoUrl: json['meter_photo_url'] as String?,
      finalPhotoUrl: json['final_photo_url'] ?? json['geo_photo_url'] as String?, // Fallback for old data
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      inverterBrand: json['inverter_brand'] as String?,
      inverterSerial: json['inverter_serial'] as String?,
      panelBrand: json['panel_brand'] as String?,
      panelCount: json['panel_count'] as int?,
      panelSerials: parsedPanelSerials,
      generationMeterNo: json['generation_meter_no'] as String?,
      structurePhotoStatus: json['structure_photo_status'] as String? ?? 'P',
      panelPhotoStatus: json['panel_photo_status'] as String? ?? 'P',
      inverterPhotoStatus: json['inverter_photo_status'] as String? ?? 'P',
      meterPhotoStatus: json['meter_photo_status'] as String? ?? 'P',
      finalPhotoStatus: json['final_photo_status'] as String? ?? 'P',
      adminVerifiedPhotoUrl: json['admin_verified_photo_url'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'P',
      adminRemark: json['admin_remark'] as String?,
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at'] as String) : null,
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at'] as String) : null,
    );
  }
}
