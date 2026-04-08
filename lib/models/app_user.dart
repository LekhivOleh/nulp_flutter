class AppUser {
  const AppUser({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  AppUser copyWith({String? name, String? email, String? password}) {
    return AppUser(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'password': password,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }
}
