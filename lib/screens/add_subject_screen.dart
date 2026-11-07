import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../models/term_model.dart';
import '../services/local_storage_service.dart';
import '../widgets/custom_color_picker_dialog.dart';

class AddSubjectScreen extends StatefulWidget {
  final VoidCallback onSubjectAdded;

  const AddSubjectScreen({
    super.key,
    required this.onSubjectAdded,
  });

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _teacherCtrl = TextEditingController();
  final TextEditingController _testTitleCtrl = TextEditingController(text: 'Kiểm tra');

  String _selectedTerm = 'Học kỳ I · 2026–2027';
  List<String> _termOptions = <String>[];

  // Pre-given palette colors matching Image 1
  final List<Color> _presetColors = const <Color>[
    Color(0xFF3B82F6), // Blue
    Color(0xFF8B5CF6), // Purple
    Color(0xFFFB7185), // Pink
    Color(0xFFFBBF24), // Amber/Yellow
    Color(0xFF10B981), // Green
    Color(0xFF06B6D4), // Teal/Cyan
  ];

  late Color _selectedColor;
  DateTime? _selectedTestDate;

  @override
  void initState() {
    super.initState();
    _selectedColor = _presetColors[0];
    _loadTerms();
  }

  void _loadTerms() {
    final List<TermModel> terms = LocalStorageService.instance.getTerms();
    if (terms.isNotEmpty) {
      _termOptions = terms.map((TermModel t) => '${t.name} · 2026–2027').toSet().toList();
      _selectedTerm = _termOptions.first;
    } else {
      _termOptions = <String>['Học kỳ I · 2026–2027', 'Học kỳ II · 2026–2027'];
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _teacherCtrl.dispose();
    _testTitleCtrl.dispose();
    super.dispose();
  }

  int _colorToInt(Color c) {
    final int a = (c.a * 255.0).round().clamp(0, 255).toInt();
    final int r = (c.r * 255.0).round().clamp(0, 255).toInt();
    final int g = (c.g * 255.0).round().clamp(0, 255).toInt();
    final int b = (c.b * 255.0).round().clamp(0, 255).toInt();
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Future<void> _pickTestDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTestDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'CHỌN NGÀY KIỂM TRA',
    );
    if (picked != null) {
      setState(() {
        _selectedTestDate = picked;
      });
    }
  }

  Future<void> _openColorPicker() async {
    final Color? picked = await CustomColorPickerDialog.show(
      context,
      initialColor: _selectedColor,
    );
    if (picked != null) {
      setState(() {
        _selectedColor = picked;
      });
    }
  }

  Future<void> _saveSubject() async {
    final String name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên môn học!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final SubjectModel newSubject = SubjectModel(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      code: _codeCtrl.text.trim(),
      teacher: _teacherCtrl.text.trim(),
      room: 'P.201',
      termId: _selectedTerm,
      colorValue: _colorToInt(_selectedColor),
      symbol: name.isNotEmpty ? name[0].toUpperCase() : 'S',
      weeklyPeriods: 4,
      testDate: _selectedTestDate,
      testTitle: _selectedTestDate != null ? _testTitleCtrl.text.trim() : null,
      score: 8.0,
      grades: <GradeItem>[],
    );

    await LocalStorageService.instance.addSubject(newSubject);
    widget.onSubjectAdded();

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm môn học "$name"!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? currentTestDate = _selectedTestDate;

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
        title: const Text(
          'Thêm môn học',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 8),

              // Title & Subtitle matching Image 1
              const Text(
                'Thông tin môn học',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Nhập thông tin để tạo một môn học mới.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),

              // Field 1: Tên môn học *
              _buildFieldLabel('Tên môn học *'),
              const SizedBox(height: 8),
              _buildTextInput(
                controller: _nameCtrl,
                hintText: 'Ví dụ: Toán',
              ),
              const SizedBox(height: 18),

              // Field 2: Mã môn (tùy chọn)
              _buildFieldLabel('Mã môn (tùy chọn)'),
              const SizedBox(height: 8),
              _buildTextInput(
                controller: _codeCtrl,
                hintText: 'Ví dụ: TOAN01',
              ),
              const SizedBox(height: 18),

              // Field 3: Giáo viên (tùy chọn)
              _buildFieldLabel('Giáo viên (tùy chọn)'),
              const SizedBox(height: 8),
              _buildTextInput(
                controller: _teacherCtrl,
                hintText: 'Ví dụ: Cô Lan',
              ),
              const SizedBox(height: 18),

              // Field 4: Học kỳ *
              _buildFieldLabel('Học kỳ *'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _termOptions.contains(_selectedTerm) ? _selectedTerm : _termOptions.first,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                    items: _termOptions.map<DropdownMenuItem<String>>((String term) {
                      return DropdownMenuItem<String>(
                        value: term,
                        child: Text(term),
                      );
                    }).toList(),
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() => _selectedTerm = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Field 5: Ngày kiểm tra (tùy chọn) with bright indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _buildFieldLabel('Ngày kiểm tra (tùy chọn)'),
                  if (currentTestDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedTestDate = null),
                      child: const Text(
                        'Xóa ngày',
                        style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickTestDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: currentTestDate != null ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                      width: currentTestDate != null ? 1.5 : 1.2,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.event_note_rounded,
                        color: currentTestDate != null ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: currentTestDate != null
                            ? Row(
                                children: <Widget>[
                                  Text(
                                    _formatDate(currentTestDate),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFD97706)),
                                        SizedBox(width: 2),
                                        Text(
                                          'Sắp kiểm tra',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFB45309),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Chưa có lịch kiểm tra (để trống nếu chưa biết)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                      ),
                      Text(
                        currentTestDate != null ? 'Đổi' : 'Chọn ngày',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (currentTestDate != null) ...<Widget>[
                const SizedBox(height: 10),
                _buildTextInput(
                  controller: _testTitleCtrl,
                  hintText: 'Tên bài kiểm tra (ví dụ: Giữa kỳ, 15 phút, Cuối kỳ)',
                ),
              ],
              const SizedBox(height: 22),

              // Field 6: Màu đại diện matching Image 1 + Color Picker from Image 3
              _buildFieldLabel('Màu đại diện'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  ..._presetColors.map((Color color) {
                    final bool isSelected = _colorToInt(_selectedColor) == _colorToInt(color);
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: isSelected
                            ? Center(
                                child: Container(
                                  width: 15,
                                  height: 15,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  }),
                  // Custom Color Picker Button (Palette / Rainbow Wheel from Image 3)
                  GestureDetector(
                    onTap: _openColorPicker,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const SweepGradient(
                          colors: <Color>[
                            Colors.red,
                            Colors.yellow,
                            Colors.green,
                            Colors.cyan,
                            Colors.blue,
                            Color(0xFFFF00FF),
                            Colors.red,
                          ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: !_presetColors.any((Color c) => _colorToInt(c) == _colorToInt(_selectedColor))
                              ? Colors.black
                              : Colors.white,
                          width: 2.5,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: _selectedColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Button: Lưu môn học
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF3B82F6), Color(0xFF6366F1), Color(0xFF7C3AED)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: _saveSubject,
                    child: const Center(
                      child: Text(
                        'Lưu môn học',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF94A3B8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
