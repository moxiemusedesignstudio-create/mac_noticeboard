import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StudentLeaderboardPage extends StatefulWidget {
  final bool isSliderView;
  const StudentLeaderboardPage({super.key, this.isSliderView = false});

  @override
  State<StudentLeaderboardPage> createState() => _StudentLeaderboardPageState();
}

class _StudentLeaderboardPageState extends State<StudentLeaderboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, String> _studentNames = {};
  final Map<String, String> _studentToGroup = {};
  List<MapEntry<String, int>> _sortedStudents = [];
  bool _isLoading = true;
  String _currentMonthName = '';
  DateTime _startOfMonth = DateTime.now();
  DateTime _endOfMonth = DateTime.now();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _setCurrentMonthRange();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) => _loadData());
  }

  void _setCurrentMonthRange() {
    DateTime now = DateTime.now();
    _currentMonthName = DateFormat('MMMM yyyy').format(now).toUpperCase();
    _startOfMonth = DateTime(now.year, now.month, 1);
    _endOfMonth = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
  }

  Future<void> _loadData() async {
    try {
      if (_studentNames.isEmpty) {
        var agentsSnapshot = await _firestore.collection('agents').get();
        for (var doc in agentsSnapshot.docs) {
          _studentNames[doc.id] = doc.data()['name']?.toString() ?? doc.id;
        }

        var groupsSnapshot = await _firestore.collection('groups').get();
        for (var doc in groupsSnapshot.docs) {
          List students = doc.data()['students'] ?? [];
          for (var s in students) {
            _studentToGroup[s.toString()] = doc.id;
          }
        }
      }

      var marksSnapshot = await _firestore
          .collection('marks')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(_startOfMonth))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(_endOfMonth))
          .get();

      Map<String, int> studentScores = {};
      for (var doc in marksSnapshot.docs) {
        String? studentId = doc.data()['studentId']?.toString();
        if (studentId != null && studentId.isNotEmpty) {
          int mark = int.tryParse(doc.data()['marks'].toString()) ?? 0;
          studentScores[studentId] = (studentScores[studentId] ?? 0) + mark;
        }
      }

      if (mounted) {
        setState(() {
          _sortedStudents = studentScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _getRankBadge(int rank, bool isSliderView) {
    double size = isSliderView ? 28 : 36;
    if (rank == 1) return Icon(Icons.emoji_events, color: const Color(0xFFFFD700), size: size);
    if (rank == 2) return Icon(Icons.emoji_events, color: const Color(0xFFC0C0C0), size: size);
    if (rank == 3) return Icon(Icons.emoji_events, color: const Color(0xFFCD7F32), size: size);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle),
      child: Icon(Icons.stars_rounded, color: const Color(0xFF10B981).withValues(alpha: 0.6), size: size - 10),
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
      return const Scaffold(backgroundColor: bgBackground, body: Center(child: CircularProgressIndicator(color: accentColor)));
    }

    int displayedRank = 1;

    Widget mainContent = ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: widget.isSliderView ? 12 : 24, vertical: widget.isSliderView ? 16 : 24),
      itemCount: _sortedStudents.length,
      itemBuilder: (context, index) {
        var entry = _sortedStudents[index];
        int totalMark = entry.value;
        String studentName = _studentNames[entry.key] ?? entry.key;
        String groupName = _studentToGroup[entry.key] ?? "NO GROUP";

        if (index > 0 && totalMark < _sortedStudents[index - 1].value) {
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
            border: Border.all(color: isFirst ? const Color(0xFFFFD700) : bgCard.withValues(alpha: 0.5), width: isFirst ? 2.5 : 1.0),
          ),
          child: Row(
            children: [
              SizedBox(width: widget.isSliderView ? 45 : 60, child: _getRankBadge(displayedRank, widget.isSliderView)),
              const SizedBox(width: 12),
              Text("#$displayedRank", style: TextStyle(fontSize: widget.isSliderView ? 12 : 15, fontWeight: FontWeight.bold, color: isFirst ? const Color(0xFFFFD700) : textSecondary.withValues(alpha: 0.7))),
              SizedBox(width: widget.isSliderView ? 12 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(studentName.toUpperCase(), style: TextStyle(fontSize: widget.isSliderView ? 16 : 22, fontWeight: FontWeight.bold, color: isFirst ? const Color(0xFFFFD700) : textPrimary)),
                    const SizedBox(height: 4),
                    Text(groupName.toUpperCase(), style: TextStyle(fontSize: widget.isSliderView ? 11 : 14, fontWeight: FontWeight.w600, color: isFirst ? const Color(0xFFFFD700).withValues(alpha: 0.7) : textSecondary.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: isFirst ? const Color(0xFFFFD700).withValues(alpha: 0.1) : bgBackground, borderRadius: BorderRadius.circular(12)),
                child: Text("$totalMark", style: TextStyle(fontSize: widget.isSliderView ? 16 : 22, fontWeight: FontWeight.w900, color: isFirst ? const Color(0xFFFFD700) : accentColor, fontFamily: 'monospace')),
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
              padding: const EdgeInsets.symmetric(vertical: 16), width: double.infinity, color: bgSurface,
              child: Column(
                children: [
                  Text("TOP PERFORMERS - $_currentMonthName", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accentColor, letterSpacing: 2)),
                  const SizedBox(height: 2),
                  const Text("LIVE SCORES", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textSecondary, letterSpacing: 1.5)),
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
              padding: const EdgeInsets.symmetric(vertical: 24), width: double.infinity,
              decoration: BoxDecoration(color: bgSurface, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)), border: Border(bottom: BorderSide(color: bgCard.withValues(alpha: 0.5)))),
              child: Column(
                children: [
                  const Icon(Icons.person_pin_rounded, color: accentColor, size: 55),
                  const SizedBox(height: 12),
                  const Text("TOP PERFORMERS", style: TextStyle(color: textPrimary, fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  const Text("LIVE SCORES", style: TextStyle(color: accentColor, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  Text(_currentMonthName, style: const TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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