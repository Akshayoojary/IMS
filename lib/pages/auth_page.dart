import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:ims/main-pages/home-page.dart';
import 'package:ims/Admin-pages/admin_page.dart';
import 'package:ims/pages/login_or_register_page.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            // User is logged in, check their role
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('user-log')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (userSnapshot.hasData) {
                  // Check if document exists before trying to access fields
                  if (!userSnapshot.data!.exists) {
                    return Scaffold(
                      body: Center(child: Text('User data not found')),
                    );
                  }

                  final userRole = userSnapshot.data?.get('role');
                  if (userRole == 'admin') {
                    return const AdminDashboard();
                  } else if (userRole == 'user') {
                    return const HomePage();
                  } else {
                    // Handle unexpected roles
                    return Scaffold(
                      body: Center(child: Text('Unknown role')),
                    );
                  }
                } else {
                  // Handle case where user data is not available
                  return Scaffold(
                    body: Center(child: Text('User data not available')),
                  );
                }
              },
            );
          } else {
            // User is not logged in, show login or register page
            return const LoginOrRegisterPage();
          }
        },
      ),
    );
  }
}
