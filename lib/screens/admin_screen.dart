import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  final _viewsController = TextEditingController(text: "3");

  String? _selectedYear;
  List<String> _selectedSubjects = [];

  bool _loading = false;
  String? _currentUid;

  final FirebaseFirestore _fire = FirebaseFirestore.instance;

  final Map<String, List<String>> subjectsByYear = {
    "1": ["foundation", "organic chemistry", "anatomy", 'health informatics'],
    "2": [
      "basics of Molecular biology",
      "systemic physiology",
      'biochemistry 2',
    ],
    "3": [
      "forensic chemistry",
      "basic introduction of virus and medical fungi",
    ],
    "4": [
      "histopathology and cytology",
      "blood bank",
      "parasitology",
      "immunology",
    ],
  };

  // ✅ Create Auth User
  Future<String> createAuthUser(String email, String password) async {
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$Firebase_WebApiKey',
    );
    final body = json.encode({
      'email': email,
      'password': password,
      'returnSecureToken': false,
    });
    final res = await http.post(
      url,
      body: body,
      headers: {'Content-Type': 'application/json'},
    );

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['localId'] as String;
    } else {
      throw Exception('Failed to create auth user: ${res.body}');
    }
  }

  // ✅ Create user doc
  Future<void> createUserDoc({
    required String uid,
    required String email,
    required String year,
    required List<String> subjects,
    required int remainingViews,
  }) async {
    await _fire.collection('users').doc(uid).set({
      'email': email,
      'role': 'student',
      'year': year,
      'subjects': subjects,
      'deviceId': null,
      'remainingViews': remainingViews,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ Update user doc
  Future<void> updateUserDoc({
    required String uid,
    required String year,
    required List<String> subjects,
    required int remainingViews,
  }) async {
    await _fire.collection('users').doc(uid).update({
      'year': year,
      'subjects': subjects,
      'remainingViews': remainingViews,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ Fetch student
  Future<void> fetchStudentByEmail(String email) async {
    setState(() => _loading = true);
    try {
      final snapshot = await _fire
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("لم يتم العثور على هذا الطالب")),
        );
      } else {
        final data = snapshot.docs.first.data();
        _currentUid = snapshot.docs.first.id;

        setState(() {
          _selectedYear = data['year'];
          _selectedSubjects = List<String>.from(data['subjects'] ?? []);
          _viewsController.text = "${data['remainingViews'] ?? 3}";
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
    setState(() => _loading = false);
  }

  Future<void> createStudentFull() async {
    final email = _emailController.text.trim();
    final password = _passController.text.trim();
    final views = int.tryParse(_viewsController.text.trim()) ?? 3;

    if (email.isEmpty ||
        password.isEmpty ||
        _selectedYear == null ||
        _selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("يرجى ملء جميع الحقول")));
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = await createAuthUser(email, password);
      await createUserDoc(
        uid: uid,
        email: email,
        year: _selectedYear!,
        subjects: _selectedSubjects,
        remainingViews: views,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم إنشاء الطالب بنجاح!")));
      resetForm();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
    setState(() => _loading = false);
  }

  Future<void> updateStudentFull() async {
    final views = int.tryParse(_viewsController.text.trim()) ?? 3;

    if (_currentUid == null ||
        _selectedYear == null ||
        _selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى اختيار طالب وتعبئة الحقول")),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await updateUserDoc(
        uid: _currentUid!,
        year: _selectedYear!,
        subjects: _selectedSubjects,
        remainingViews: views,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم تحديث بيانات الطالب!")));
      resetForm();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    }
    setState(() => _loading = false);
  }

  void resetForm() {
    _emailController.clear();
    _passController.clear();
    _viewsController.text = "3";
    setState(() {
      _selectedYear = null;
      _selectedSubjects = [];
      _currentUid = null;
    });
  }

  Future<void> deleteStudent() async {
    if (_currentUid == null || _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("يرجى البحث عن الطالب أولاً")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تأكيد الحذف"),
        content: const Text("هل أنت متأكد أنك تريد حذف هذا الطالب نهائياً؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("حذف"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      // 1️⃣ حذف من Firestore
      await _fire.collection('users').doc(_currentUid).delete();

      // 2️⃣ حذف من Firebase Auth (REST API)
      await deleteAuthUserByEmail(email: _emailController.text.trim());

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("تم حذف الطالب بنجاح")));
      resetForm();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ أثناء الحذف: $e")));
    }
    setState(() => _loading = false);
  }

  Future<void> deleteAuthUserByEmail({required String email}) async {
    try {
      // أول حاجة نحصل على token عن طريق login
      final loginUrl = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$Firebase_WebApiKey',
      );

      final loginRes = await http.post(
        loginUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': _passController.text.trim(),
          'returnSecureToken': true,
        }),
      );

      if (loginRes.statusCode != 200) {
        throw Exception('لم يتم تسجيل الدخول لحذف المستخدم: ${loginRes.body}');
      }

      final idToken = json.decode(loginRes.body)['idToken'];

      // بعدين نحذف الحساب
      final deleteUrl = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:delete?key=$Firebase_WebApiKey',
      );

      final deleteRes = await http.post(
        deleteUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': idToken}),
      );

      if (deleteRes.statusCode != 200) {
        throw Exception('فشل حذف المستخدم من Auth: ${deleteRes.body}');
      }
    } catch (e) {
      throw Exception("فشل حذف المستخدم من Auth: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Admin - Add / Update Student"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                CustomTextField(
                  controller: _emailController,
                  hint: "البريد الإلكتروني",
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _passController,
                  hint: "كلمة المرور",
                  isPassword: true,
                ),
                const SizedBox(height: 12),

                // زر البحث
                ElevatedButton.icon(
                  onPressed: () =>
                      fetchStudentByEmail(_emailController.text.trim()),
                  icon: const Icon(Icons.search),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue[600],
                    minimumSize: const Size.fromHeight(45),
                  ),
                  label: const Text(
                    "بحث عن طالب موجود",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: "اختر السنة",
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedYear,
                  items: subjectsByYear.keys.map((year) {
                    return DropdownMenuItem(
                      value: year,
                      child: Text("Year $year"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value;
                      _selectedSubjects = [];
                    });
                  },
                ),
                const SizedBox(height: 12),

                if (_selectedYear != null)
                  Column(
                    children: subjectsByYear[_selectedYear]!
                        .map(
                          (subject) => CheckboxListTile(
                            title: Text(subject),
                            value: _selectedSubjects.contains(subject),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedSubjects.add(subject);
                                } else {
                                  _selectedSubjects.remove(subject);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 12),

                CustomTextField(
                  controller: _viewsController,
                  hint: "عدد المشاهدات المسموح بها",
                ),
                const SizedBox(height: 20),

                _loading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: createStudentFull,
                            icon: const Icon(Icons.person_add),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(45),
                            ),
                            label: const Text(
                              "إضافة طالب",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: updateStudentFull,
                            icon: const Icon(Icons.update),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(45),
                            ),
                            label: const Text(
                              "تحديث بيانات الطالب",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: deleteStudent,
                            icon: const Icon(Icons.delete),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(45),
                            ),
                            label: const Text(
                              "حذف الطالب",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
