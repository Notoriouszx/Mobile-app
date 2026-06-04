class AccessGrant {
  final String id;
  final String patientId;
  final String? doctorId;
  final String? nurseId;
  final String? token;
  final String? otp;
  final DateTime expiresAt;
  final String status; // pending, active, revoked, resolved
  final DateTime createdAt;
  final DateTime? usedAt;
  final String? doctorName;

  AccessGrant({
    required this.id,
    required this.patientId,
    this.doctorId,
    this.nurseId,
    this.token,
    this.otp,
    required this.expiresAt,
    required this.status,
    required this.createdAt,
    this.usedAt,
    this.doctorName,
  });

  factory AccessGrant.fromJson(Map<String, dynamic> json) {
    return AccessGrant(
      id: json['id'],
      patientId: json['patientId'],
      doctorId: json['doctorId'],
      nurseId: json['nurseId'],
      token: json['token'],
      otp: json['otp'],
      expiresAt: DateTime.parse(json['expiresAt']),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt']),
      usedAt: json['usedAt'] != null ? DateTime.parse(json['usedAt']) : null,
      doctorName: json['doctor']?['name'],
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isPending => status == 'pending';
  bool get isActive => status == 'active';
}

class Doctor {
  final String id;
  final String name;
  final String email;
  final String? image;

  Doctor({
    required this.id,
    required this.name,
    required this.email,
    this.image,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      image: json['image'],
    );
  }
}
