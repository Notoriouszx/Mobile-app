class UserModel {
  final String id;
  final String name;
  final String email;
  final String? image;
  final String role;
  final String? phone;
  final bool isActive;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.image,
    required this.role,
    this.phone,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json;
    return UserModel(
      id: user['id'] ?? '',
      name: user['name'] ?? '',
      email: user['email'] ?? '',
      image: user['image'],
      role: user['role'] ?? 'patient',
      phone: user['phone'],
      isActive: user['isActive'] ?? true,
    );
  }
}
