import 'dart:async';
import 'package:flutter/material.dart';
import 'institution_leaderboard_page.dart';
import 'department_leaderboard_page.dart';
import 'student_leaderboard_page.dart';

class ScoreSlider extends StatefulWidget {
  const ScoreSlider({super.key});

  @override
  State<ScoreSlider> createState() => _ScoreSliderState();
}

class _ScoreSliderState extends State<ScoreSlider> {
  // PageController ഇവിടെ കൃത്യമായി ഡിക്ലെയർ ചെയ്തിട്ടുണ്ട്
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Timer? _timer;

  final List<Widget> _pages = [
    const InstitutionLeaderboardPage(isSliderView: true),
    const DepartmentLeaderboardPage(isSliderView: true),
    const StudentLeaderboardPage(isSliderView: true),
  ];

  @override
  void initState() {
    super.initState();
    _startSliderTimer();
  }

  void _startSliderTimer() {
    // 8 സെക്കൻഡ് കൂടുമ്പോൾ പേജ് മാറാനുള്ള ടൈമർ
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (!mounted) return;

      if (_currentPage < _pages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(
            milliseconds: 1200,
          ), // 1.2 സെക്കൻഡ് സ്മൂത്ത് ആനിമേഷൻ
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // മെമ്മറി ലീക്ക് ഒഴിവാക്കാൻ ടൈമർ ക്യാൻസൽ ചെയ്യുന്നു
    _pageController.dispose(); // കൺട്രോളർ ഡിസ്പോസ് ചെയ്യുന്നു
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller:
          _pageController, // FIXED: ഈ കൺട്രോളർ വിട്ടുപോയതാണ് സ്ലൈഡ് ആവാതിരിക്കാൻ കാരണം
      physics: const NeverScrollableScrollPhysics(), // മാനുവൽ സ്ക്രോളിങ് തടയാൻ
      children: _pages,
    );
  }
}
