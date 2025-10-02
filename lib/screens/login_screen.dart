import 'package:flutter/material.dart';
import 'package:learning_app/constants.dart';
import 'package:learning_app/screens/forgot_paassword_screen.dart';
import 'package:learning_app/screens/home_page.dart';
import 'package:learning_app/screens/playlist_screen.dart';
import 'package:learning_app/widgets/cutom_textfield.dart';
import '../services/auth_service.dart';
import 'admin_screen.dart';
import 'student_home_screen.dart';

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

  void _login() async {
    setState(() => _loading = true);
    try {
      final user =
          await _auth.signIn(_emailController.text, _passController.text);

      if (user != null) {
        // هنا هنحدد لو Admin أو Student من Firestore بعدين
        if (_emailController.text.contains(AdminEmail)) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const AdminAddStudentScreen()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) =>  MyVideosPage()));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Login", style: TextStyle(fontSize: 26)),
            const SizedBox(height: 20),
            CustomTextField(controller: _emailController, hint: "Email"),
            const SizedBox(height: 12),
            CustomTextField(
                controller: _passController, hint: "Password", isPassword: true),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text("Login"),
                  ),
            TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen()),
                  );
                },
                child: const Text("Forgot Password?"))
          ],
        ),
      ),
    );
  }
}
