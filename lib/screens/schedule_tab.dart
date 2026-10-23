import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/schedule_model.dart';
import '../services/local_storage_service.dart';

class ScheduleTab extends StatefulWidget {
  final VoidCallback onDataChanged;
  const ScheduleTab({super.key, required this.onDataChanged});

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  late List<ScheduleModel> _allSchedules;

  late DateTime _schoolStart;
  late DateTime _schoolEnd;

  // Selected week (1..totalWeeks, default 12 or clamped)
  int _selectedWeek = 12;

  // Selected day index (0..6: 0=T2, 1=T3, 2=T4, 3=T5, 4=T6, 5=T7, 6=CN)
  // Default 1 (T3 - Thứ Ba, matching screenshot)
  int _selectedDayIndex = 1;

  final List<String> _dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
    _loadDatesAndSchedules();
  }

  void _loadDatesAndSchedules() {
    _schoolStart = LocalStorageService.instance.getSchoolYearStartDate();
    _schoolEnd = LocalStorageService.instance.getSchoolYearEndDate();
    _allSchedules = LocalStorageService.instance.getSchedules();

    final total = _calculateTotalWeeks(_schoolStart, _schoolEnd);
    if (_selectedWeek > total) {
      _selectedWeek = total;
    }
    if (_selectedWeek < 1) {
      _selectedWeek = 1;
    }
    setState(() {});
  }

  // Calculate Monday of the first week (Week 1) from the school year start date
  DateTime _getMondayOfFirstWeek(DateTime start) {
    return DateTime(start.year, start.month, start.day).subtract(Duration(days: start.weekday - 1));
  }

  // Total weeks from start to end date
  int _calculateTotalWeeks(DateTime start, DateTime end) {
    final firstMonday = _getMondayOfFirstWeek(start);
    final lastSunday = DateTime(end.year, end.month, end.day).add(Duration(days: 7 - end.weekday));
    final diffDays = lastSunday.difference(firstMonday).inDays + 1;
    return (diffDays / 7).round().clamp(1, 100);
  }

  int get _totalWeeks => _calculateTotalWeeks(_schoolStart, _schoolEnd);

  // Get Monday date for a given week number (1..totalWeeks)
  DateTime _getMondayOfWeek(int week) {
    final firstMonday = _getMondayOfFirstWeek(_schoolStart);
    return firstMonday.add(Duration(days: (week - 1) * 7));
  }

  List<DateTime> _getDaysOfWeek(int week) {
    final monday = _getMondayOfWeek(week);
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  void _previousWeek() {
    if (_selectedWeek > 1) {
      setState(() {
        _selectedWeek--;
      });
    }
  }

  void _nextWeek() {
    if (_selectedWeek < _totalWeeks) {
      setState(() {
        _selectedWeek++;
      });
    }
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  }

  void _showSchoolYearConfigDialog() {
    DateTime tempStart = _schoolStart;
    DateTime tempEnd = _schoolEnd;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final totalWeeksPreview = _calculateTotalWeeks(tempStart, tempEnd);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.edit_calendar_rounded, color: Color(0xFF5B50EC), size: 24),
                SizedBox(width: 10),
                Text(
                  'Cài đặt năm học',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thiết lập ngày bắt đầu và kết thúc năm học. Tuần 1 bắt đầu từ ngày đầu năm học, và tuần cuối cùng kết thúc vào ngày bế giảng.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Ngày bắt đầu năm học (Bắt đầu Tuần 1)
                  const Text(
                    'Ngày bắt đầu năm học (Tuần 1):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
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
                        children: [
                          const Icon(Icons.event_available_rounded, color: Color(0xFF5B50EC), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            _formatDate(tempStart),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
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

                  // Ngày kết thúc năm học (Tuần cuối)
                  const Text(
                    'Ngày kết thúc năm học (Tuần cuối):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
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
                        children: [
                          const Icon(Icons.event_busy_rounded, color: Color(0xFFF43F5E), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            _formatDate(tempEnd),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
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

                  // Summary info card
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
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF4F46E5)),
                            const SizedBox(width: 8),
                            Text(
                              'Tổng cộng: $totalWeeksPreview tuần',
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
                          '• Tuần 1: ${_formatDate(tempStart)} – ${_formatDate(_getMondayOfFirstWeek(tempStart).add(const Duration(days: 6)))}\n• Tuần $totalWeeksPreview: Kết thúc ngày ${_formatDate(tempEnd)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF4338CA), height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
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
                  _loadDatesAndSchedules();
                  widget.onDataChanged();
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã cập nhật năm học! Tổng số: $totalWeeksPreview tuần.'),
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

  void _showWeekPickerModal() {
    final total = _totalWeeks;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chọn tuần trong năm học',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Từ ${_formatDate(_schoolStart)} đến ${_formatDate(_schoolEnd)} (Tổng $total tuần)',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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
                  itemBuilder: (context, index) {
                    final weekNum = index + 1;
                    final monday = _getMondayOfWeek(weekNum);
                    final isCurrent = weekNum == _selectedWeek;

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
                          children: [
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

  void _showAddScheduleDialog() {
    final titleCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: '10:00');
    final endCtrl = TextEditingController(text: '10:45');
    final roomCtrl = TextEditingController(text: 'P.201');
    final symbolCtrl = TextEditingController(text: 'Σ');
    int selectedColorIndex = 0;

    final colorOptions = [
      {'bg': 0xFFEFF6FF, 'fg': 0xFF3B82F6, 'name': 'Xanh dương'},
      {'bg': 0xFFFFF1F2, 'fg': 0xFFF43F5E, 'name': 'Hồng'},
      {'bg': 0xFFF5F3FF, 'fg': 0xFF8B5CF6, 'name': 'Tím'},
      {'bg': 0xFFECFDF5, 'fg': 0xFF10B981, 'name': 'Xanh lá'},
      {'bg': 0xFFFFF7ED, 'fg': 0xFFF97316, 'name': 'Cam'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Thêm môn học · ${_dayNames[_selectedDayIndex]}',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên môn học',
                    hintText: 'Toán, Ngữ văn, Tiếng Anh...',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Bắt đầu',
                          hintText: '07:00',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Kết thúc',
                          hintText: '07:45',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: roomCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Phòng học',
                          hintText: 'P.201',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: symbolCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ký hiệu/Icon',
                          hintText: 'Σ, V, A, H',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Màu sắc thẻ:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(colorOptions.length, (idx) {
                    final opt = colorOptions[idx];
                    final isSel = selectedColorIndex == idx;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColorIndex = idx),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(opt['bg'] as int),
                          border: Border.all(
                            color: isSel ? Color(opt['fg'] as int) : Colors.transparent,
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Color(opt['fg'] as int),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
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
                if (titleCtrl.text.trim().isEmpty) return;
                final color = colorOptions[selectedColorIndex];
                final newItem = ScheduleModel(
                  id: 'sch_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleCtrl.text.trim(),
                  startTime: startCtrl.text.trim(),
                  endTime: endCtrl.text.trim(),
                  room: roomCtrl.text.trim(),
                  symbol: symbolCtrl.text.trim().isEmpty ? '📚' : symbolCtrl.text.trim(),
                  backgroundColorValue: color['bg'] as int,
                  foregroundColorValue: color['fg'] as int,
                  day: _dayNames[_selectedDayIndex],
                  dayOfWeek: _selectedDayIndex + 1,
                  week: _selectedWeek,
                );
                await LocalStorageService.instance.addSchedule(newItem);
                _loadDatesAndSchedules();
                widget.onDataChanged();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Lưu vào TKB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSubjectDetails(ScheduleModel item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                children: [
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
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
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
              const SizedBox(height: 24),
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
                title: const Text('Xóa tiết học này', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await LocalStorageService.instance.deleteSchedule(item.id);
                  _loadDatesAndSchedules();
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
    final user = LocalStorageService.instance.getCurrentUser();
    final userName = (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Minh';
    final userInitial = userName[0].toUpperCase();

    final daysOfWeek = _getDaysOfWeek(_selectedWeek);
    final selectedDay = daysOfWeek[_selectedDayIndex];

    // Filter schedules for the selected day
    final selectedDayOfWeekNum = _selectedDayIndex + 1;
    final currentDayName = _dayNames[_selectedDayIndex];

    final daySchedules = _allSchedules.where((s) {
      final matchesDay = s.dayOfWeek == selectedDayOfWeekNum || s.day == currentDayName;
      final matchesWeek = s.week == 0 || s.week == _selectedWeek;
      return matchesDay && matchesWeek;
    }).toList();

    // Sort by startTime
    daySchedules.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Construct timeline slots
    final Set<String> timeSlots = {'07:00', '08:00', '09:00', '10:00', '13:00'};
    for (final s in daySchedules) {
      timeSlots.add(s.startTime);
    }
    final sortedSlots = timeSlots.toList()..sort();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // Top Header: StudyFlow title + User Avatar "M"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
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
            const SizedBox(height: 16),

            // Title Row: "Thời khóa biểu" + "Năm học" Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Thời khóa biểu',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  // Button to configure School Year Start & End Date
                  InkWell(
                    onTap: _showSchoolYearConfigDialog,
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
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_calendar_rounded, size: 16, color: Color(0xFF4F46E5)),
                          SizedBox(width: 6),
                          Text(
                            'Năm học',
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
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
                        children: [
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
                        color: _selectedWeek < _totalWeeks ? const Color(0xFF6366F1) : const Color(0xFFCBD5E1),
                      ),
                      onPressed: _selectedWeek < _totalWeeks ? _nextWeek : null,
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
                children: List.generate(7, (idx) {
                  final dayDate = daysOfWeek[idx];
                  final isSelected = idx == _selectedDayIndex;
                  final dayLabel = _dayNames[idx];

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
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF5B50EC).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                itemBuilder: (context, index) {
                  final timeSlot = sortedSlots[index];

                  // Find schedule items that start at this slot
                  final schedulesAtTime = daySchedules.where((s) => s.startTime == timeSlot).toList();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 18.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                  children: schedulesAtTime.map((item) {
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
      ),

      // Floating Action Button matching bottom-right of screenshot
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

  // Card matching screenshot style: Left accent strip + soft tinted background + white icon badge
  Widget _buildTimelineSubjectCard(ScheduleModel item) {
    final accentColor = Color(item.foregroundColorValue);
    final bgColor = Color(item.backgroundColorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 74,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            // Left colored vertical accent line
            Container(
              width: 4.5,
              height: double.infinity,
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
                boxShadow: [
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

            // Subject Title & Room/Time subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
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
          ],
        ),
      ),
    );
  }
}
