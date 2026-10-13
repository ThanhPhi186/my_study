import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:study_flow/main.dart';
import 'package:study_flow/services/local_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.instance.init();
  });

  testWidgets('StudyFlow App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const StudyFlowApp());
    await tester.pumpAndSettle();

    // Verify StudyFlow title exists
    expect(find.text('StudyFlow'), findsWidgets);
  });
}
