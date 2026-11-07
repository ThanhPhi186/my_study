import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/schedule_model.dart';
import '../models/subject_model.dart';
import '../models/term_model.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import '../widgets/custom_color_picker_dialog.dart';

class ScheduleTab extends StatefulWidget {
  final VoidCallback onDataChanged;
  const ScheduleTab({super.key, required this.onDataChanged});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  List<ScheduleModel> _allSchedules = <ScheduleModel>[];
  List<TermModel> _terms = <TermModel>[];
  late TermModel _selectedTerm;

  late DateTime _schoolYearStart;
  late DateTime _schoolYearEnd;

  // Selected week (1..totalWeeks, default 12 or clamped)
  int _selectedWeek = 12;

  // Selected day index (0..6: 0=T2, 1=T3, 2=T4, 3=T5, 4=T6, 5=T7, 6=CN)
  int _selectedDayIndex = 1;

  final List<String> _dayNames = <String>['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _schoolYearStart = LocalStorageService.instance.getSchoolYearStartDate();
    _schoolYearEnd = LocalStorageService.instance.getSchoolYearEndDate();
    _allSchedules = LocalStorageService.instance.getSchedules();
    _terms = LocalStorageService.instance.getTerms();
    _selectedTerm = LocalStorageService.instance.getSelectedTerm();

    final int total = _selectedTerm.totalWeeks;
    if (_selectedWeek > total) {
      _selectedWeek = total;
    }
    if (_selectedWeek < 1) {
      _selectedWeek = 1;
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _switchTerm(TermModel term) async {
    await LocalStorageService.instance.setSelectedTermId(term.id);
    setState(() {
      _selectedTerm = term;
      if (_selectedWeek > term.totalWeeks) {
        _selectedWeek = 1;
      }
    });
    widget.onDataChanged();
  }

  void _previousWeek() {
    if (_selectedWeek > 1) {
      setState(() {
        _selectedWeek--;
      });
    }
  }

  void _nextWeek() {
    if (_selectedWeek < _selectedTerm.totalWeeks) {
      setState(() {
        _selectedWeek++;
      });
    }
  }

  int _colorToInt(Color c) {
    final int a = (c.a * 255.0).round().clamp(0, 255).toInt();
    final int r = (c.r * 255.0).round().clamp(0, 255).toInt();
    final int g = (c.g * 255.0).round().clamp(0, 255).toInt();
    final int b = (c.b * 255.0).round().clamp(0, 255).toInt();
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  String _formatDate(DateTime dt) {
    final String d = dt.day.toString().padLeft(2, '0');
    final String m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  // --- School Year Configuration Dialog (Start of Year & End of Year) ---
  void _showSchoolYearDialog() {
    DateTime tempStart = _schoolYearStart;
    DateTime tempEnd = _schoolYearEnd;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          final int diffDays = tempEnd.difference(tempStart).inDays + 1;
          final int totalWeeksPreview = (diffDays / 7).round().clamp(1, 100).toInt();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: <Widget>[
                Icon(Icons.calendar_month_rounded, color: Color(0xFF5B50EC), size: 24),
                SizedBox(width: 10),
                Text(
                  'Cài đặt năm học',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 340,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Thiết lập ngày bắt đầu và ngày kết thúc của toàn bộ năm học (Start of Year & End of Year).',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // Start of the year
                    const Text(
                      'Ngày bắt đầu năm học (Start of Year):',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: tempStart,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                          helpText: 'CHỌN NGÀY BẮT ĐẦU NĂM HỌC',
                        );
                        if (picked != null) {
                          setDialogState(() {
                            tempStart = picked;
                            if (tempEnd.isBefore(tempStart)) {
                              tempEnd = tempStart.add(const Duration(days: 280));
                            }
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.event_available_rounded, color: Color(0xFF5B50EC), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(tempStart),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const Spacer(),
                            const Text(
                              'Thay đổi',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5B50EC)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // End of the year
                    const Text(
                      'Ngày kết thúc năm học (End of Year):',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: tempEnd.isAfter(tempStart) ? tempEnd : tempStart.add(const Duration(days: 1)),
                          firstDate: tempStart,
                          lastDate: DateTime(2035),
                          helpText: 'CHỌN NGÀY KẾT THÚC NĂM HỌC',
                        );
                        if (picked != null) {
                          setDialogState(() {
                            tempEnd = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.event_busy_rounded, color: Color(0xFFF43F5E), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(tempEnd),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const Spacer(),
                            const Text(
                              'Thay đổi',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5B50EC)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Summary info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF4F46E5)),
                              const SizedBox(width: 8),
                              Text(
                                'Tổng thời lượng: $totalWeeksPreview tuần',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF4F46E5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '• Bắt đầu: ${_formatDate(tempStart)}\n• Kết thúc: ${_formatDate(tempEnd)}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF4338CA), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B50EC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () async {
                  await LocalStorageService.instance.setSchoolYearDates(
                    start: tempStart,
                    end: tempEnd,
                  );
                  _loadData();
                  widget.onDataChanged();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã cập nhật năm học: ${_formatDate(tempStart)} – ${_formatDate(tempEnd)}'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
                child: const Text('Lưu năm học', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Add Term Dialog (Fixes the date current term ends and next term starts) ---
  void _showAddTermDialog() {
    final TermModel currentTerm = _selectedTerm;
    final TextEditingController nextTermNameCtrl = TextEditingController(text: 'Học kỳ ${_terms.length + 1}');

    DateTime dateTermEnds = currentTerm.endDate;
    if (dateTermEnds.isAfter(_schoolYearEnd)) {
      dateTermEnds = _schoolYearEnd.subtract(const Duration(days: 120));
    }

    DateTime dateNextTermStarts = dateTermEnds.add(const Duration(days: 1));
    DateTime nextTermEndDate = _schoolYearEnd;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          final int currentTermWeeks = (dateTermEnds.difference(currentTerm.startDate).inDays + 1) ~/ 7;
          final int nextTermWeeks = (nextTermEndDate.difference(dateNextTermStarts).inDays + 1) ~/ 7;
          final int breakDays = dateNextTermStarts.difference(dateTermEnds).inDays - 1;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: <Widget>[
                Icon(Icons.add_chart_rounded, color: Color(0xFF5B50EC), size: 24),
                SizedBox(width: 10),
                Text(
                  'Thêm học kỳ mới (Add Term)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 340,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Nhập ngày kết thúc của kỳ hiện tại và ngày bắt đầu của kỳ tiếp theo.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 18),

                    // Section 1: Current Term End Date
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4F46E5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  currentTerm.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Bắt đầu: ${_formatDate(currentTerm.startDate)}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Ngày học kỳ này kết thúc (Date term ends):',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final DateTime firstD = currentTerm.startDate.add(const Duration(days: 1));
                              final DateTime lastD = DateTime(2035);
                              final DateTime initD = dateTermEnds.isAfter(firstD) ? dateTermEnds : firstD;
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: initD,
                                firstDate: firstD,
                                lastDate: lastD,
                                helpText: 'CHỌN NGÀY KẾT THÚC ${currentTerm.name.toUpperCase()}',
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  dateTermEnds = picked;
                                  if (!dateNextTermStarts.isAfter(dateTermEnds)) {
                                    dateNextTermStarts = dateTermEnds.add(const Duration(days: 1));
                                  }
                                  if (!nextTermEndDate.isAfter(dateNextTermStarts)) {
                                    nextTermEndDate = _schoolYearEnd;
                                  }
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.event_busy_rounded, color: Color(0xFFF43F5E), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(dateTermEnds),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'Chọn ngày',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5B50EC)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Next Term Configuration
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Học kỳ tiếp theo (Next term):',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: nextTermNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'Tên học kỳ tiếp theo',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFC7D2FE)),
                              ),
                            ),
                            onChanged: (String _) => setDialogState(() {}),
                          ),
                          const SizedBox(height: 12),

                          // Date next term starts
                          const Text(
                            'Ngày bắt đầu kỳ tiếp theo (Date next term starts):',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final DateTime firstD = dateTermEnds.add(const Duration(days: 1));
                              final DateTime lastD = DateTime(2035);
                              final DateTime initD = dateNextTermStarts.isAfter(firstD) ? dateNextTermStarts : firstD;
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: initD,
                                firstDate: firstD,
                                lastDate: lastD,
                                helpText: 'CHỌN NGÀY BẮT ĐẦU KỲ TIẾP THEO',
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  dateNextTermStarts = picked;
                                  if (!nextTermEndDate.isAfter(dateNextTermStarts)) {
                                    nextTermEndDate = dateNextTermStarts.add(const Duration(days: 60));
                                  }
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFC7D2FE)),
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.event_available_rounded, color: Color(0xFF5B50EC), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(dateNextTermStarts),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'Chọn ngày',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5B50EC)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Date next term ends
                          const Text(
                            'Ngày kết thúc kỳ tiếp theo (Next term ends):',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: nextTermEndDate.isAfter(dateNextTermStarts)
                                    ? nextTermEndDate
                                    : dateNextTermStarts.add(const Duration(days: 30)),
                                firstDate: dateNextTermStarts.add(const Duration(days: 7)),
                                lastDate: DateTime(2035),
                                helpText: 'CHỌN NGÀY KẾT THÚC KỲ TIẾP THEO',
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  nextTermEndDate = picked;
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFC7D2FE)),
                              ),
                              child: Row(
                                children: <Widget>[
                                  const Icon(Icons.event_busy_rounded, color: Color(0xFF10B981), size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(nextTermEndDate),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                  const Spacer(),
                                  const Text(
                                    'Chọn ngày',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5B50EC)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Summary breakdown
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '• ${currentTerm.name}: ${_formatDate(currentTerm.startDate)} – ${_formatDate(dateTermEnds)} (~$currentTermWeeks tuần)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          if (breakDays > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 3.0),
                              child: Text(
                                '• Nghỉ giữa kỳ: ${_formatDate(dateTermEnds.add(const Duration(days: 1)))} – ${_formatDate(dateNextTermStarts.subtract(const Duration(days: 1)))} ($breakDays ngày)',
                                style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                              ),
                            ),
                          const SizedBox(height: 3),
                          Text(
                            '• ${nextTermNameCtrl.text.trim().isEmpty ? "Học kỳ tiếp" : nextTermNameCtrl.text.trim()}: ${_formatDate(dateNextTermStarts)} – ${_formatDate(nextTermEndDate)} (~$nextTermWeeks tuần)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B50EC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () async {
                  if (!dateTermEnds.isAfter(currentTerm.startDate)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ngày kết thúc phải sau ngày bắt đầu!'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  if (!dateNextTermStarts.isAfter(dateTermEnds)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ngày bắt đầu kỳ tiếp theo phải sau ngày kết thúc kỳ hiện tại!'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  if (!nextTermEndDate.isAfter(dateNextTermStarts)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ngày kết thúc kỳ tiếp theo phải sau ngày bắt đầu!'), backgroundColor: Colors.red),
                    );
                    return;
                  }

                  final String nextName = nextTermNameCtrl.text.trim().isEmpty ? 'Học kỳ ${_terms.length + 1}' : nextTermNameCtrl.text.trim();

                  await LocalStorageService.instance.addNextTermTransition(
                    currentTermId: currentTerm.id,
                    currentTermEndDate: dateTermEnds,
                    nextTermName: nextName,
                    nextTermStartDate: dateNextTermStarts,
                    nextTermEndDate: nextTermEndDate,
                  );

                  _loadData();
                  widget.onDataChanged();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã cập nhật ${currentTerm.name} và tạo mới $nextName!'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                },
                child: const Text('Xác nhận thêm học kỳ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Edit Term Dialog ---
  void _showEditTermDialog(TermModel term) {
    final TextEditingController nameCtrl = TextEditingController(text: term.name);
    DateTime tempStart = term.startDate;
    DateTime tempEnd = term.endDate;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          final TermModel tempTerm = TermModel(
            id: term.id,
            name: nameCtrl.text.trim(),
            startDate: tempStart,
            endDate: tempEnd,
          );
          final int totalWeeksPreview = tempTerm.totalWeeks;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: <Widget>[
                const Icon(Icons.edit_note_rounded, color: Color(0xFF5B50EC), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chỉnh sửa: ${term.name}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 340,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tên học kỳ',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      onChanged: (String _) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // Start date
                    const Text('Ngày bắt đầu học kỳ:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: tempStart,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            tempStart = picked;
                            if (tempEnd.isBefore(tempStart)) {
                              tempEnd = tempStart.add(const Duration(days: 120));
                            }
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.event_available_rounded, color: Color(0xFF5B50EC), size: 20),
                            const SizedBox(width: 10),
                            Text(_formatDate(tempStart), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            const Spacer(),
                            const Text('Đổi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5B50EC))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // End date
                    const Text('Ngày kết thúc học kỳ:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: tempEnd.isAfter(tempStart) ? tempEnd : tempStart.add(const Duration(days: 1)),
                          firstDate: tempStart,
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            tempEnd = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.event_busy_rounded, color: Color(0xFFF43F5E), size: 20),
                            const SizedBox(width: 10),
                            Text(_formatDate(tempEnd), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            const Spacer(),
                            const Text('Đổi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF5B50EC))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Text(
                        'Tổng số: $totalWeeksPreview tuần (${_formatDate(tempStart)} – ${_formatDate(tempEnd)})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              if (_terms.length > 1)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await LocalStorageService.instance.deleteTerm(term.id);
                    _loadData();
                    widget.onDataChanged();
                  },
                  child: const Text('Xóa kỳ này', style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B50EC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final TermModel updated = term.copyWith(
                    name: nameCtrl.text.trim().isEmpty ? term.name : nameCtrl.text.trim(),
                    startDate: tempStart,
                    endDate: tempEnd,
                  );
                  await LocalStorageService.instance.updateTerm(updated);
                  _loadData();
                  widget.onDataChanged();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Cập nhật', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showWeekPickerModal() {
    final int total = _selectedTerm.totalWeeks;

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Chọn tuần trong ${_selectedTerm.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Từ ${_formatDate(_selectedTerm.startDate)} đến ${_formatDate(_selectedTerm.endDate)} (Tổng $total tuần)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: total,
                  itemBuilder: (BuildContext context, int index) {
                    final int weekNum = index + 1;
                    final DateTime monday = _selectedTerm.getMondayOfWeek(weekNum);
                    final bool isCurrent = weekNum == _selectedWeek;

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _selectedWeek = weekNum;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCurrent ? const Color(0xFF5B50EC) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrent ? const Color(0xFF5B50EC) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              'Tuần $weekNum',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isCurrent ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Thg ${monday.month}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isCurrent ? Colors.white70 : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- AddSchedule / Activity Dialog with 2 Options & Repeat Selector ---
  void _showAddScheduleDialog() {
    final List<SubjectModel> availableSubjects = LocalStorageService.instance.getSubjects();

    int modeOption = 0; // 0: Chọn môn học từ danh sách, 1: Hoạt động mới
    String? selectedSubjectId = availableSubjects.isNotEmpty ? availableSubjects.first.id : null;

    SubjectModel? getSelectedSubject() {
      if (selectedSubjectId == null) return null;
      for (final SubjectModel s in availableSubjects) {
        if (s.id == selectedSubjectId) return s;
      }
      return availableSubjects.isNotEmpty ? availableSubjects.first : null;
    }

    final SubjectModel? initialSubj = getSelectedSubject();
    final TextEditingController customTitleCtrl = TextEditingController(text: 'Sinh hoạt lớp');
    final TextEditingController roomCtrl = TextEditingController(text: initialSubj?.room ?? 'P.201');
    final TextEditingController startCtrl = TextEditingController(text: '10:00');
    final TextEditingController endCtrl = TextEditingController(text: '10:45');
    final TextEditingController symbolCtrl = TextEditingController(text: initialSubj?.symbol ?? '📚');

    int repeatEveryWeeks = 1; // 1 = every week, 2 = every 2 weeks, etc.
    Color activityColor = const Color(0xFF3B82F6);

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          final SubjectModel? selectedSubject = getSelectedSubject();
          final DateTime? selectedSubjTestDate = selectedSubject?.testDate;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'Thêm vào lịch học · ${_dayNames[_selectedDayIndex]}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            content: SizedBox(
              width: 340,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Segmented switch: [Chọn môn học] | [Hoạt động mới]
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: InkWell(
                              onTap: () => setDialogState(() => modeOption = 0),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: modeOption == 0 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: modeOption == 0
                                      ? <BoxShadow>[
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Chọn môn học',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: modeOption == 0 ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setDialogState(() => modeOption = 1),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: modeOption == 1 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: modeOption == 1
                                      ? <BoxShadow>[
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  'Hoạt động mới',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: modeOption == 1 ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Option 0: Chọn môn học từ danh sách
                    if (modeOption == 0) ...<Widget>[
                      if (availableSubjects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Chưa có môn học nào trong danh sách. Bạn có thể chuyển sang "Hoạt động mới" hoặc tạo môn học trong mục Môn học.',
                            style: TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        )
                      else ...<Widget>[
                        const Text(
                          'Chọn môn học từ danh sách:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedSubjectId,
                              isExpanded: true,
                              items: availableSubjects.map<DropdownMenuItem<String>>((SubjectModel s) {
                                return DropdownMenuItem<String>(
                                  value: s.id,
                                  child: Row(
                                    children: <Widget>[
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Color(s.colorValue),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Text(
                                            s.symbol,
                                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          s.name,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (s.testDate != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('⚡ Sắp thi', style: TextStyle(fontSize: 10, color: Color(0xFFB45309), fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? val) {
                                if (val != null) {
                                  setDialogState(() {
                                    selectedSubjectId = val;
                                    final SubjectModel? sel = getSelectedSubject();
                                    if (sel != null) {
                                      roomCtrl.text = sel.room;
                                      symbolCtrl.text = sel.symbol;
                                    }
                                  });
                                }
                              },
                            ),
                          ),
                        ),

                        // Test notice preview if chosen subject has test
                        if (selectedSubject != null && selectedSubjTestDate != null) ...<Widget>[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFFD97706)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Môn này có lịch kiểm tra: ${_formatDate(selectedSubjTestDate)} (${selectedSubject.testTitle ?? "Kiểm tra"})',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Repeat Selector Button
                        const Text(
                          'Lặp lại (Repeat):',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: repeatEveryWeeks,
                              isExpanded: true,
                              icon: const Icon(Icons.repeat_rounded, color: Color(0xFF4F46E5)),
                              items: const <DropdownMenuItem<int>>[
                                DropdownMenuItem<int>(value: 1, child: Text('Lặp lại mỗi 1 tuần (Mỗi tuần)')),
                                DropdownMenuItem<int>(value: 2, child: Text('Lặp lại mỗi 2 tuần (Cách tuần)')),
                                DropdownMenuItem<int>(value: 3, child: Text('Lặp lại mỗi 3 tuần')),
                                DropdownMenuItem<int>(value: 4, child: Text('Lặp lại mỗi 4 tuần')),
                              ],
                              onChanged: (int? val) {
                                if (val != null) {
                                  setDialogState(() => repeatEveryWeeks = val);
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          repeatEveryWeeks == 1
                              ? '• Môn học sẽ xuất hiện đều đặn mỗi tuần vào ${_dayNames[_selectedDayIndex]}.'
                              : '• Môn học sẽ xuất hiện mỗi $repeatEveryWeeks tuần một lần (Tuần $_selectedWeek, ${_selectedWeek + repeatEveryWeeks}...).',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ] else ...<Widget>[
                      // Option 1: Hoạt động mới (Does not repeat)
                      const Text(
                        'Tên hoạt động:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: customTitleCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Ví dụ: Sinh hoạt lớp, Họp CLB, Đá bóng...',
                          isDense: true,
                          filled: true,
                          fillColor: Color(0xFFF8FAFC),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Color picker for activity
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text('Màu sắc hoạt động:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          GestureDetector(
                            onTap: () async {
                              final Color? picked = await CustomColorPickerDialog.show(context, initialColor: activityColor);
                              if (picked != null) {
                                setDialogState(() => activityColor = picked);
                              }
                            },
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: activityColor,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Notice: Activities do not repeat!
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Hoạt động chỉ diễn ra trong Tuần $_selectedWeek và không lặp lại.',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    // Time & Room inputs
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: startCtrl,
                            decoration: const InputDecoration(labelText: 'Bắt đầu', hintText: '07:00'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: endCtrl,
                            decoration: const InputDecoration(labelText: 'Kết thúc', hintText: '07:45'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: roomCtrl,
                            decoration: const InputDecoration(labelText: 'Phòng / Địa điểm', hintText: 'P.201'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: symbolCtrl,
                            decoration: const InputDecoration(labelText: 'Ký hiệu / Icon', hintText: 'Σ, A, ⚽'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B50EC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () async {
                  final bool isActivityMode = (modeOption == 1);
                  final String title = isActivityMode
                      ? (customTitleCtrl.text.trim().isEmpty ? 'Hoạt động' : customTitleCtrl.text.trim())
                      : (selectedSubject?.name ?? 'Môn học');

                  final Color color = isActivityMode
                      ? activityColor
                      : Color(selectedSubject?.colorValue ?? 0xFF3B82F6);

                  final ScheduleModel newItem = ScheduleModel(
                    id: 'sch_${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    startTime: startCtrl.text.trim().isEmpty ? '07:00' : startCtrl.text.trim(),
                    endTime: endCtrl.text.trim().isEmpty ? '07:45' : endCtrl.text.trim(),
                    room: roomCtrl.text.trim().isEmpty ? 'P.201' : roomCtrl.text.trim(),
                    symbol: symbolCtrl.text.trim().isEmpty ? (title.isNotEmpty ? title[0] : 'S') : symbolCtrl.text.trim(),
                    backgroundColorValue: _colorToInt(color.withValues(alpha: 0.12)),
                    foregroundColorValue: _colorToInt(color),
                    day: _dayNames[_selectedDayIndex],
                    dayOfWeek: _selectedDayIndex + 1,
                    week: _selectedWeek,
                    termId: _selectedTerm.id,
                    subjectId: isActivityMode ? '' : (selectedSubject?.id ?? ''),
                    isActivity: isActivityMode,
                    repeatInterval: isActivityMode ? 0 : repeatEveryWeeks,
                    startWeek: _selectedWeek,
                    testDate: isActivityMode ? null : selectedSubject?.testDate,
                    testTitle: isActivityMode ? null : selectedSubject?.testTitle,
                  );

                  await LocalStorageService.instance.addSchedule(newItem);
                  _loadData();
                  widget.onDataChanged();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Lưu vào TKB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSubjectDetails(ScheduleModel item) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) {
        final DateTime? itemTestDate = item.testDate;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Color(item.backgroundColorValue),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        item.symbol,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(item.foregroundColorValue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.isActivity ? const Color(0xFFFEF3C7) : const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.isActivity ? 'Hoạt động' : 'Môn học',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: item.isActivity ? const Color(0xFFB45309) : const Color(0xFF4F46E5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item.day} · ${item.timeFormatted}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Repeat interval badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      item.isActivity ? Icons.event_note_rounded : Icons.repeat_rounded,
                      size: 18,
                      color: const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.isActivity
                          ? 'Hoạt động một lần (Tuần ${item.week})'
                          : (item.repeatInterval == 1
                              ? 'Lặp lại mỗi tuần'
                              : 'Lặp lại mỗi ${item.repeatInterval} tuần (từ Tuần ${item.startWeek})'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                  ],
                ),
              ),

              // Test warning if scheduled item has test
              if (itemTestDate != null) ...<Widget>[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lịch kiểm tra: ${_formatDate(itemTestDate)} (${item.testTitle ?? "Kiểm tra"})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade600),
                ),
                title: const Text('Xóa tiết này khỏi TKB', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await LocalStorageService.instance.deleteSchedule(item.id);
                  _loadData();
                  widget.onDataChanged();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserModel? user = LocalStorageService.instance.getCurrentUser();
    final String userName = (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Minh';
    final String userInitial = userName[0].toUpperCase();

    final List<DateTime> daysOfWeek = _selectedTerm.getDaysOfWeek(_selectedWeek);
    final DateTime selectedDay = daysOfWeek[_selectedDayIndex];

    // Filter schedules for the selected day based on repeatInterval / activity
    final int selectedDayOfWeekNum = _selectedDayIndex + 1;
    final String currentDayName = _dayNames[_selectedDayIndex];

    final List<ScheduleModel> daySchedules = _allSchedules.where((ScheduleModel s) {
      final bool matchesDay = s.dayOfWeek == selectedDayOfWeekNum || s.day == currentDayName;
      final bool matchesTerm = s.termId.isEmpty || s.termId == _selectedTerm.id;
      final bool matchesWeek = s.occursInWeek(_selectedWeek);
      return matchesDay && matchesWeek && matchesTerm;
    }).toList();

    // Sort by startTime
    daySchedules.sort((ScheduleModel a, ScheduleModel b) => a.startTime.compareTo(b.startTime));

    // Construct timeline slots
    final Set<String> timeSlots = <String>{'07:00', '08:00', '09:00', '10:00', '13:00'};
    for (final ScheduleModel s in daySchedules) {
      timeSlots.add(s.startTime);
    }
    final List<String> sortedSlots = timeSlots.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 12),

          // Top Header: StudyFlow title + User Avatar "M"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'StudyFlow',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDE9FE),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userInitial,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6D28D9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // School Year Pill Banner (Start of Year & End of Year)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: _showSchoolYearDialog,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.school_rounded, size: 18, color: Color(0xFF4F46E5)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Năm học: ${_formatDate(_schoolYearStart)} – ${_formatDate(_schoolYearEnd)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Đổi năm học',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title Row: "Thời khóa biểu" + "Add term" Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Thời khóa biểu',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                InkWell(
                  onTap: _showAddTermDialog,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFC7D2FE),
                        width: 1.2,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.add_rounded, size: 16, color: Color(0xFF4F46E5)),
                        SizedBox(width: 4),
                        Text(
                          'Add term',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Terms Bar
          SizedBox(
            height: 38,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _terms.length + 1,
              itemBuilder: (BuildContext context, int idx) {
                if (idx == _terms.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: _showAddTermDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.add, size: 15, color: Color(0xFF64748B)),
                            SizedBox(width: 4),
                            Text(
                              'Thêm kỳ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final TermModel term = _terms[idx];
                final bool isSelected = term.id == _selectedTerm.id;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _switchTerm(term),
                    onLongPress: () => _showEditTermDialog(term),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            term.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                          if (isSelected) ...<Widget>[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _showEditTermDialog(term),
                              child: Icon(
                                Icons.edit_rounded,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Week Picker Card: < Tuần 12 · Tháng 10 >
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFF1F5F9),
                  width: 1.2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      size: 26,
                      color: _selectedWeek > 1 ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
                    ),
                    onPressed: _selectedWeek > 1 ? _previousWeek : null,
                  ),
                  GestureDetector(
                    onTap: _showWeekPickerModal,
                    child: Row(
                      children: <Widget>[
                        Text(
                          'Tuần $_selectedWeek · Tháng ${selectedDay.month}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF6366F1)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      size: 26,
                      color: _selectedWeek < _selectedTerm.totalWeeks ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
                    ),
                    onPressed: _selectedWeek < _selectedTerm.totalWeeks ? _nextWeek : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 7 Days Picker Strip (T2, T3, T4, T5, T6, T7, CN)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List<Widget>.generate(7, (int idx) {
                final DateTime dayDate = daysOfWeek[idx];
                final bool isSelected = idx == _selectedDayIndex;
                final String dayLabel = _dayNames[idx];

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDayIndex = idx;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF5B50EC) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF5B50EC) : const Color(0xFFF1F5F9),
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: const Color(0xFF5B50EC).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            dayLabel,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${dayDate.day}',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // Timeline & Subjects List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
              itemCount: sortedSlots.length,
              itemBuilder: (BuildContext context, int index) {
                final String timeSlot = sortedSlots[index];

                // Find schedule items that start at this slot
                final List<ScheduleModel> schedulesAtTime = daySchedules.where((ScheduleModel s) => s.startTime == timeSlot).toList();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 18.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Left Time Label (e.g. 07:00, 08:00, 09:00, 10:00, 13:00)
                      SizedBox(
                        width: 48,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14.0),
                          child: Text(
                            timeSlot,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Right Content: Subject Card or Empty Divider Line
                      Expanded(
                        child: schedulesAtTime.isNotEmpty
                            ? Column(
                                children: schedulesAtTime.map((ScheduleModel item) {
                                  return GestureDetector(
                                    onTap: () => _showSubjectDetails(item),
                                    child: _buildTimelineSubjectCard(item),
                                  );
                                }).toList(),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(top: 22.0),
                                child: Container(
                                  height: 1,
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0, right: 4.0),
        child: SizedBox(
          width: 58,
          height: 58,
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF5B50EC),
            shape: const CircleBorder(),
            elevation: 4,
            onPressed: _showAddScheduleDialog,
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }

  // Card matching screenshot style + bright small note for upcoming test
  Widget _buildTimelineSubjectCard(ScheduleModel item) {
    final Color accentColor = Color(item.foregroundColorValue);
    final Color bgColor = Color(item.backgroundColorValue);

    // Check if item or linked subject has upcoming test date
    DateTime? tempTestDate = item.testDate;
    if (tempTestDate == null && item.subjectId.isNotEmpty) {
      final List<SubjectModel> subjects = LocalStorageService.instance.getSubjects();
      for (final SubjectModel s in subjects) {
        if (s.id == item.subjectId) {
          tempTestDate = s.testDate;
          break;
        }
      }
    }

    final DateTime? finalTestDate = tempTestDate;
    final bool hasTest = finalTestDate != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(minHeight: 74),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: hasTest
            ? Border.all(color: const Color(0xFFF59E0B), width: 1.5)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            children: <Widget>[
              // Left colored vertical accent line
              Container(
                width: 4.5,
                color: accentColor,
              ),
              const SizedBox(width: 14),

              // White rounded icon badge with symbol
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    item.symbol,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Subject Title & Room/Time subtitle + Bright test badge
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Bright small note indicator for upcoming test!
                          if (finalTestDate != null)
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFD97706)),
                                  const SizedBox(width: 2),
                                  Text(
                                    'THI: ${_formatDate(finalTestDate)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.roomAndTimeFormatted,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
