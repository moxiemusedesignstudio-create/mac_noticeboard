import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InstitutionLeaderboardPage extends StatefulWidget {
  final bool isSliderView;
  const InstitutionLeaderboardPage({super.key, this.isSliderView = false});

  @override
  State<InstitutionLeaderboardPage> createState() =>
      _InstitutionLeaderboardPageState();
}

class _InstitutionLeaderboardPageState
    extends State<InstitutionLeaderboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, String> _institutionNames = {};
  List<String> _institutionIds = [];
  bool _isLoadingInstitutions = true;

  // ഗ്രൂപ്പ് ലീഡർബോർഡിലെ അതേ പ്രീമിയം കളർ തീം
  static const Color bgBackground = Color(0xFF0B0F19);
  static const Color bgSurface = Color(0xFF161D2F);
  static const Color bgCard = Color(0xFF242F49);
  static const Color accentColor = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _loadClubDetails();
  }

  // 1. എല്ലാ ക്ലബ്ബുകളുടെയും ഐഡിയും പേരും ലോഡ് ചെയ്യുന്നു
  Future<void> _loadClubDetails() async {
    try {
      var clubsSnapshot = await _firestore.collection('clubs').get();
      Map<String, String> tempNames = {};
      List<String> tempIds = [];

      for (var doc in clubsSnapshot.docs) {
        var data = doc.data();
        tempNames[doc.id] = data['name']?.toString() ?? '';
        tempIds.add(doc.id);
      }

      setState(() {
        _institutionNames = tempNames;
        _institutionIds = tempIds;
        _isLoadingInstitutions = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingInstitutions = false;
      });
    }
  }

  // 2. നിങ്ങളുടെ പഴയ സബ്‌കളക്ഷനിൽ (programs) നിന്നും ടോട്ടൽ ലൈവ് മാർക്കുകൾ ഫെച്ച് ചെയ്യുന്നു (ടൈം ഫിൽട്ടർ ഒഴിവാക്കി)
  Future<Map<String, int>> _getLiveMarks() async {
    Map<String, int> institutionMarksMap = {};

    for (var id in _institutionIds) {
      institutionMarksMap[id] = 0;
    }

    List<Future<void>> futures = _institutionIds.map((institutionId) async {
      try {
        // ഇവിടെ തീയതി നോക്കാതെ ആകെ ലഭിച്ച എല്ലാ മാർക്കുകളും കൂട്ടി ലൈവ് സ്കോർ എടുക്കുന്നു
        var programsSnapshot = await _firestore
            .collection('institutions')
            .doc(institutionId)
            .collection('programs')
            .get();

        int total = 0;
        for (var doc in programsSnapshot.docs) {
          var data = doc.data();
          total += int.tryParse(data['mark'].toString()) ?? 0;
        }
        institutionMarksMap[institutionId] = total;
      } catch (e) {
        // എറർ വന്നാൽ 0 ആയി തുടരും
      }
    }).toList();

    await Future.wait(futures);
    return institutionMarksMap;
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
        color: accentColor.withValues(alpha: 0.6),
        size: size - 10,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInstitutions) {
      return const Scaffold(
        backgroundColor: bgBackground,
        body: Center(
          child: CircularProgressIndicator(color: accentColor, strokeWidth: 3),
        ),
      );
    }

    return FutureBuilder<Map<String, int>>(
      future: _getLiveMarks(),
      builder: (context, marksSnapshot) {
        if (!marksSnapshot.hasData) {
          return const Scaffold(
            backgroundColor: bgBackground,
            body: Center(
              child: CircularProgressIndicator(
                color: accentColor,
                strokeWidth: 3,
              ),
            ),
          );
        }

        Map<String, int> liveMarks = marksSnapshot.data!;

        var sortedInstitutionIds = List<String>.from(_institutionIds)
          ..sort((a, b) {
            int markA = liveMarks[a] ?? 0;
            int markB = liveMarks[b] ?? 0;
            return markB.compareTo(markA);
          });

        int displayedRank = 1;

        Widget mainContent = ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSliderView ? 12 : 24,
            vertical: widget.isSliderView ? 16 : 24,
          ),
          itemCount: sortedInstitutionIds.length,
          itemBuilder: (context, index) {
            String institutionId = sortedInstitutionIds[index];
            String institutionName = _institutionNames[institutionId] ?? '';
            int totalMark = liveMarks[institutionId] ?? 0;

            if (index > 0) {
              String prevInstitutionId = sortedInstitutionIds[index - 1];
              int prevMark = liveMarks[prevInstitutionId] ?? 0;
              if (totalMark < prevMark) {
                displayedRank++;
              }
            } else {
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
                      institutionName.toUpperCase(),
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
                        "INSTITUTION RANKINGS",
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
                      Icon(Icons.emoji_events, color: accentColor, size: 55),
                      SizedBox(height: 12),
                      Text(
                        "CLUB RANKINGS",
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "LIVE SCORES",
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
      },
    );
  }
}
