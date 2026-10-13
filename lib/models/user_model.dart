class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String semester;
  final double gpa;
  final int totalSubjects;
  final int weeklyHours;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.semester = 'Học kỳ I · 2026–2027',
    this.gpa = 8.4,
    this.totalSubjects = 8,
    this.weeklyHours = 24,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'semester': semester,
      'gpa': gpa,
      'totalSubjects': totalSubjects,
      'weeklyHours': weeklyHours,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      semester: json['semester'] ?? 'Học kỳ I · 2026–2027',
      gpa: (json['gpa'] as num?)?.toDouble() ?? 8.4,
      totalSubjects: (json['totalSubjects'] as num?)?.toInt() ?? 8,
      weeklyHours: (json['weeklyHours'] as num?)?.toInt() ?? 24,
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? password,
    String? semester,
    double? gpa,
    int? totalSubjects,
    int? weeklyHours,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      semester: semester ?? this.semester,
      gpa: gpa ?? this.gpa,
      totalSubjects: totalSubjects ?? this.totalSubjects,
      weeklyHours: weeklyHours ?? this.weeklyHours,
    );
  }
}
