class GradeItem {
  final String id;
  final String name; // e.g. "Thường xuyên 1", "Giữa kỳ", "Cuối kỳ"
  final int weight; // Hệ số (1, 2, 3)
  final double score; // e.g. 8.0, 9.0

  GradeItem({
    required this.id,
    required this.name,
    this.weight = 1,
    required this.score,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'weight': weight,
      'score': score,
    };
  }

  factory GradeItem.fromJson(Map<String, dynamic> json) {
    return GradeItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      weight: (json['weight'] as num?)?.toInt() ?? 1,
      score: (json['score'] as num?)?.toDouble() ?? 8.0,
    );
  }
}

class SubjectModel {
  final String id;
  final String name;
  final int credits;
  final double score;
  final String teacher;
  final String room;
  final String code;
  final String termId; // e.g. "Học kỳ I · 2026–2027"
  final int colorValue; // Hex color value
  final String symbol; // 'Σ', 'V', 'A', etc.
  final int weeklyPeriods; // Số tiết / tuần
  final DateTime? testDate; // Ngày kiểm tra (nếu có)
  final String? testTitle; // Tên bài kiểm tra (ví dụ: "Giữa kỳ", "15 phút")
  final List<GradeItem> grades;

  SubjectModel({
    required this.id,
    required this.name,
    this.credits = 3,
    this.score = 8.0,
    this.teacher = '',
    this.room = 'P.201',
    this.code = '',
    this.termId = 'Học kỳ I · 2026–2027',
    this.colorValue = 0xFF3B82F6,
    this.symbol = 'S',
    this.weeklyPeriods = 4,
    this.testDate,
    this.testTitle,
    this.grades = const <GradeItem>[],
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'credits': credits,
      'score': score,
      'teacher': teacher,
      'room': room,
      'code': code,
      'termId': termId,
      'colorValue': colorValue,
      'symbol': symbol,
      'weeklyPeriods': weeklyPeriods,
      'testDate': testDate?.toIso8601String(),
      'testTitle': testTitle,
      'grades': grades.map((GradeItem g) => g.toJson()).toList(),
    };
  }

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    final List<GradeItem> loadedGrades = <GradeItem>[];
    final dynamic rawGrades = json['grades'];
    if (rawGrades is List<dynamic>) {
      for (final dynamic item in rawGrades) {
        if (item is Map<dynamic, dynamic>) {
          loadedGrades.add(GradeItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    DateTime? parsedTestDate;
    final dynamic rawTestDate = json['testDate'];
    if (rawTestDate != null && rawTestDate.toString().isNotEmpty) {
      parsedTestDate = DateTime.tryParse(rawTestDate.toString());
    }

    double initialScore = (json['score'] as num?)?.toDouble() ?? 8.0;
    if (loadedGrades.isNotEmpty) {
      double totalWeightedScore = 0.0;
      int totalWeight = 0;
      for (final GradeItem g in loadedGrades) {
        totalWeightedScore += g.score * g.weight;
        totalWeight += g.weight;
      }
      if (totalWeight > 0) {
        initialScore = double.parse((totalWeightedScore / totalWeight).toStringAsFixed(1));
      }
    }

    final String nameStr = (json['name'] ?? '').toString();
    final String defaultSymbol = nameStr.isNotEmpty ? nameStr[0].toUpperCase() : 'S';
    final dynamic rawSymbol = json['symbol'];

    return SubjectModel(
      id: (json['id'] ?? '').toString(),
      name: nameStr,
      credits: (json['credits'] as num?)?.toInt() ?? 3,
      score: initialScore,
      teacher: (json['teacher'] ?? '').toString(),
      room: (json['room'] ?? 'P.201').toString(),
      code: (json['code'] ?? '').toString(),
      termId: (json['termId'] ?? 'Học kỳ I · 2026–2027').toString(),
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF3B82F6,
      symbol: (rawSymbol != null && rawSymbol.toString().isNotEmpty)
          ? rawSymbol.toString()
          : defaultSymbol,
      weeklyPeriods: (json['weeklyPeriods'] as num?)?.toInt() ?? 4,
      testDate: parsedTestDate,
      testTitle: json['testTitle']?.toString(),
      grades: loadedGrades,
    );
  }

  SubjectModel copyWith({
    String? name,
    int? credits,
    double? score,
    String? teacher,
    String? room,
    String? code,
    String? termId,
    int? colorValue,
    String? symbol,
    int? weeklyPeriods,
    DateTime? testDate,
    bool clearTestDate = false,
    String? testTitle,
    List<GradeItem>? grades,
  }) {
    return SubjectModel(
      id: id,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      score: score ?? this.score,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      code: code ?? this.code,
      termId: termId ?? this.termId,
      colorValue: colorValue ?? this.colorValue,
      symbol: symbol ?? this.symbol,
      weeklyPeriods: weeklyPeriods ?? this.weeklyPeriods,
      testDate: clearTestDate ? null : (testDate ?? this.testDate),
      testTitle: clearTestDate ? null : (testTitle ?? this.testTitle),
      grades: grades ?? this.grades,
    );
  }

  double get calculatedScore {
    if (grades.isEmpty) return score;
    double totalWeight = 0.0;
    double weightedScore = 0.0;
    for (final GradeItem g in grades) {
      weightedScore += g.score * g.weight;
      totalWeight += g.weight;
    }
    if (totalWeight == 0.0) return score;
    return double.parse((weightedScore / totalWeight).toStringAsFixed(1));
  }
}
