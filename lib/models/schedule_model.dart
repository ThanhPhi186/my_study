class ScheduleModel {
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final String room;
  final String symbol; // 'Σ', 'A', 'H2O', or icon type
  final int backgroundColorValue;
  final int foregroundColorValue;
  final String day;

  ScheduleModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.symbol,
    required this.backgroundColorValue,
    required this.foregroundColorValue,
    this.day = 'Hôm nay',
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
    };
  }

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      room: json['room'] ?? '',
      symbol: json['symbol'] ?? 'S',
      backgroundColorValue: json['backgroundColorValue'] ?? 0xFFEFF6FF,
      foregroundColorValue: json['foregroundColorValue'] ?? 0xFF3B82F6,
      day: json['day'] ?? 'Hôm nay',
    );
  }

  String get timeFormatted => '$startTime – $endTime · $room';
}
