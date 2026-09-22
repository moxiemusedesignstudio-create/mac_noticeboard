import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentLeaderboardPage extends StatefulWidget {
  final bool isSliderView;
  const DepartmentLeaderboardPage({super.key, this.isSliderView = false});

  @override
  State<DepartmentLeaderboardPage> createState() =>
      _DepartmentLeaderboardPageState();
}

class _DepartmentLeaderboardPageState extends State<DepartmentLeaderboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, String> _studentToDepartment = {};
  List<MapEntry<String, int>> _sortedDepartments = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _loadAllData(),
    );
  }

  Future<void> _loadAllData() async {
    try {
      if (_studentToDepartment.isEmpty) {
        var departmentsSnapshot = await _firestore
            .collection('departments')
            .get(const GetOptions(source: Source.serverAndCache));

        for (var doc in departmentsSnapshot.docs) {
          var data = doc.data();
          List students = data['students'] ?? [];
          for (var s in students) {
            _studentToDepartment[s.toString()] = doc.id;
          }
        }
      }

      var marksSnapshot = await _firestore
          .collection('marks')
          .get(const GetOptions(source: Source.serverAndCache));

      Map<String, int> departmentScores = {};
      _studentToDepartment.values.toSet().forEach(
        (departmentId) => departmentScores[departmentId] = 0,
      );

      for (var doc in marksSnapshot.docs) {
        var d = doc.data();
        String? departmentId = _studentToDepartment[d['studentId']?.toString()];
        if (departmentId != null) {
          int mark = int.tryParse(d['marks'].toString()) ?? 0;
          departmentScores[departmentId] =
              (departmentScores[departmentId] ?? 0) + mark;
        }
      }

      if (mounted) {
        setState(() {
          _sortedDepartments = departmentScores.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _loadFromServerDirectly();
      }
    }
  }

  Future<void> _loadFromServerDirectly() async {
    try {
      var marksSnapshot = await _firestore.collection('marks').get();
      Map<String, int> departmentScores = {};
      _studentToDepartment.values.toSet().forEach(
        (departmentId) => departmentScores[departmentId] = 0,
      );

      for (var doc in marksSnapshot.docs) {
        var d = doc.data();
        String? departmentId = _studentToDepartment[d['studentId']?.toString()];
        if (departmentId != null) {
          int mark = int.tryParse(d['marks'].toString()) ?? 0;
          departmentScores[departmentId] =
              (departmentScores[departmentId] ?? 0) + mark;
        }
      }
      if (mounted) {
        setState(() {
          _sortedDepartments = departmentScores.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _getRankBadge(int rank, bool isSliderView) {
    double size = isSliderView ? 28 : 36;
    if (rank == 1)
      return Icon(
        Icons.emoji_events,
        color: const Color(0xFFFFD700),
        size: size,
      );
    if (rank == 2)
      return Icon(
        Icons.emoji_events,
        color: const Color(0xFFC0C0C0),
        size: size,
      );
    if (rank == 3)
      return Icon(
        Icons.emoji_events,
        color: const Color(0xFFCD7F32),
        size: size,
      );
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.stars_rounded,
        color: const Color(0xFF10B981).withValues(alpha: 0.6),
        size: size - 10,
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgBackground = Color(0xFF0B0F19);
    const Color bgSurface = Color(0xFF161D2F);
    const Color bgCard = Color(0xFF242F49);
    const Color accentColor = Color(0xFF10B981);
    const Color textPrimary = Color(0xFFF9FAFB);
    const Color textSecondary = Color(0xFF9CA3AF);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: bgBackground,
        body: Center(
          child: CircularProgressIndicator(color: accentColor, strokeWidth: 3),
        ),
      );
    }

    int displayedRank = 1;

    Widget mainContent = ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isSliderView ? 12 : 24,
        vertical: widget.isSliderView ? 16 : 24,
      ),
      itemCount: _sortedDepartments.length,
      itemBuilder: (context, index) {
        var entry = _sortedDepartments[index];
        int totalMark = entry.value;

        if (index > 0 && totalMark < _sortedDepartments[index - 1].value) {
          displayedRank++;
        } else if (index == 0) {
          displayedRank = 1;
        }

        bool isFirst = displayedRank == 1;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(widget.isSliderView ? 16 : 24),
          decoration: BoxDecoration(
            color: isFirst ? const Color(0xFF1F2E3D) : bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isFirst
                  ? const Color(0xFFFFD700)
                  : bgCard.withValues(alpha: 0.5),
              width: isFirst ? 2.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: widget.isSliderView ? 40 : 55,
                child: _getRankBadge(displayedRank, widget.isSliderView),
              ),
              const SizedBox(width: 12),
              Text(
                "#$displayedRank",
                style: TextStyle(
                  fontSize: widget.isSliderView ? 12 : 15,
                  fontWeight: FontWeight.bold,
                  color: isFirst
                      ? const Color(0xFFFFD700)
                      : textSecondary.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(width: widget.isSliderView ? 12 : 20),
              Expanded(
                child: Text(
                  entry.key.toUpperCase(),
                  style: TextStyle(
                    fontSize: widget.isSliderView ? 16 : 22,
                    fontWeight: FontWeight.bold,
                    color: isFirst ? const Color(0xFFFFD700) : textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isFirst
                      ? const Color(0xFFFFD700).withValues(alpha: 0.1)
                      : bgBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$totalMark",
                  style: TextStyle(
                    fontSize: widget.isSliderView ? 16 : 22,
                    fontWeight: FontWeight.w900,
                    color: isFirst ? const Color(0xFFFFD700) : accentColor,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (widget.isSliderView) {
      return Scaffold(
        backgroundColor: bgBackground,
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              color: bgSurface,
              child: const Column(
                children: [
                  Text(
                    "DEPARTMENT STATUS",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "LIVE SCORES",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: mainContent),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              width: double.infinity,
              decoration: BoxDecoration(
                color: bgSurface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                border: Border(
                  bottom: BorderSide(color: bgCard.withValues(alpha: 0.5)),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.stars_rounded, color: accentColor, size: 55),
                  SizedBox(height: 12),
                  Text(
                    "GROUP RANKINGS",
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "CURRENT STANDINGS",
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: mainContent),
          ],
        ),
      ),
    );
  }
}
