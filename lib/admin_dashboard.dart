import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'main_screen_settings.dart';
import 'digital_screen_settings.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TextEditingController passwordController = TextEditingController();
  bool isAuthenticated = false;
  bool isPasswordVisible = false;
  final String adminPassword = "adm@mac";

  static const Color bgBackground = Color(0xFF0F172A);
  static const Color bgSurface = Color(0xFF1E293B);
  static const Color accentColor = Colors.indigoAccent;
  static const Color textPrimary = Colors.white;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isAuthenticated = prefs.getBool('isAdminLoggedIn') ?? false;
    });
  }

  Future<void> loginAdmin() async {
    if (passwordController.text == adminPassword) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdminLoggedIn', true);
      setState(() {
        isAuthenticated = true;
      });
      _showMessage("Access Granted! Welcome.");
    } else {
      _showMessage("Invalid Password!", isError: true);
    }
  }

  Future<void> logoutAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdminLoggedIn', false);
    setState(() {
      isAuthenticated = false;
      passwordController.clear();
    });
    _showMessage("Logged out successfully.");
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 850;

    if (!isAuthenticated) {
      return Scaffold(
        backgroundColor: bgBackground,
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 450,
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                color: bgSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_person_rounded,
                    size: 70,
                    color: accentColor,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    "ADMIN AUTHENTICATION",
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: passwordController,
                    obscureText: !isPasswordVisible,
                    style: const TextStyle(
                      color: textPrimary,
                      letterSpacing: 2,
                    ),
                    onSubmitted: (_) => loginAdmin(),
                    decoration: InputDecoration(
                      hintText: "Enter Admin Password",
                      hintStyle: const TextStyle(
                        color: Colors.white38,
                        letterSpacing: 0,
                      ),
                      prefixIcon: const Icon(Icons.key, color: Colors.white60),
                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.white60,
                        ),
                        onPressed: () => setState(
                          () => isPasswordVisible = !isPasswordVisible,
                        ),
                      ),
                      filled: true,
                      fillColor: bgBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: loginAdmin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "VERIFY SYSTEM ACCESS",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgBackground,
      appBar: AppBar(
        backgroundColor: bgSurface,
        elevation: 0,
        title: const Text(
          "ADMIN CONTROL CENTER",
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: logoutAdmin,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Wrap(
            spacing: 25,
            runSpacing: 25,
            alignment: WrapAlignment.center,
            children: [
              // 1. MAIN SCREEN SETTING BUTTON
              _buildSubMenuButton(
                context: context,
                isMobile: isMobile,
                title: "MAIN SCREEN\nSETTINGS",
                icon: Icons.fullscreen_rounded,
                colors: [
                  const Color.fromARGB(255, 233, 14, 14),
                  const Color.fromARGB(255, 138, 2, 2),
                ],
                nextPage: const MainScreenSettings(),
              ),

              // 2. DIGITAL SCREEN SETTING BUTTON
              _buildSubMenuButton(
                context: context,
                isMobile: isMobile,
                title: "DIGITAL SCREEN\nSETTINGS",
                icon: Icons.tv,
                colors: [
                  const Color.fromARGB(255, 233, 14, 14),
                  const Color.fromARGB(255, 138, 2, 2),
                ],
                nextPage: const DigitalScreenSettings(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubMenuButton({
    required BuildContext context,
    required bool isMobile,
    required String title,
    required IconData icon,
    required List<Color> colors,
    required Widget nextPage,
  }) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => nextPage)),
      child: Container(
        width: isMobile ? 280 : 320,
        height: isMobile ? 160 : 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors.last.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: isMobile ? 45 : 55),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
