import 'package:flutter/material.dart';
import '../models/subject_model.dart';
import '../models/term_model.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';
import 'add_subject_screen.dart';
import 'subject_detail_screen.dart';

class SubjectsTab extends StatefulWidget {
  final VoidCallback onDataChanged;
  const SubjectsTab({super.key, required this.onDataChanged});

  @override
  State<SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends State<SubjectsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTermFilter = 'Tất cả';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshSubjects() {
    setState(() {});
  }

  List<String> _getTermFilterOptions() {
    final List<TermModel> terms = LocalStorageService.instance.getTerms();
    final List<String> options = <String>['Tất cả', 'Học kỳ I', 'Học kỳ II'];
    for (final TermModel t in terms) {
      final String cleanName = t.name.trim();
      if (cleanName.isNotEmpty && !options.contains(cleanName)) {
        options.add(cleanName);
      }
    }
    return options;
  }

  List<SubjectModel> _filterSubjects(List<SubjectModel> allSubjects, String activeFilter) {
    return allSubjects.where((SubjectModel sub) {
      // Filter by term pill
      if (activeFilter != 'Tất cả') {
        final String subTermPrefix = sub.termId.split('·').first.trim().toLowerCase();
        final String filterLower = activeFilter.toLowerCase();
        if (subTermPrefix != filterLower && !sub.termId.toLowerCase().contains(filterLower)) {
          return false;
        }
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final String q = _searchQuery.toLowerCase();
        final bool matchesName = sub.name.toLowerCase().contains(q);
        final bool matchesCode = sub.code.toLowerCase().contains(q);
        final bool matchesTeacher = sub.teacher.toLowerCase().contains(q);
        return matchesName || matchesCode || matchesTeacher;
      }

      return true;
    }).toList();
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }

  void _navigateToAddSubject() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => AddSubjectScreen(
          onSubjectAdded: () {
            _refreshSubjects();
            widget.onDataChanged();
          },
        ),
      ),
    );
  }

  void _navigateToSubjectDetail(SubjectModel subject) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => SubjectDetailScreen(
          subject: subject,
          onUpdated: () {
            _refreshSubjects();
            widget.onDataChanged();
          },
        ),
      ),
    );
  }

  Future<void> _deleteSubject(SubjectModel subject) async {
    await LocalStorageService.instance.deleteSubject(subject.id);
    _refreshSubjects();
    widget.onDataChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa môn "${subject.name}"'),
          action: SnackBarAction(
            label: 'Hoàn tác',
            textColor: Colors.amber,
            onPressed: () async {
              await LocalStorageService.instance.addSubject(subject);
              _refreshSubjects();
              widget.onDataChanged();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<SubjectModel> allSubjects = LocalStorageService.instance.getSubjects();
    final UserModel? user = LocalStorageService.instance.getCurrentUser();
    final String userName = (user?.name != null && user!.name.isNotEmpty) ? user.name : 'Minh';
    final String userInitial = userName[0].toUpperCase();

    final List<String> termOptions = _getTermFilterOptions();
    final String activeFilter = termOptions.contains(_selectedTermFilter) ? _selectedTermFilter : 'Tất cả';
    final List<SubjectModel> displayList = _filterSubjects(allSubjects, activeFilter);

    return ColoredBox(
      color: const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 12),

          // Top Header: StudyFlow + User Avatar "M"
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
                    color: Color(0xFF3B82F6),
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
          const SizedBox(height: 18),

          // Main Title: "Danh sách môn học"
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Danh sách môn học',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar: "Tìm kiếm môn học..."
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (String val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm môn học...',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Filter Pills: "Tất cả", "Học kỳ I", "Học kỳ II"
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: termOptions.length,
              separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 10),
              itemBuilder: (BuildContext context, int index) {
                final String option = termOptions[index];
                final bool isSelected = option == activeFilter;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTermFilter = option;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: <Color>[Color(0xFF6366F1), Color(0xFF7C3AED)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFFEEF2F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Subjects List
          Expanded(
            child: displayList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(Icons.menu_book_rounded, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'Chưa có môn học nào',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    itemCount: displayList.length,
                    itemBuilder: (BuildContext context, int index) {
                      final SubjectModel sub = displayList[index];
                      final Color subjColor = Color(sub.colorValue);
                      final DateTime? subTestDate = sub.testDate;

                      return Dismissible(
                        key: Key(sub.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (DismissDirection direction) => _deleteSubject(sub),
                        child: GestureDetector(
                          onTap: () => _navigateToSubjectDetail(sub),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: <Widget>[
                                // Left rounded square badge with symbol
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: subjColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      sub.symbol.isNotEmpty
                                          ? sub.symbol
                                          : (sub.name.isNotEmpty ? sub.name[0].toUpperCase() : 'S'),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: subjColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Subject Name + Weekly Periods + Optional Bright Test Badge
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Flexible(
                                            child: Text(
                                              sub.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (subTestDate != null) ...<Widget>[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF3C7),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFFDE68A)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFFD97706)),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    'Thi ${_formatDate(subTestDate)}',
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
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${sub.weeklyPeriods} tiết / tuần',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Right Score matching subject color
                                Text(
                                  sub.calculatedScore.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: subjColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Full-Width "+ Thêm môn học" Button matching screenshot
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF4F86F7), Color(0xFF6366F1), Color(0xFF7C3AED)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _navigateToAddSubject,
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.add_rounded, color: Colors.white, size: 22),
                        SizedBox(width: 6),
                        Text(
                          'Thêm môn học',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
