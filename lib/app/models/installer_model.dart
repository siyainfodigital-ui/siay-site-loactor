class InstallerModel {
  final String id;
  final String mobile;
  final String? name;
  final int assignedCount;
  final int pendingCount;
  final int visitedCount;
  final int doneCount;

  InstallerModel({
    required this.id,
    required this.mobile,
    this.name,
    this.assignedCount = 0,
    this.pendingCount = 0,
    this.visitedCount = 0,
    this.doneCount = 0,
  });

  factory InstallerModel.fromJson(Map<String, dynamic> json) {
    return InstallerModel(
      id: json['id'] ?? '',
      mobile: json['mobile'] ?? '',
      name: json['name'],
      assignedCount: json['assigned_count'] ?? 0,
      pendingCount: json['pending_count'] ?? 0,
      visitedCount: json['visited_count'] ?? 0,
      doneCount: json['done_count'] ?? 0,
    );
  }

  String get displayName => name ?? mobile;
}
