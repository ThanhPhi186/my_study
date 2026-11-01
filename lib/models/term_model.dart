class TermModel {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  TermModel({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }

  factory TermModel.fromJson(Map<String, dynamic> json) {
    return TermModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Học kỳ',
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime(2026, 7, 27),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime(2027, 1, 17),
    );
  }

  // Monday of the first week containing the term's start date
  DateTime get firstMonday {
    return DateTime(startDate.year, startDate.month, startDate.day)
        .subtract(Duration(days: startDate.weekday - 1));
  }

  // Sunday of the final week containing the term's end date
  DateTime get lastSunday {
    return DateTime(endDate.year, endDate.month, endDate.day)
        .add(Duration(days: 7 - endDate.weekday));
  }

  // Total weeks in this term
  int get totalWeeks {
    final diffDays = lastSunday.difference(firstMonday).inDays + 1;
    return (diffDays / 7).round().clamp(1, 60);
  }

  // Get Monday of week w (1..totalWeeks)
  DateTime getMondayOfWeek(int week) {
    return firstMonday.add(Duration(days: (week - 1) * 7));
  }

  // Get all 7 days for week w (Monday to Sunday)
  List<DateTime> getDaysOfWeek(int week) {
    final monday = getMondayOfWeek(week);
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  TermModel copyWith({
    String? name,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return TermModel(
      id: id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
