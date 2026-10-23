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
  final int dayOfWeek;
  final int week;

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
    required this.dayOfWeek,
    required this.week,
  
    
  });

  Map<String, dynamic> toJson() {
    return {
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
    };
  }

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    int parsedDayOfWeek = json['dayOfWeek'] ?? 2;
    // Map string day to dayOfWeek if not set
    final dayStr = json['day'] ?? 'T3';
    if (json['dayOfWeek'] == null) {
      if (dayStr == 'T2' || dayStr == 'Thứ Hai') parsedDayOfWeek = 1;
      else if (dayStr == 'T3' || dayStr == 'Thứ Ba' || dayStr == 'Hôm nay') parsedDayOfWeek = 2;
      else if (dayStr == 'T4' || dayStr == 'Thứ Tư' || dayStr == 'Ngày mai') parsedDayOfWeek = 3;
      else if (dayStr == 'T5' || dayStr == 'Thứ Năm') parsedDayOfWeek = 4;
      else if (dayStr == 'T6' || dayStr == 'Thứ Sáu') parsedDayOfWeek = 5;
      else if (dayStr == 'T7' || dayStr == 'Thứ Bảy') parsedDayOfWeek = 6;
      else if (dayStr == 'CN' || dayStr == 'Chủ Nhật') parsedDayOfWeek = 7;
    }

    return ScheduleModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      room: json['room'] ?? '',
      symbol: json['symbol'] ?? 'S',
      backgroundColorValue: json['backgroundColorValue'] ?? 0xFFEFF6FF,
      foregroundColorValue: json['foregroundColorValue'] ?? 0xFF3B82F6,
      day: dayStr,
      dayOfWeek: parsedDayOfWeek,
      week: json['week'] ?? 12,
    );
  }

  String get timeFormatted => '$startTime – $endTime · $room';
  String get roomAndTimeFormatted => '$room · $startTime–$endTime';
}
