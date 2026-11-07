class ScheduleModel {
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final String room;
  final String symbol; // 'Σ', 'V', 'A', 'H', etc.
  final int backgroundColorValue;
  final int foregroundColorValue;
  final String day;
  final int dayOfWeek; // 1: T2, 2: T3, ... 7: CN
  final int week; // starting week or activity week
  final String termId; // Optional term association
  final String subjectId; // Optional link to SubjectModel
  final bool isActivity; // True if custom one-time activity
  final int repeatInterval; // 0 = does not repeat, 1 = every week, 2 = every 2 weeks, etc.
  final int startWeek; // The reference week it starts repeating from
  final DateTime? testDate; // Optional test date if subject has test
  final String? testTitle;

  ScheduleModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.symbol,
    required this.backgroundColorValue,
    required this.foregroundColorValue,
    this.day = 'T3',
    this.dayOfWeek = 2,
    this.week = 12,
    this.termId = '',
    this.subjectId = '',
    this.isActivity = false,
    this.repeatInterval = 1,
    this.startWeek = 1,
    this.testDate,
    this.testTitle,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'startTime': startTime,
      'endTime': endTime,
      'room': room,
      'symbol': symbol,
      'backgroundColorValue': backgroundColorValue,
      'foregroundColorValue': foregroundColorValue,
      'day': day,
      'dayOfWeek': dayOfWeek,
      'week': week,
      'termId': termId,
      'subjectId': subjectId,
      'isActivity': isActivity,
      'repeatInterval': repeatInterval,
      'startWeek': startWeek,
      'testDate': testDate?.toIso8601String(),
      'testTitle': testTitle,
    };
  }

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    final String dayStr = (json['day'] ?? 'T3').toString();
    int parsedDayOfWeek = (json['dayOfWeek'] as num?)?.toInt() ?? 2;
    if (json['dayOfWeek'] == null) {
      if (dayStr == 'T2' || dayStr == 'Thứ Hai') {
        parsedDayOfWeek = 1;
      } else if (dayStr == 'T3' || dayStr == 'Thứ Ba' || dayStr == 'Hôm nay') {
        parsedDayOfWeek = 2;
      } else if (dayStr == 'T4' || dayStr == 'Thứ Tư' || dayStr == 'Ngày mai') {
        parsedDayOfWeek = 3;
      } else if (dayStr == 'T5' || dayStr == 'Thứ Năm') {
        parsedDayOfWeek = 4;
      } else if (dayStr == 'T6' || dayStr == 'Thứ Sáu') {
        parsedDayOfWeek = 5;
      } else if (dayStr == 'T7' || dayStr == 'Thứ Bảy') {
        parsedDayOfWeek = 6;
      } else if (dayStr == 'CN' || dayStr == 'Chủ Nhật') {
        parsedDayOfWeek = 7;
      }
    }

    final int parsedWeek = (json['week'] as num?)?.toInt() ?? 12;
    DateTime? parsedTestDate;
    final dynamic rawTestDate = json['testDate'];
    if (rawTestDate != null && rawTestDate.toString().isNotEmpty) {
      parsedTestDate = DateTime.tryParse(rawTestDate.toString());
    }

    final bool parsedIsActivity = json['isActivity'] == true;

    return ScheduleModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      startTime: (json['startTime'] ?? '').toString(),
      endTime: (json['endTime'] ?? '').toString(),
      room: (json['room'] ?? '').toString(),
      symbol: (json['symbol'] ?? 'S').toString(),
      backgroundColorValue: (json['backgroundColorValue'] as num?)?.toInt() ?? 0xFFEFF6FF,
      foregroundColorValue: (json['foregroundColorValue'] as num?)?.toInt() ?? 0xFF3B82F6,
      day: dayStr,
      dayOfWeek: parsedDayOfWeek,
      week: parsedWeek,
      termId: (json['termId'] ?? '').toString(),
      subjectId: (json['subjectId'] ?? '').toString(),
      isActivity: parsedIsActivity,
      repeatInterval: (json['repeatInterval'] as num?)?.toInt() ?? (parsedIsActivity ? 0 : 1),
      startWeek: (json['startWeek'] as num?)?.toInt() ?? parsedWeek,
      testDate: parsedTestDate,
      testTitle: json['testTitle']?.toString(),
    );
  }

  ScheduleModel copyWith({
    String? title,
    String? startTime,
    String? endTime,
    String? room,
    String? symbol,
    int? backgroundColorValue,
    int? foregroundColorValue,
    String? day,
    int? dayOfWeek,
    int? week,
    String? termId,
    String? subjectId,
    bool? isActivity,
    int? repeatInterval,
    int? startWeek,
    DateTime? testDate,
    bool clearTestDate = false,
    String? testTitle,
  }) {
    return ScheduleModel(
      id: id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      room: room ?? this.room,
      symbol: symbol ?? this.symbol,
      backgroundColorValue: backgroundColorValue ?? this.backgroundColorValue,
      foregroundColorValue: foregroundColorValue ?? this.foregroundColorValue,
      day: day ?? this.day,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      week: week ?? this.week,
      termId: termId ?? this.termId,
      subjectId: subjectId ?? this.subjectId,
      isActivity: isActivity ?? this.isActivity,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      startWeek: startWeek ?? this.startWeek,
      testDate: clearTestDate ? null : (testDate ?? this.testDate),
      testTitle: clearTestDate ? null : (testTitle ?? this.testTitle),
    );
  }

  String get timeFormatted => '$startTime – $endTime · $room';
  String get roomAndTimeFormatted => '$room · $startTime–$endTime';

  /// Determines if this schedule item occurs in a given target week
  bool occursInWeek(int targetWeek) {
    if (isActivity || repeatInterval <= 0) {
      return week == targetWeek;
    }
    if (repeatInterval == 1) {
      return true;
    }
    final int diff = targetWeek - startWeek;
    return diff >= 0 && (diff % repeatInterval == 0);
  }
}
