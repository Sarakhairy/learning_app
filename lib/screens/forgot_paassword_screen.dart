import 'package:flutter/material.dart';
import 'package:learning_app/widgets/cutom_textfield.dart';
import '../services/auth_service.dart';


class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  void _resetPassword() async {
    setState(() => _loading = true);
    try {
      await _auth.resetPassword(_emailController.text);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم إرسال رابط لإعادة التعيين")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("أدخل إيميلك لإرسال رابط إعادة كلمة المرور"),
            const SizedBox(height: 20),
            CustomTextField(controller: _emailController, hint: "Email"),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _resetPassword, child: const Text("Send Link")),
          ],
        ),
      ),
    );
  }
}
