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
      // Set default user as logged in initially for easy testing
      await _prefs.setString(_currentUserKey, defaultUser.id);
    }

    // 2. Seed default schedules if empty
    final schedulesJson = _prefs.getStringList(_schedulesKey);
    if (schedulesJson == null || schedulesJson.isEmpty) {
      final defaultSchedules = [
        ScheduleModel(
          id: 'sch_1',
          title: 'Toán',
          startTime: '07:00',
          endTime: '07:45',
          room: 'P.201',
          symbol: 'Σ',
          backgroundColorValue: 0xFFEFF6FF,
          foregroundColorValue: 0xFF3B82F6,
          day: 'Hôm nay',
        ),
        ScheduleModel(
          id: 'sch_2',
          title: 'Tiếng Anh',
          startTime: '08:00',
          endTime: '08:45',
          room: 'P.203',
          symbol: 'A',
          backgroundColorValue: 0xFFF5F3FF,
          foregroundColorValue: 0xFF8B5CF6,
          day: 'Hôm nay',
        ),
        ScheduleModel(
          id: 'sch_3',
          title: 'Hóa học',
          startTime: '09:00',
          endTime: '09:45',
          room: 'P.204',
          symbol: '🧪',
          backgroundColorValue: 0xFFECFDF5,
          foregroundColorValue: 0xFF10B981,
          day: 'Hôm nay',
        ),
        ScheduleModel(
          id: 'sch_4',
          title: 'Vật lý',
          startTime: '13:30',
          endTime: '14:15',
          room: 'P.102',
          symbol: '⚛',
          backgroundColorValue: 0xFFFFF7ED,
          foregroundColorValue: 0xFFF97316,
          day: 'Ngày mai',
        ),
        ScheduleModel(
          id: 'sch_5',
          title: 'Tin học',
          startTime: '14:30',
          endTime: '15:15',
          room: 'Lab 3',
          symbol: '💻',
          backgroundColorValue: 0xFFF0FDF4,
          foregroundColorValue: 0xFF16A34A,
          day: 'Ngày mai',
        ),
      ];
      final list = defaultSchedules.map((s) => jsonEncode(s.toJson())).toList();
      await _prefs.setStringList(_schedulesKey, list);
    }

    // 3. Seed subjects
    final subjectsJson = _prefs.getStringList(_subjectsKey);
    if (subjectsJson == null || subjectsJson.isEmpty) {
      final defaultSubjects = [
        SubjectModel(id: 'sub_1', name: 'Toán cao cấp', credits: 4, score: 8.5, teacher: 'TS. Nguyễn Văn Hùng', room: 'P.201', code: 'MATH101'),
        SubjectModel(id: 'sub_2', name: 'Tiếng Anh chuyên ngành', credits: 3, score: 8.8, teacher: 'ThS. Trần Thị Mai', room: 'P.203', code: 'ENG201'),
        SubjectModel(id: 'sub_3', name: 'Hóa học đại cương', credits: 3, score: 8.0, teacher: 'PGS. Lê Văn An', room: 'P.204', code: 'CHEM102'),
        SubjectModel(id: 'sub_4', name: 'Vật lý đại cương', credits: 3, score: 8.2, teacher: 'TS. Phạm Minh Tuấn', room: 'P.102', code: 'PHYS101'),
        SubjectModel(id: 'sub_5', name: 'Lập trình Flutter & Dart', credits: 4, score: 9.2, teacher: 'ThS. Vũ Hoàng', room: 'Lab 3', code: 'CS301'),
        SubjectModel(id: 'sub_6', name: 'Cấu trúc dữ liệu & Giải thuật', credits: 3, score: 8.6, teacher: 'TS. Đặng Thanh', room: 'P.305', code: 'CS202'),
        SubjectModel(id: 'sub_7', name: 'Kỹ năng giao tiếp & Thuyết trình', credits: 2, score: 8.7, teacher: 'ThS. Đỗ Lan Hương', room: 'P.108', code: 'SOFT101'),
        SubjectModel(id: 'sub_8', name: 'Triết học Mác - Lênin', credits: 2, score: 7.9, teacher: 'TS. Hoàng Đức', room: 'Hội trường B', code: 'PHI101'),
      ];
      final list = defaultSubjects.map((s) => jsonEncode(s.toJson())).toList();
      await _prefs.setStringList(_subjectsKey, list);
    }
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
