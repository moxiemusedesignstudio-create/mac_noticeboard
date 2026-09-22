import 'package:flutter/material.dart';

import 'digital_screen.dart';
import 'admin_dashboard.dart';
import 'main_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 850;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            radius: 1.2,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 48,
            ),
            child: Center(
              child: Wrap(
                spacing: 30,
                runSpacing: 30,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // 1. MAIN SCREEN BUTTON
                  _buildMenuButton(
                    context: context,
                    isMobile: isMobile,
                    title: "MAIN SCREEN",
                    icon: Icons.fullscreen_rounded,
                    colors: [const Color(0xFF0EA5E9), const Color(0xFF1E3A8A)],
                    shadowColor: Colors.blue,
                    nextScreen: const MainScreen(),
                  ),

                  // 2. DIGITAL SCREEN BUTTON
                  _buildMenuButton(
                    context: context,
                    isMobile: isMobile,
                    title: "DIGITAL SCREEN",
                    icon: Icons.tv,
                    colors: [const Color(0xFF0EA5E9), const Color(0xFF1E3A8A)],
                    shadowColor: Colors.blue,
                    nextScreen: const DigitalScreen(),
                  ),

                  _buildMenuButton(
                    context: context,
                    isMobile: isMobile,
                    title: "ADMIN PANEL",
                    icon: Icons.admin_panel_settings,
                    colors: [
                      const Color.fromARGB(255, 233, 14, 14),
                      const Color.fromARGB(255, 138, 2, 2),
                    ],
                    shadowColor: Colors.red,
                    nextScreen: const AdminDashboard(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required bool isMobile,
    required String title,
    required IconData icon,
    required List<Color> colors,
    required MaterialColor shadowColor,
    required Widget nextScreen,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isMobile ? 320 : 380,
        height: isMobile ? 180 : 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.3),
              blurRadius: 25,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: isMobile ? 55 : 70),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 22 : 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
