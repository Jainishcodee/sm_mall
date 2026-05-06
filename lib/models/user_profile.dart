class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String photoUrl;
  final String gender;
  final bool isActive;
  final bool isAdmin;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    this.firstName = '',
    this.lastName = '',
    required this.email,
    required this.phone,
    this.photoUrl = '',
    this.gender = '',
    this.isActive = true,
    this.isAdmin = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Full display name, falls back to legacy 'name' field.
  String get displayName {
    final full = '${firstName.trim()} ${lastName.trim()}'.trim();
    return full.isEmpty ? phone : full;
  }

  factory UserProfile.fromFirestore(String id, Map<String, dynamic> data) {
    // Support legacy 'name' field by splitting on first space.
    final legacy = (data['name'] as String?) ?? '';
    final parts = legacy.split(' ');
    return UserProfile(
      id: id,
      firstName:
          (data['firstName'] as String?) ??
          (parts.isNotEmpty ? parts.first : ''),
      lastName:
          (data['lastName'] as String?) ??
          (parts.length > 1 ? parts.sublist(1).join(' ') : ''),
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      photoUrl: (data['photoUrl'] as String?) ?? '',
      gender: (data['gender'] as String?) ?? '',
      isActive: (data['isActive'] as bool?) ?? true,
      isAdmin: (data['isAdmin'] as bool?) ?? false,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as dynamic)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'name': displayName, // keep legacy field
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'gender': gender,
      'isActive': isActive,
      'isAdmin': isAdmin,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
