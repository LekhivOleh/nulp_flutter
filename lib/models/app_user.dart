class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.isAdmin = false,
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final bool isAdmin;

  AppUser copyWith({
    String? name,
    String? email,
    String? password,
    bool? isAdmin,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'isAdmin': isAdmin,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }
}
