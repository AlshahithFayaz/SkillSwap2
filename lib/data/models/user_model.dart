class UserModel {
  final String id;
  final String name;
  final String email;
  final String rollNo;
  final String department;
  final String year; // '1st', '2nd', '3rd', '4th'
  final List<String> teachSkills;
  final List<String> learnSkills;
  final double ratingAvg;
  final int ratingCount;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.rollNo,
    required this.department,
    required this.year,
    required this.teachSkills,
    required this.learnSkills,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? rollNo,
    String? department,
    String? year,
    List<String>? teachSkills,
    List<String>? learnSkills,
    double? ratingAvg,
    int? ratingCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      rollNo: rollNo ?? this.rollNo,
      department: department ?? this.department,
      year: year ?? this.year,
      teachSkills: teachSkills ?? List.from(this.teachSkills),
      learnSkills: learnSkills ?? List.from(this.learnSkills),
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'rollNo': rollNo,
      'department': department,
      'year': year,
      'teachSkills': teachSkills,
      'learnSkills': learnSkills,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return UserModel(
      id: documentId ?? map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      rollNo: map['rollNo'] ?? '',
      department: map['department'] ?? '',
      year: map['year'] ?? '',
      teachSkills: List<String>.from(map['teachSkills'] ?? []),
      learnSkills: List<String>.from(map['learnSkills'] ?? []),
      ratingAvg: (map['ratingAvg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (map['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }
}
