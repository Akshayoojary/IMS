import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnrollmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add an enrollment
  Future<void> enrollUser(String internshipId) async {
    User? user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('enrolled_users').add({
          'internshipId': internshipId,
          'userId': user.uid,
          'userName': user.displayName ?? '',
          'userEmail': user.email ?? '',
          'enrolledAt': FieldValue.serverTimestamp(),
          'status': 'active',
        });
        print("User enrolled successfully");
      } catch (e) {
        print("Error enrolling user: $e");
      }
    } else {
      print('No user is currently signed in.');
    }
  }

  // Fetch enrolled users for a specific internship
  Future<List<Map<String, dynamic>>> getEnrolledUsers(String internshipId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('enrolled_users')
          .where('internshipId', isEqualTo: internshipId)
          .get();

      List<Map<String, dynamic>> enrolledUsers = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return enrolledUsers;
    } catch (e) {
      print("Error fetching enrolled users: $e");
      return [];
    }
  }

  // Update enrollment status
  Future<void> updateEnrollmentStatus(String enrollmentId, String newStatus) async {
    try {
      await _firestore.collection('enrolled_users').doc(enrollmentId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print("Enrollment status updated successfully");
    } catch (e) {
      print("Error updating enrollment status: $e");
    }
  }

  // Remove an enrollment
  Future<void> removeEnrollment(String enrollmentId) async {
    try {
      await _firestore.collection('enrolled_users').doc(enrollmentId).delete();
      print("Enrollment removed successfully");
    } catch (e) {
      print("Error removing enrollment: $e");
    }
  }
}
