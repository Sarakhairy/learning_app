import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:learning_app/constants.dart';
import 'package:learning_app/widgets/cutom_textfield.dart';


class AdminAddStudentScreen extends StatefulWidget {
  const AdminAddStudentScreen({super.key});

  @override
  State<AdminAddStudentScreen> createState() => _AdminAddStudentScreenState();
}

class _AdminAddStudentScreenState extends State<AdminAddStudentScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _levelController = TextEditingController();
  final _viewsController = TextEditingController(text: "3"); // عدد المشاهدات الافتراضي

  bool _loading = false;

  final FirebaseFirestore _fire = FirebaseFirestore.instance;

  /// 1️⃣ إنشاء حساب Auth عبر REST API
  Future<String> createAuthUser(String email, String password) async {
    final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$Firebase_WebApiKey');
    final body = json.encode({
      'email': email,
      'password': password,
      'returnSecureToken': false,
    });
    final res = await http.post(url,
        body: body, headers: {'Content-Type': 'application/json'});

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final uid = data['localId'] as String;
      return uid;
    } else {
      throw Exception('Failed to create auth user: ${res.body}');
    }
  }

  /// 2️⃣ إنشاء مستند Firestore
  Future<void> createUserDoc({
    required String uid,
    required String email,
    required String level,
    required int remainingViews,
  }) async {
    await _fire.collection('users').doc(uid).set({
      'email': email,
      'role': 'student',
      'level': level,
      'deviceId': null,
      'remainingViews': remainingViews,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 3️⃣ كامل flow: إنشاء Auth + Firestore
  Future<void> createStudentFull() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();
    final level = _levelController.text.trim();
    final views = int.tryParse(_viewsController.text.trim()) ?? 3;

    if (email.isEmpty || password.isEmpty || level.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("يرجى ملء جميع الحقول")));
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = await createAuthUser(email, password);
      await createUserDoc(uid: uid, email: email, level: level, remainingViews: views);

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("تم إنشاء الطالب بنجاح!")));
      _emailController.clear();
      _passController.clear();
      _levelController.clear();
      _viewsController.text = "3";
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin - Add Student")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CustomTextField(controller: _emailController, hint: "Email"),
            const SizedBox(height: 12),
            CustomTextField(controller: _passController, hint: "Password", isPassword: true),
            const SizedBox(height: 12),
            CustomTextField(controller: _levelController, hint: "Level (مثال: Level1)"),
            const SizedBox(height: 12),
            CustomTextField(controller: _viewsController, hint: "عدد المشاهدات المسموح بها"),
            const SizedBox(height: 20),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: createStudentFull,
                    child: const Text("Add Student"),
                  ),
          ],
        ),
      ),
    );
  }
}
