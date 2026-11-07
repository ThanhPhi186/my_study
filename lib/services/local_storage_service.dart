import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/schedule_model.dart';
import '../models/subject_model.dart';
import '../models/term_model.dart';

class LocalStorageService {
  static final LocalStorageService instance = LocalStorageService._internal();
  LocalStorageService._internal();

  late SharedPreferences _prefs;

  static const String _usersKey = 'sf_users_list';
  static const String _currentUserKey = 'sf_current_user_id';
  static const String _schedulesKey = 'sf_schedules_list';
  static const String _subjectsKey = 'sf_subjects_list';
  static const String _seedVersionKey = 'sf_seed_version_v8';
  static const String _schoolYearStartKey = 'sf_school_year_start';
  static const String _schoolYearEndKey = 'sf_school_year_end';
  static const String _termsKey = 'sf_terms_list';
  static const String _currentTermKey = 'sf_current_term_id';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _seedInitialDataIfNeeded();
  }

  Future<void> _seedInitialDataIfNeeded() async {
    // 1. Seed default user if no users exist
    final List<String>? usersJson = _prefs.getStringList(_usersKey);
    if (usersJson == null || usersJson.isEmpty) {
      final UserModel defaultUser = UserModel(
        id: 'user_default_minh',
        name: 'Minh',
        email: 'minh@studyflow.edu.vn',
        password: 'password123',
        semester: 'Học kỳ I · 2026–2027',
        gpa: 8.4,
        totalSubjects: 8,
        weeklyHours: 24,
      );
      await _prefs.setStringList(_usersKey, <String>[jsonEncode(defaultUser.toJson())]);
      await _prefs.setString(_currentUserKey, defaultUser.id);
    }

    // 2. Seed default school year dates if empty (Start of the Year & End of the Year)
    if (!_prefs.containsKey(_schoolYearStartKey)) {
      await _prefs.setString(_schoolYearStartKey, DateTime(2026, 7, 27).toIso8601String());
    }
    if (!_prefs.containsKey(_schoolYearEndKey)) {
      await _prefs.setString(_schoolYearEndKey, DateTime(2027, 5, 30).toIso8601String());
    }

    // 3. Seed default terms if empty
    final List<String>? termsJson = _prefs.getStringList(_termsKey);
    if (termsJson == null || termsJson.isEmpty) {
      final List<TermModel> defaultTerms = <TermModel>[
        TermModel(
          id: 'term_1',
          name: 'Học kỳ I',
          startDate: DateTime(2026, 7, 27),
          endDate: DateTime(2027, 1, 17),
        ),
        TermModel(
          id: 'term_2',
          name: 'Học kỳ II',
          startDate: DateTime(2027, 1, 18),
          endDate: DateTime(2027, 5, 30),
        ),
      ];
      final List<String> list = defaultTerms.map((TermModel t) => jsonEncode(t.toJson())).toList();
      await _prefs.setStringList(_termsKey, list);
      await _prefs.setString(_currentTermKey, 'term_1');
    }

    // 4. Seed default schedules (updated with T3 and all days)
    final bool hasNewSeed = _prefs.getBool(_seedVersionKey) ?? false;
    final List<String>? schedulesJson = _prefs.getStringList(_schedulesKey);

    if (schedulesJson == null || schedulesJson.isEmpty || !hasNewSeed) {
      final List<ScheduleModel> defaultSchedules = <ScheduleModel>[
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
          termId: 'term_1',
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
          termId: 'term_1',
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
          termId: 'term_1',
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
          termId: 'term_1',
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
          termId: 'term_1',
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
          termId: 'term_1',
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
          termId: 'term_1',
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
          termId: 'term_1',
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
          termId: 'term_1',
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
          termId: 'term_1',
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
          termId: 'term_1',
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
          termId: 'term_1',
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
          termId: 'term_1',
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
          termId: 'term_1',
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
          termId: 'term_1',
        ),
      ];

      final List<String> list = defaultSchedules.map((ScheduleModel s) => jsonEncode(s.toJson())).toList();
      await _prefs.setStringList(_schedulesKey, list);
      await _prefs.setBool(_seedVersionKey, true);
    }

    // 5. Seed subjects matching screenshot
    final bool hasNewSubjectSeed = _prefs.getBool('${_seedVersionKey}_subjects') ?? false;
    final List<String>? subjectsJson = _prefs.getStringList(_subjectsKey);
    if (subjectsJson == null || subjectsJson.isEmpty || !hasNewSubjectSeed) {
      final List<SubjectModel> defaultSubjects = <SubjectModel>[
        SubjectModel(
          id: 'sub_1',
          name: 'Toán',
          code: 'TOAN01',
          teacher: 'Cô Lan',
          room: 'P.201',
          credits: 4,
          score: 8.6,
          termId: 'Học kỳ I · 2026–2027',
          colorValue: 0xFF3B82F6,
          symbol: 'Σ',
          weeklyPeriods: 5,
          grades: <GradeItem>[
            GradeItem(id: 'g1', name: 'Thường xuyên 1', weight: 1, score: 8.0),
            GradeItem(id: 'g2', name: 'Thường xuyên 2', weight: 1, score: 9.0),
            GradeItem(id: 'g3', name: 'Giữa kỳ', weight: 2, score: 8.5),
            GradeItem(id: 'g4', name: 'Thường xuyên 3', weight: 1, score: 9.0),
            GradeItem(id: 'g5', name: 'Cuối kỳ', weight: 3, score: 8.5),
          ],
        ),
        SubjectModel(
          id: 'sub_2',
          name: 'Ngữ văn',
          code: 'VAN01',
          teacher: 'Cô Hương',
          room: 'P.202',
          credits: 3,
          score: 8.2,
          termId: 'Học kỳ I · 2026–2027',
          colorValue: 0xFFFB7185,
          symbol: 'V',
          weeklyPeriods: 4,
          grades: <GradeItem>[
            GradeItem(id: 'gv1', name: 'Thường xuyên 1', weight: 1, score: 8.0),
            GradeItem(id: 'gv2', name: 'Giữa kỳ', weight: 2, score: 8.3),
          ],
        ),
        SubjectModel(
          id: 'sub_3',
          name: 'Tiếng Anh',
          code: 'ENG01',
          teacher: 'Cô Mai',
          room: 'P.203',
          credits: 3,
          score: 9.0,
          termId: 'Học kỳ I · 2026–2027',
          colorValue: 0xFF8B5CF6,
          symbol: 'A',
          weeklyPeriods: 4,
          grades: <GradeItem>[
            GradeItem(id: 'ge1', name: 'Thường xuyên 1', weight: 1, score: 9.0),
            GradeItem(id: 'ge2', name: 'Giữa kỳ', weight: 2, score: 9.0),
          ],
        ),
        SubjectModel(
          id: 'sub_4',
          name: 'Hóa học',
          code: 'CHEM01',
          teacher: 'Thầy An',
          room: 'P.204',
          credits: 3,
          score: 8.7,
          termId: 'Học kỳ I · 2026–2027',
          colorValue: 0xFF10B981,
          symbol: 'H',
          weeklyPeriods: 3,
          grades: <GradeItem>[
            GradeItem(id: 'gc1', name: 'Thường xuyên 1', weight: 1, score: 8.5),
            GradeItem(id: 'gc2', name: 'Giữa kỳ', weight: 2, score: 8.8),
          ],
        ),
        SubjectModel(
          id: 'sub_5',
          name: 'Vật lý',
          code: 'PHYS01',
          teacher: 'Thầy Tuấn',
          room: 'P.102',
          credits: 3,
          score: 8.1,
          termId: 'Học kỳ I · 2026–2027',
          colorValue: 0xFFF59E0B,
          symbol: 'L',
          weeklyPeriods: 4,
          grades: <GradeItem>[
            GradeItem(id: 'gp1', name: 'Thường xuyên 1', weight: 1, score: 8.1),
          ],
        ),
        SubjectModel(
          id: 'sub_6',
          name: 'Tin học',
          code: 'TIN01',
          teacher: 'Thầy Hoàng',
          room: 'Lab 3',
          credits: 2,
          score: 9.2,
          termId: 'Học kỳ I · 2026–2027',
          colorValue: 0xFF0EA5E9,
          symbol: 'T',
          weeklyPeriods: 2,
          grades: <GradeItem>[
            GradeItem(id: 'gt1', name: 'Thực hành 1', weight: 1, score: 9.2),
          ],
        ),
      ];
      final List<String> list = defaultSubjects.map((SubjectModel s) => jsonEncode(s.toJson())).toList();
      await _prefs.setStringList(_subjectsKey, list);
      await _prefs.setBool('${_seedVersionKey}_subjects', true);
    }
  }

  // --- Terms Management ---

  List<TermModel> getTerms() {
    final List<String> list = _prefs.getStringList(_termsKey) ?? <String>[];
    final List<TermModel> result = <TermModel>[];
    for (final String item in list) {
      try {
        final dynamic decoded = jsonDecode(item);
        if (decoded is Map<dynamic, dynamic>) {
          result.add(TermModel.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {}
    }
    return result;
  }

  Future<void> _saveTerms(List<TermModel> terms) async {
    final List<String> list = terms.map((TermModel t) => jsonEncode(t.toJson())).toList();
    await _prefs.setStringList(_termsKey, list);
  }

  Future<void> addTerm(TermModel term) async {
    final List<TermModel> terms = getTerms();
    terms.add(term);
    await _saveTerms(terms);
    await setSelectedTermId(term.id);
  }

  /// Add next term transition: fixes the current term end date and starts the next term
  Future<void> addNextTermTransition({
    required String currentTermId,
    required DateTime currentTermEndDate,
    required String nextTermName,
    required DateTime nextTermStartDate,
    required DateTime nextTermEndDate,
  }) async {
    final List<TermModel> terms = getTerms();
    final int idx = terms.indexWhere((TermModel t) => t.id == currentTermId);
    if (idx != -1) {
      terms[idx] = terms[idx].copyWith(endDate: currentTermEndDate);
    }

    final TermModel newTerm = TermModel(
      id: 'term_${DateTime.now().millisecondsSinceEpoch}',
      name: nextTermName,
      startDate: nextTermStartDate,
      endDate: nextTermEndDate,
    );
    terms.add(newTerm);
    await _saveTerms(terms);
    await setSelectedTermId(newTerm.id);
  }

  Future<void> updateTerm(TermModel term) async {
    final List<TermModel> terms = getTerms();
    final int idx = terms.indexWhere((TermModel t) => t.id == term.id);
    if (idx != -1) {
      terms[idx] = term;
      await _saveTerms(terms);
    }
  }

  Future<void> deleteTerm(String termId) async {
    final List<TermModel> terms = getTerms();
    terms.removeWhere((TermModel t) => t.id == termId);
    await _saveTerms(terms);
    if (getSelectedTermId() == termId) {
      if (terms.isNotEmpty) {
        await setSelectedTermId(terms.first.id);
      } else {
        await _prefs.remove(_currentTermKey);
      }
    }
  }

  String getSelectedTermId() {
    final String? cur = _prefs.getString(_currentTermKey);
    if (cur != null) return cur;
    final List<TermModel> terms = getTerms();
    if (terms.isNotEmpty) return terms.first.id;
    return '';
  }

  Future<void> setSelectedTermId(String id) async {
    await _prefs.setString(_currentTermKey, id);

    // Also update current user's semester text if matching
    final List<TermModel> terms = getTerms();
    try {
      final TermModel t = terms.firstWhere((TermModel element) => element.id == id);
      final UserModel? user = getCurrentUser();
      if (user != null) {
        await updateUser(user.copyWith(semester: '${t.name} · 2026–2027'));
      }
    } catch (_) {}
  }

  TermModel getSelectedTerm() {
    final List<TermModel> terms = getTerms();
    if (terms.isEmpty) {
      return TermModel(
        id: 'term_default',
        name: 'Học kỳ I',
        startDate: getSchoolYearStartDate(),
        endDate: getSchoolYearEndDate(),
      );
    }
    final String selId = getSelectedTermId();
    try {
      return terms.firstWhere((TermModel t) => t.id == selId);
    } catch (_) {
      return terms.first;
    }
  }

  // --- School Year Configuration (Start of Year & End of Year) ---

  DateTime getSchoolYearStartDate() {
    final String? str = _prefs.getString(_schoolYearStartKey);
    if (str != null) {
      try {
        return DateTime.parse(str);
      } catch (_) {}
    }
    return DateTime(2026, 7, 27);
  }

  DateTime getSchoolYearEndDate() {
    final String? str = _prefs.getString(_schoolYearEndKey);
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

    final List<TermModel> terms = getTerms();
    if (terms.isNotEmpty) {
      terms.first = terms.first.copyWith(startDate: DateTime(start.year, start.month, start.day));
      terms.last = terms.last.copyWith(endDate: DateTime(end.year, end.month, end.day));
      await _saveTerms(terms);
    }
  }

  // --- Auth & User Management ---

  List<UserModel> _getAllUsers() {
    final List<String> list = _prefs.getStringList(_usersKey) ?? <String>[];
    final List<UserModel> result = <UserModel>[];
    for (final String item in list) {
      try {
        final dynamic decoded = jsonDecode(item);
        if (decoded is Map<dynamic, dynamic>) {
          result.add(UserModel.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {}
    }
    return result;
  }

  Future<void> _saveAllUsers(List<UserModel> users) async {
    final List<String> list = users.map((UserModel u) => jsonEncode(u.toJson())).toList();
    await _prefs.setStringList(_usersKey, list);
  }

  UserModel? getCurrentUser() {
    final String? currentId = _prefs.getString(_currentUserKey);
    if (currentId == null) return null;
    final List<UserModel> users = _getAllUsers();
    try {
      return users.firstWhere((UserModel u) => u.id == currentId);
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
    final List<UserModel> users = _getAllUsers();
    final String cleanEmail = email.trim().toLowerCase();

    if (users.any((UserModel u) => u.email.toLowerCase() == cleanEmail)) {
      throw Exception('Email này đã được đăng ký trong hệ thống.');
    }

    final UserModel newUser = UserModel(
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
    final List<UserModel> users = _getAllUsers();
    final String cleanInput = emailOrPhone.trim().toLowerCase();

    final UserModel user = users.firstWhere(
      (UserModel u) => u.email.toLowerCase() == cleanInput && u.password == password,
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
    final List<UserModel> users = _getAllUsers();
    final int index = users.indexWhere((UserModel u) => u.id == updatedUser.id);
    if (index != -1) {
      users[index] = updatedUser;
      await _saveAllUsers(users);
    }
  }

  // --- Schedule Management ---

  List<ScheduleModel> getSchedules() {
    final List<String> list = _prefs.getStringList(_schedulesKey) ?? <String>[];
    final List<ScheduleModel> result = <ScheduleModel>[];
    for (final String item in list) {
      try {
        final dynamic decoded = jsonDecode(item);
        if (decoded is Map<dynamic, dynamic>) {
          result.add(ScheduleModel.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {}
    }
    return result;
  }

  Future<void> addSchedule(ScheduleModel item) async {
    final List<ScheduleModel> schedules = getSchedules();
    schedules.add(item);
    final List<String> list = schedules.map((ScheduleModel s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_schedulesKey, list);
  }

  Future<void> deleteSchedule(String id) async {
    final List<ScheduleModel> schedules = getSchedules();
    schedules.removeWhere((ScheduleModel s) => s.id == id);
    final List<String> list = schedules.map((ScheduleModel s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_schedulesKey, list);
  }

  // --- Subject Management ---

  List<SubjectModel> getSubjects() {
    final List<String> list = _prefs.getStringList(_subjectsKey) ?? <String>[];
    final List<SubjectModel> result = <SubjectModel>[];
    for (final String item in list) {
      try {
        final dynamic decoded = jsonDecode(item);
        if (decoded is Map<dynamic, dynamic>) {
          result.add(SubjectModel.fromJson(Map<String, dynamic>.from(decoded)));
        }
      } catch (_) {}
    }
    return result;
  }

  Future<void> addSubject(SubjectModel subject) async {
    final List<SubjectModel> subjects = getSubjects();
    subjects.add(subject);
    final List<String> list = subjects.map((SubjectModel s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_subjectsKey, list);

    final UserModel? user = getCurrentUser();
    if (user != null) {
      await updateUser(user.copyWith(totalSubjects: subjects.length));
    }
  }

  Future<void> updateSubject(SubjectModel subject) async {
    final List<SubjectModel> subjects = getSubjects();
    final int idx = subjects.indexWhere((SubjectModel s) => s.id == subject.id);
    if (idx != -1) {
      subjects[idx] = subject;
      final List<String> list = subjects.map((SubjectModel s) => jsonEncode(s.toJson())).toList();
      await _prefs.setStringList(_subjectsKey, list);
    }
  }

  Future<void> deleteSubject(String id) async {
    final List<SubjectModel> subjects = getSubjects();
    subjects.removeWhere((SubjectModel s) => s.id == id);
    final List<String> list = subjects.map((SubjectModel s) => jsonEncode(s.toJson())).toList();
    await _prefs.setStringList(_subjectsKey, list);

    final UserModel? user = getCurrentUser();
    if (user != null) {
      await updateUser(user.copyWith(totalSubjects: subjects.length));
    }
  }
}
