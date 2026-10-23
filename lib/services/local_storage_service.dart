import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/schedule_model.dart';
import '../models/subject_model.dart';

class LocalStorageService {
  static final LocalStorageService instance = LocalStorageService._internal();
  LocalStorageService._internal();

  late SharedPreferences _prefs;

  static const String _usersKey = 'sf_users_list';
  static const String _currentUserKey = 'sf_current_user_id';
  static const String _schedulesKey = 'sf_schedules_list';
  static const String _subjectsKey = 'sf_subjects_list';
  static const String _seedVersionKey = 'sf_seed_version_v2';
  static const String _schoolYearStartKey = 'sf_school_year_start';
  static const String _schoolYearEndKey = 'sf_school_year_end';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _seedInitialDataIfNeeded();
  }

  Future<void> _seedInitialDataIfNeeded() async {
    // 1. Seed default user if no users exist
    final usersJson = _prefs.getStringList(_usersKey);
    if (usersJson == null || usersJson.isEmpty) {
      final defaultUser = UserModel(
        id: 'user_default_minh',
        name: 'Minh',
        email: 'minh@studyflow.edu.vn',
        password: 'password123',
        semester: 'Học kỳ I · 2026–2027',
        gpa: 8.4,
        totalSubjects: 8,
        weeklyHours: 24,
      );
      await _prefs.setStringList(_usersKey, [jsonEncode(defaultUser.toJson())]);
      await _prefs.setString(_currentUserKey, defaultUser.id);
    }

    // 2. Seed default school year dates if empty
    if (!_prefs.containsKey(_schoolYearStartKey)) {
      await _prefs.setString(_schoolYearStartKey, DateTime(2026, 7, 27).toIso8601String());
    }
    if (!_prefs.containsKey(_schoolYearEndKey)) {
      await _prefs.setString(_schoolYearEndKey, DateTime(2027, 5, 30).toIso8601String());
    }

    // 3. Seed default schedules (updated with T3 and all days)
    final bool hasNewSeed = _prefs.getBool(_seedVersionKey) ?? false;
    final schedulesJson = _prefs.getStringList(_schedulesKey);

    if (schedulesJson == null || schedulesJson.isEmpty || !hasNewSeed) {
      final defaultSchedules = [
        // T3 (Tuesday 13) - Exactly matching screenshot
        ScheduleModel(
          id: 'sch_t3_1',
          title: 'Toán',
          startTime: '07:00',
          endTime: '07:45',
          room: 'P.201',
          symbol: 'Σ',
          backgroundColorValue: 0xFFEFF6FF,
          foregroundColorValue: 0xFF3B82F6,
          day: 'T3',
          dayOfWeek: 2,
          week: 12,
        ),
        ScheduleModel(
          id: 'sch_t3_2',
          title: 'Ngữ văn',
          startTime: '08:00',
          endTime: '08:45',
          room: 'P.202',
          symbol: 'V',
          backgroundColorValue: 0xFFFFF1F2,
          foregroundColorValue: 0xFFF43F5E,
          day: 'T3',
          dayOfWeek: 2,
          week: 12,
        ),
        ScheduleModel(
          id: 'sch_t3_3',
          title: 'Tiếng Anh',
          startTime: '09:00',
          endTime: '09:45',
          room: 'P.203',
          symbol: 'A',
          backgroundColorValue: 0xFFF5F3FF,
          foregroundColorValue: 0xFF8B5CF6,
          day: 'T3',
          dayOfWeek: 2,
          week: 12,
        ),
        ScheduleModel(
          id: 'sch_t3_4',
          title: 'Hóa học',
          startTime: '13:00',
          endTime: '13:45',
          room: 'P.204',
          symbol: 'H',
          backgroundColorValue: 0xFFECFDF5,
          foregroundColorValue: 0xFF10B981,
          day: 'T3',
          dayOfWeek: 2,
          week: 12,
        ),

        // T2 (Monday 12)
        ScheduleModel(
          id: 'sch_t2_1',
          title: 'Sinh học',
          startTime: '07:00',
          endTime: '07:45',
          room: 'P.201',
          symbol: 'S',
          backgroundColorValue: 0xFFF0F9FF,
          foregroundColorValue: 0xFF0EA5E9,
          day: 'T2',
          dayOfWeek: 1,
          week: 12,
        ),
        ScheduleModel(
          id: 'sch_t2_2',
          title: 'Lịch sử',
          startTime: '08:00',
          endTime: '08:45',
          room: 'P.202',
          symbol: 'L',
          backgroundColorValue: 0xFFFFFBEB,
          foregroundColorValue: 0xFFF59E0B,
          day: 'T2',
          dayOfWeek: 1,
          week: 12,
        ),
        ScheduleModel(
          id: 'sch_t2_3',
          title: 'Địa lý',
          startTime: '09:00',
          endTime: '09:45',
          room: 'P.203',
          symbol: 'Đ',
          backgroundColorValue: 0xFFECFDF5,
          foregroundColorValue: 0xFF10B981,
          day: 'T2',
          dayOfWeek: 1,
          week: 12,
        ),

        // T4 (Wednesday 14)
        ScheduleModel(
          id: 'sch_t4_1',
          title: 'Vật lý',
          startTime: '07:00',
          endTime: '07:45',
          room: 'P.102',
          symbol: '⚛',
          backgroundColorValue: 0xFFFFF7ED,
          foregroundColorValue: 0xFFF97316,
          day: 'T4',
          dayOfWeek: 3,
          week: 12,
        ),
        ScheduleModel(
          id: 'sch_t4_2',
          title: 'Toán',
          startTime: '08:00',
          endTime: '08:45',
          room: 'P.201',
          symbol: 'Σ',
          backgroundColorValue: 0xFFEFF6FF,
          foregroundColorValue: 0xFF3B82F6,
          day: 'T4',
          dayOfWeek: 3,
          week: 12,
        ),
        ScheduleModel(
          id: 'sch_t4_3',
          title: 'Tin học',
          startTime: '13:00',
          endTime: '13:45',
          room: 'Lab 3',
          symbol: '💻',
          backgroundColorValue: 0xFFEEF2FF,
          foregroundColorValue: 0xFF6366F1,
          day: 'T4',
          dayOfWeek: 3,
          week: 12,
        ),

        // T5 (Thursday 15)
        ScheduleModel(
          id: 'sch_t5_1',
          title: 'Tiếng Anh',
          startTime: '07:00',
          endTime: '07:45',
          room: 'P.203',
          symbol: 'A',
          backgroundColorValue: 0xFFF5F3FF,
          foregroundColorValue: 0xFF8B5CF6,
          day: 'T5',
          dayOfWeek: 4,
          week: 12,
        ),
        ScheduleModel(
          id: 'sch_t5_2',
          title: 'Hóa học',
          startTime: '08:00',
          endTime: '08:45',
          room: 'P.204',
          symbol: 'H',
          backgroundColorValue: 0xFFECFDF5,
          foregroundColorValue: 0xFF10B981,
          day: 'T5',
          dayOfWeek: 4,
          week: 12,
        ),

        // T6 (Friday 16)
        ScheduleModel(
          id: 'sch_t6_1',
          title: 'Toán',
          startTime: '07:00',
          endTime: '07:45',
          room: 'P.201',
          symbol: 'Σ',
          backgroundColorValue: 0xFFEFF6FF,
          foregroundColorValue: 0xFF3B82F6,
          day: 'T6',
          dayOfWeek: 5,
          week: 12,
        ),
        ScheduleModel(
          id: 'sch_t6_2',
          title: 'Ngữ văn',
          startTime: '08:00',
          endTime: '08:45',
          room: 'P.202',
          symbol: 'V',
          backgroundColorValue: 0xFFFFF1F2,
          foregroundColorValue: 0xFFF43F5E,
          day: 'T6',
          dayOfWeek: 5,
          week: 12,
        ),

        // T7 (Saturday 17)
        ScheduleModel(
          id: 'sch_t7_1',
          title: 'Hoạt động trải nghiệm',
          startTime: '08:00',
          endTime: '09:30',
          room: 'Hội trường',
          symbol: '🌟',
          backgroundColorValue: 0xFFFEFCE8,
          foregroundColorValue: 0xFFEAB308,
          day: 'T7',
          dayOfWeek: 6,
          week: 12,
        ),
      ];

      final list = defaultSchedules.map((s) => jsonEncode(s.toJson())).toList();
      await _prefs.setStringList(_schedulesKey, list);
      await _prefs.setBool(_seedVersionKey, true);
    }

    // 4. Seed subjects
    final subjectsJson = _prefs.getStringList(_subjectsKey);
    if (subjectsJson == null || subjectsJson.isEmpty) {
      final defaultSubjects = [
        SubjectModel(id: 'sub_1', name: 'Toán cao cấp', credits: 4, score: 8.5, teacher: 'TS. Nguyễn Văn Hùng', room: 'P.201', code: 'MATH101'),
        SubjectModel(id: 'sub_2', name: 'Tiếng Anh chuyên ngành', credits: 3, score: 8.8, teacher: 'ThS. Trần Thị Mai', room: 'P.203', code: 'ENG201'),
        SubjectModel(id: 'sub_3', name: 'Hóa học đại cương', credits: 3, score: 8.0, teacher: 'PGS. Lê Văn An', room: 'P.204', code: 'CHEM102'),
        SubjectModel(id: 'sub_4', name: 'Vật lý đại cương', credits: 3, score: 8.2, teacher: 'TS. Phạm Minh Tuấn', room: 'P.102', code: 'PHYS101'),
        SubjectModel(id: 'sub_5', name: 'Lập trình Flutter & Dart', credits: 4, score: 9.2, teacher: 'ThS. Vũ Hoàng', room: 'Lab 3', code: 'CS301'),
        SubjectModel(id: 'sub_6', name: 'Ngữ văn học', credits: 3, score: 8.4, teacher: 'ThS. Đỗ Lan Hương', room: 'P.202', code: 'LIT101'),
        SubjectModel(id: 'sub_7', name: 'Sinh học ứng dụng', credits: 2, score: 8.3, teacher: 'TS. Hoàng Đức', room: 'P.201', code: 'BIO101'),
        SubjectModel(id: 'sub_8', name: 'Lịch sử văn minh', credits: 2, score: 8.0, teacher: 'TS. Đặng Thanh', room: 'P.202', code: 'HIS101'),
      ];
      final list = defaultSubjects.map((s) => jsonEncode(s.toJson())).toList();
      await _prefs.setStringList(_subjectsKey, list);
    }
  }

  // --- School Year Configuration ---

  DateTime getSchoolYearStartDate() {
    final str = _prefs.getString(_schoolYearStartKey);
    if (str != null) {
      try {
        return DateTime.parse(str);
      } catch (_) {}
    }
    return DateTime(2026, 7, 27);
  }

  DateTime getSchoolYearEndDate() {
    final str = _prefs.getString(_schoolYearEndKey);
    if (str != null) {
      try {
        return DateTime.parse(str);
      } catch (_) {}
    }
    return DateTime(2027, 5, 30);
  }

  Future<void> setSchoolYearDates({
    required DateTime start,
    required DateTime end,
  }) async {
    await _prefs.setString(_schoolYearStartKey, DateTime(start.year, start.month, start.day).toIso8601String());
    await _prefs.setString(_schoolYearEndKey, DateTime(end.year, end.month, end.day).toIso8601String());
  }

  // --- Auth & User Management ---

  List<UserModel> _getAllUsers() {
    final list = _prefs.getStringList(_usersKey) ?? [];
    return list.map((item) => UserModel.fromJson(jsonDecode(item))).toList();
  }

  Future<void> _saveAllUsers(List<UserModel> users) async {
    final list = users.map((u) => jsonEncode(u.toJson())).toList();
    await _prefs.setStringList(_usersKey, list);
  }

  UserModel? getCurrentUser() {
    final currentId = _prefs.getString(_currentUserKey);
    if (currentId == null) return null;
    final users = _getAllUsers();
    try {
      return users.firstWhere((u) => u.id == currentId);
    } catch (_) {
      return null;
    }
  }

  bool isLoggedIn() {
    return _prefs.getString(_currentUserKey) != null;
  }

  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final users = _getAllUsers();
    final cleanEmail = email.trim().toLowerCase();

    // Check if email already exists
    if (users.any((u) => u.email.toLowerCase() == cleanEmail)) {
      throw Exception('Email này đã được đăng ký trong hệ thống.');
    }

    final newUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: cleanEmail,
      password: password,
      semester: 'Học kỳ I · 2026–2027',
      gpa: 8.4,
      totalSubjects: 8,
      weeklyHours: 24,
    );

    users.add(newUser);
    await _saveAllUsers(users);
    await _prefs.setString(_currentUserKey, newUser.id);
    return newUser;
  }

  Future<UserModel> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final users = _getAllUsers();
    final cleanInput = emailOrPhone.trim().toLowerCase();

    final user = users.firstWhere(
      (u) => u.email.toLowerCase() == cleanInput && u.password == password,
      orElse: () {
        throw Exception('Email hoặc mật khẩu không chính xác.');
      },
    );

    await _prefs.setString(_currentUserKey, user.id);
    return user;
  }

  Future<void> logout() async {
    await _prefs.remove(_currentUserKey);
  }

  Future<void> updateUser(UserModel updatedUser) async {
    final users = _getAllUsers();
    final index = users.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      users[index] = updatedUser;
      await _saveAllUsers(users);
    }
  }

  // --- Schedule Management ---

  List<ScheduleModel> getSchedules() {
    final list = _prefs.getStringList(_schedulesKey) ?? [];
    return list.map((item) => ScheduleModel.fromJson(jsonDecode(item))).toList();
  }

  Future<void> addSchedule(ScheduleModel item) async {
    final schedules = getSchedules();
    schedules.add(item);
    final list = schedules.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_schedulesKey, list);
  }

  Future<void> deleteSchedule(String id) async {
    final schedules = getSchedules();
    schedules.removeWhere((s) => s.id == id);
    final list = schedules.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_schedulesKey, list);
  }

  // --- Subject Management ---

  List<SubjectModel> getSubjects() {
    final list = _prefs.getStringList(_subjectsKey) ?? [];
    return list.map((item) => SubjectModel.fromJson(jsonDecode(item))).toList();
  }

  Future<void> addSubject(SubjectModel subject) async {
    final subjects = getSubjects();
    subjects.add(subject);
    final list = subjects.map((s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_subjectsKey, list);

    // Also update current user subject count
    final user = getCurrentUser();
    if (user != null) {
      await updateUser(user.copyWith(totalSubjects: subjects.length));
    }
  }
}
