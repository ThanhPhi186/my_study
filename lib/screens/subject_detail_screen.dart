import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/subject_model.dart';
import '../services/local_storage_service.dart';

class SubjectDetailScreen extends StatefulWidget {
  final SubjectModel subject;
  final VoidCallback onUpdated;

  const SubjectDetailScreen({
    super.key,
    required this.subject,
    required this.onUpdated,
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen> {
  late SubjectModel _subject;
  int _selectedTab = 0; // 0: Điểm số, 1: Biểu đồ, 2: Thông tin

  @override
  void initState() {
    super.initState();
    _subject = widget.subject;
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  void _showAddGradeDialog() {
    final TextEditingController nameCtrl = TextEditingController(text: 'Thường xuyên ${_subject.grades.length + 1}');
    final TextEditingController scoreCtrl = TextEditingController(text: '8.5');
    int selectedWeight = 1;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Thêm điểm mới', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên bài kiểm tra / cột điểm',
                      hintText: 'Thường xuyên, Giữa kỳ, Cuối kỳ...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: scoreCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Điểm số (0 - 10)',
                      hintText: '8.5',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Hệ số tính điểm:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: <int>[1, 2, 3].map((int w) {
                      final bool isSel = selectedWeight == w;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => setDialogState(() => selectedWeight = w),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFF5B50EC) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Hệ số $w',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSel ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final double scoreVal = double.tryParse(scoreCtrl.text) ?? 8.0;
                final GradeItem newGrade = GradeItem(
                  id: 'g_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim().isEmpty ? 'Điểm kiểm tra' : nameCtrl.text.trim(),
                  weight: selectedWeight,
                  score: scoreVal.clamp(0.0, 10.0).toDouble(),
                );

                final List<GradeItem> updatedGrades = List<GradeItem>.from(_subject.grades)..add(newGrade);
                final SubjectModel updatedSubject = _subject.copyWith(grades: updatedGrades);

                await LocalStorageService.instance.updateSubject(updatedSubject);
                setState(() => _subject = updatedSubject);
                widget.onUpdated();

                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Lưu điểm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGrade(String gradeId) async {
    final List<GradeItem> updatedGrades = _subject.grades.where((GradeItem g) => g.id != gradeId).toList();
    final SubjectModel updatedSubject = _subject.copyWith(grades: updatedGrades);
    await LocalStorageService.instance.updateSubject(updatedSubject);
    setState(() => _subject = updatedSubject);
    widget.onUpdated();
  }

  void _confirmDeleteSubject() {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa môn "${_subject.name}"?'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa môn học này? Mọi dữ liệu điểm số sẽ bị xóa.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalStorageService.instance.deleteSubject(_subject.id);
              widget.onUpdated();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa môn "${_subject.name}"'),
                    backgroundColor: Colors.red.shade600,
                  ),
                );
              }
            },
            child: const Text('Xóa môn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _editTestDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _subject.testDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'CHỌN NGÀY KIỂM TRA',
    );
    if (picked != null) {
      final SubjectModel updated = _subject.copyWith(
        testDate: picked,
        testTitle: _subject.testTitle ?? 'Kiểm tra',
      );
      await LocalStorageService.instance.updateSubject(updated);
      setState(() => _subject = updated);
      widget.onUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color subjColor = Color(_subject.colorValue);
    final double avgScore = _subject.calculatedScore;
    final DateTime? currentTestDate = _subject.testDate;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_subject.name} · ${_subject.termId.split('·').first.trim()}',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            tooltip: 'Xóa môn học',
            onPressed: _confirmDeleteSubject,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Hero Card matching Image 2
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      subjColor,
                      Color.lerp(subjColor, const Color(0xFF7C3AED), 0.4) ?? subjColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: subjColor.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        // Left white box with symbol (e.g. Σ)
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _subject.symbol.isNotEmpty ? _subject.symbol : 'S',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: subjColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Title & Subtitle (e.g. "Toán", "5 tiết / tuần · P.201")
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _subject.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_subject.weeklyPeriods} tiết / tuần · ${_subject.room}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bright small note if there's a test coming up!
                    if (currentTestDate != null) ...<Widget>[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: const Color(0xFFD97706).withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFFD97706)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sắp có bài kiểm tra: ${_formatDate(currentTestDate)} (${_subject.testTitle ?? "Kiểm tra"})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _editTestDate,
                              child: const Icon(Icons.edit_calendar_rounded, size: 16, color: Color(0xFF92400E)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // GPA / Score Card matching Image 2
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'ĐIỂM TRUNG BÌNH',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        Text(
                          avgScore.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: subjColor,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(Icons.arrow_upward_rounded, size: 13, color: Color(0xFF10B981)),
                              SizedBox(width: 2),
                              Text(
                                '+0.4',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Segmented Pills matching Image 2: "Điểm số", "Biểu đồ", "Thông tin"
              Row(
                children: <Widget>[
                  _buildTabPill(index: 0, title: 'Điểm số'),
                  const SizedBox(width: 10),
                  _buildTabPill(index: 1, title: 'Biểu đồ'),
                  const SizedBox(width: 10),
                  _buildTabPill(index: 2, title: 'Thông tin'),
                ],
              ),
              const SizedBox(height: 22),

              // Content based on tab
              if (_selectedTab == 0) _buildGradesListSection(),
              if (_selectedTab == 1) _buildChartsSection(),
              if (_selectedTab == 2) _buildInfoSection(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabPill({required int index, required String title}) {
    final bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradesListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Header: "Danh sách điểm" + "+ Thêm điểm"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text(
              'Danh sách điểm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: _showAddGradeDialog,
              child: const Text(
                '+ Thêm điểm',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6366F1),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (_subject.grades.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Column(
                children: <Widget>[
                  Icon(Icons.assignment_outlined, size: 40, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text('Chưa có cột điểm nào', style: TextStyle(color: Color(0xFF94A3B8))),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _showAddGradeDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Thêm điểm ngay', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: _subject.grades.map((GradeItem grade) {
              return Dismissible(
                key: Key(grade.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (DismissDirection direction) => _deleteGrade(grade.id),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            grade.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hệ số ${grade.weight}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        grade.score.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildChartsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Biểu đồ tiến độ điểm số', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          if (_subject.grades.isEmpty)
            const Center(child: Text('Chưa có đủ điểm để vẽ biểu đồ.', style: TextStyle(color: Color(0xFF94A3B8))))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _subject.grades.map((GradeItem g) {
                final double height = (g.score / 10.0) * 120.0;
                return Column(
                  children: <Widget>[
                    Text(g.score.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: height.clamp(10.0, 120.0).toDouble(),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: <Color>[Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 50,
                      child: Text(
                        g.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final DateTime? currentTestDate = _subject.testDate;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: <Widget>[
          _buildInfoRow('Mã môn học', _subject.code.isNotEmpty ? _subject.code : 'Chưa có'),
          const Divider(height: 24),
          _buildInfoRow('Giáo viên', _subject.teacher.isNotEmpty ? _subject.teacher : 'Chưa cập nhật'),
          const Divider(height: 24),
          _buildInfoRow('Phòng học', _subject.room),
          const Divider(height: 24),
          _buildInfoRow('Số tín chỉ', '${_subject.credits} tín chỉ'),
          const Divider(height: 24),
          _buildInfoRow('Số tiết / tuần', '${_subject.weeklyPeriods} tiết'),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Ngày kiểm tra', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              Row(
                children: <Widget>[
                  Text(
                    currentTestDate != null ? _formatDate(currentTestDate) : 'Chưa có',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: currentTestDate != null ? const Color(0xFFD97706) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _editTestDate,
                    child: const Text('Đổi', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
      ],
    );
  }
}
