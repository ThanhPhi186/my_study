class SubjectModel {
  final String id;
  final String name;
  final int credits;
  final double score;
  final String teacher;
  final String room;
  final String code;

  SubjectModel({
    required this.id,
    required this.name,
    required this.credits,
    required this.score,
    required this.teacher,
    required this.room,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'credits': credits,
      'score': score,
      'teacher': teacher,
      'room': room,
      'code': code,
    };
  }

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      credits: (json['credits'] as num?)?.toInt() ?? 3,
      score: (json['score'] as num?)?.toDouble() ?? 8.0,
      teacher: json['teacher'] ?? '',
      room: json['room'] ?? '',
      code: json['code'] ?? '',
    );
  }
}
