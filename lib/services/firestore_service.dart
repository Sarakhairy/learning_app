import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHelper {
  final String firebaseWebApiKey;
  final FirebaseFirestore _fire = FirebaseFirestore.instance;

  AdminHelper({required this.firebaseWebApiKey});

  /// 1) Create Auth user via REST, returns the uid (localId)
  Future<String> createAuthUser(String email, String password) async {
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$firebaseWebApiKey');
    final body = json.encode({'email': email, 'password': password, 'returnSecureToken': false});
    final res = await http.post(url, body: body, headers: {'Content-Type': 'application/json'});
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      final uid = data['localId'] as String;
      return uid;
    } else {
      throw Exception('Failed to create auth user: ${res.body}');
    }
  }

  /// 2) Create Firestore user doc using uid as doc id
  Future<void> createUserDoc({
    required String uid,
    required String email,
    required String role, // 'student' or 'admin'
    required String level, // e.g. "1"
    int remainingViews = 3,
  }) async {
    await _fire.collection('users').doc(uid).set({
      'email': email,
      'role': role,
      'level': level,
      'deviceId': null,
      'remainingViews': remainingViews,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
  }

  /// Convenience: full flow (create auth + fire user doc)
  Future<void> createStudentFull({required String email, required String password, required String level}) async {
    final uid = await createAuthUser(email, password);
    await createUserDoc(uid: uid, email: email, role: 'student', level: level);
  }
}
class FirestoreService {
  final _firestore = FirebaseFirestore.instance;

  Future<String?> getStudentLevel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    if (snapshot.exists) {
      return snapshot['level'];
    }
    return null;
  }

  Future<String?> getPlaylistIdForLevel(String level) async {
    final snapshot = await _firestore.collection('playlists').doc(level).get();
    if (snapshot.exists) {
      return snapshot['playlistId'];
    }
    return null;
  }

  Future<void> decrementRemainingViews(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'remainingViews': FieldValue.increment(-1),
    });
  }
}
