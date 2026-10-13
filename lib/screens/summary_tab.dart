import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/local_storage_service.dart';

class SummaryTab extends StatelessWidget {
  final VoidCallback onDataChanged;
  const SummaryTab({super.key, required this.onDataChanged});

  @override
  Widget build(BuildContext context) {
    final user = LocalStorageService.instance.getCurrentUser();
    final subjects = LocalStorageService.instance.getSubjects();

    double calculatedGpa = 0.0;
    int totalCredits = 0;
    if (subjects.isNotEmpty) {
      double totalWeightedScore = 0.0;
      for (final s in subjects) {
        totalWeightedScore += s.score * s.credits;
        totalCredits += s.credits;
      }
      calculatedGpa = totalCredits > 0 ? (totalWeightedScore / totalCredits) : (user?.gpa ?? 8.4);
    } else {
      calculatedGpa = user?.gpa ?? 8.4;
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tổng kết học tập',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GPA Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.heroCardGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryIndigo.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ĐIỂM TRUNG BÌNH HỌC KỲ',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        calculatedGpa.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '/ 10.0',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Xếp loại Giỏi 🌟',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Bạn đang có thành tích rất xuất sắc! Hãy tiếp tục duy trì nhé.',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Performance metrics row
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Tổng tín chỉ',
                    value: '$totalCredits',
                    icon: Icons.school_rounded,
                    color: AppColors.statPurple,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Môn đã hoàn thành',
                    value: '${subjects.length}/${subjects.length}',
                    icon: Icons.check_circle_rounded,
                    color: AppColors.statGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Score Distribution
            const Text(
              'Phân bố điểm các môn',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildProgressRow(
                    label: 'Điểm A (8.5 - 10.0)',
                    count: subjects.where((s) => s.score >= 8.5).length,
                    total: subjects.isEmpty ? 1 : subjects.length,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 14),
                  _buildProgressRow(
                    label: 'Điểm B (7.0 - 8.4)',
                    count: subjects.where((s) => s.score >= 7.0 && s.score < 8.5).length,
                    total: subjects.isEmpty ? 1 : subjects.length,
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 14),
                  _buildProgressRow(
                    label: 'Điểm C (5.5 - 6.9)',
                    count: subjects.where((s) => s.score >= 5.5 && s.score < 7.0).length,
                    total: subjects.isEmpty ? 1 : subjects.length,
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final double pct = total > 0 ? (count / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$count môn (${(pct * 100).toInt()}%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
