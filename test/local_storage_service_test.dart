import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_flow/models/schedule_model.dart';
import 'package:study_flow/models/subject_model.dart';
import 'package:study_flow/models/term_model.dart';
import 'package:study_flow/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.instance.init();
  });

  group('LocalStorageService Tests', () {
    test('Default user seeded properly on first launch', () {
      final user = LocalStorageService.instance.getCurrentUser();
      expect(user, isNotNull);
      expect(user!.name, equals('Minh'));
      expect(user.gpa, equals(8.4));
      expect(user.totalSubjects, equals(8));
      expect(user.weeklyHours, equals(24));
    });

    test('User registration and login flow', () async {
      final newUser = await LocalStorageService.instance.registerUser(
        name: 'Nguyen Van B',
        email: 'vanb@example.com',
        password: 'password123',
      );
      expect(newUser.name, equals('Nguyen Van B'));
      expect(LocalStorageService.instance.isLoggedIn(), isTrue);

      // Logout
      await LocalStorageService.instance.logout();
      expect(LocalStorageService.instance.isLoggedIn(), isFalse);

      // Login again
      final loggedInUser = await LocalStorageService.instance.login(
        emailOrPhone: 'vanb@example.com',
        password: 'password123',
      );
      expect(loggedInUser.id, equals(newUser.id));
      expect(LocalStorageService.instance.isLoggedIn(), isTrue);
    });

    test('Schedule management in local storage', () async {
      final initialCount = LocalStorageService.instance.getSchedules().length;
      expect(initialCount, greaterThanOrEqualTo(3));

      final newSchedule = ScheduleModel(
        id: 'sch_test',
        title: 'Lịch sử',
        startTime: '10:00',
        endTime: '10:45',
        room: 'P.105',
        symbol: '📜',
        backgroundColorValue: 0xFFEFF6FF,
        foregroundColorValue: 0xFF3B82F6,
        day: 'Hôm nay',
      );

      await LocalStorageService.instance.addSchedule(newSchedule);
      expect(LocalStorageService.instance.getSchedules().length, equals(initialCount + 1));

      await LocalStorageService.instance.deleteSchedule('sch_test');
      expect(LocalStorageService.instance.getSchedules().length, equals(initialCount));
    });

    test('Subject management in local storage', () async {
      final initialCount = LocalStorageService.instance.getSubjects().length;

      final newSubject = SubjectModel(
        id: 'sub_test',
        name: 'Mạng máy tính',
        credits: 3,
        score: 9.0,
        teacher: 'ThS. Nguyễn Văn C',
        room: 'Lab 2',
        code: 'NET101',
      );

      await LocalStorageService.instance.addSubject(newSubject);
      expect(LocalStorageService.instance.getSubjects().length, equals(initialCount + 1));

      // Update subject
      final updatedSubject = newSubject.copyWith(
        score: 9.5,
        testDate: DateTime(2026, 11, 20),
        testTitle: 'Cuối kỳ',
      );
      await LocalStorageService.instance.updateSubject(updatedSubject);
      final fetched = LocalStorageService.instance.getSubjects().firstWhere((s) => s.id == 'sub_test');
      expect(fetched.score, equals(9.5));
      expect(fetched.testDate, isNotNull);
      expect(fetched.testTitle, equals('Cuối kỳ'));

      // Delete subject
      await LocalStorageService.instance.deleteSubject('sub_test');
      expect(LocalStorageService.instance.getSubjects().length, equals(initialCount));
    });

    test('Subject calculated score with weighted grades', () {
      final subjectWithGrades = SubjectModel(
        id: 'sub_math',
        name: 'Toán cao cấp',
        grades: [
          GradeItem(id: 'g1', name: 'Thường xuyên 1', weight: 1, score: 8.5),
          GradeItem(id: 'g2', name: 'Thường xuyên 2', weight: 1, score: 9.0),
          GradeItem(id: 'g3', name: 'Giữa kỳ', weight: 2, score: 8.0),
          GradeItem(id: 'g4', name: 'Cuối kỳ', weight: 3, score: 9.0),
        ],
      );

      // (8.5*1 + 9.0*1 + 8.0*2 + 9.0*3) / (1 + 1 + 2 + 3) = (8.5 + 9.0 + 16.0 + 27.0) / 7 = 60.5 / 7 = 8.64 -> 8.6
      expect(subjectWithGrades.calculatedScore, equals(8.6));
    });

    test('Schedule repeat interval and occursInWeek logic', () {
      // 1. Repeating subject every week
      final repeatWeekly = ScheduleModel(
        id: 'sch_weekly',
        title: 'Toán',
        startTime: '08:00',
        endTime: '09:30',
        room: 'P.201',
        symbol: 'Σ',
        backgroundColorValue: 0xFFEFF6FF,
        foregroundColorValue: 0xFF3B82F6,
        isActivity: false,
        repeatInterval: 1,
        startWeek: 1,
      );
      expect(repeatWeekly.occursInWeek(1), isTrue);
      expect(repeatWeekly.occursInWeek(5), isTrue);
      expect(repeatWeekly.occursInWeek(12), isTrue);

      // 2. Repeating subject every 2 weeks starting from week 2
      final repeatBiweekly = ScheduleModel(
        id: 'sch_biweekly',
        title: 'Thí nghiệm',
        startTime: '13:00',
        endTime: '15:00',
        room: 'Lab 1',
        symbol: '🔬',
        backgroundColorValue: 0xFFEFF6FF,
        foregroundColorValue: 0xFF3B82F6,
        isActivity: false,
        repeatInterval: 2,
        startWeek: 2,
      );
      expect(repeatBiweekly.occursInWeek(2), isTrue);
      expect(repeatBiweekly.occursInWeek(3), isFalse);
      expect(repeatBiweekly.occursInWeek(4), isTrue);
      expect(repeatBiweekly.occursInWeek(5), isFalse);

      // 3. Custom activity (does not repeat, only on specific week)
      final activity = ScheduleModel(
        id: 'act_1',
        title: 'Họp CLB',
        startTime: '17:00',
        endTime: '18:30',
        room: 'Hội trường',
        symbol: '⚡',
        backgroundColorValue: 0xFFFEF3C7,
        foregroundColorValue: 0xFFD97706,
        isActivity: true,
        repeatInterval: 0,
        week: 12,
      );
      expect(activity.occursInWeek(12), isTrue);
      expect(activity.occursInWeek(11), isFalse);
      expect(activity.occursInWeek(13), isFalse);
    });

    test('Term management and week calculation', () async {
      final terms = LocalStorageService.instance.getTerms();
      expect(terms, isNotEmpty);

      final newTerm = TermModel(
        id: 'term_test',
        name: 'Học kỳ Hè 2027',
        startDate: DateTime(2027, 6, 7), // Monday
        endDate: DateTime(2027, 8, 1), // Sunday (~8 weeks)
      );

      await LocalStorageService.instance.addTerm(newTerm);
      expect(LocalStorageService.instance.getTerms().length, equals(terms.length + 1));
      expect(newTerm.totalWeeks, equals(8));

      // Week 1 days
      final week1Days = newTerm.getDaysOfWeek(1);
      expect(week1Days.length, equals(7));
      expect(week1Days[0].day, equals(7)); // June 7
    });

    test('Start of Year and End of Year and Add Term transition test', () async {
      // Set Start of Year and End of Year
      await LocalStorageService.instance.setSchoolYearDates(
        start: DateTime(2026, 9, 1),
        end: DateTime(2027, 5, 31),
      );

      expect(LocalStorageService.instance.getSchoolYearStartDate(), equals(DateTime(2026, 9, 1)));
      expect(LocalStorageService.instance.getSchoolYearEndDate(), equals(DateTime(2027, 5, 31)));

      final initialTerms = LocalStorageService.instance.getTerms();
      final firstTerm = initialTerms.first;

      // Add Term: fixes the date the current term ends and the next term starts
      await LocalStorageService.instance.addNextTermTransition(
        currentTermId: firstTerm.id,
        currentTermEndDate: DateTime(2027, 1, 15),
        nextTermName: 'Học kỳ II Mới',
        nextTermStartDate: DateTime(2027, 1, 18),
        nextTermEndDate: DateTime(2027, 5, 31),
      );

      final updatedTerms = LocalStorageService.instance.getTerms();
      final updatedFirstTerm = updatedTerms.firstWhere((t) => t.id == firstTerm.id);
      expect(updatedFirstTerm.endDate, equals(DateTime(2027, 1, 15)));

      final nextTerm = updatedTerms.firstWhere((t) => t.name == 'Học kỳ II Mới');
      expect(nextTerm.startDate, equals(DateTime(2027, 1, 18)));
      expect(nextTerm.endDate, equals(DateTime(2027, 5, 31)));
      expect(LocalStorageService.instance.getSelectedTermId(), equals(nextTerm.id));
    });
  });
}
