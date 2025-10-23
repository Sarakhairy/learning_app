import 'package:flutter/material.dart';
import 'package:learning_app/constants.dart';
import 'package:learning_app/screens/forgot_paassword_screen.dart';
import 'package:learning_app/screens/playlist_screen.dart';
import 'package:learning_app/services/auth_service.dart';
import 'package:learning_app/screens/admin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // _checkLoginStatus();
  }

  // ✅ التحقق هل المستخدم سجل دخول قبل كده
  // Future<void> _checkLoginStatus() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final savedEmail = prefs.getString("userEmail");
  //   if (savedEmail != null && savedEmail.isNotEmpty) {
  //     if (savedEmail.contains(AdminEmail)) {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (_) => const AdminAddStudentScreen()),
  //       );
  //     } else {
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (_) => const MyVideosPage()),
  //       );
  //     }
  //   }
  // }

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final user =
          await _auth.signIn(_emailController.text.trim(), _passController.text.trim());

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("userEmail", _emailController.text.trim());

        if (_emailController.text.contains(AdminEmail)) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminAddStudentScreen()));
        } else {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const MyVideosPage()));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ: $e")));
          print(e);
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ Logo
                Icon(Icons.school, size: 90, color: Colors.blue[800]),
                const SizedBox(height: 16),
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Login to continue",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // ✅ Email
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Password
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),

                // ✅ زرار تسجيل الدخول
                _loading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 12),

                // ✅ Forgot password
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
