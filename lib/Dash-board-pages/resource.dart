import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ims/Dash-board-pages/Detail-page/resource_detailed.dart';

class ResourcePage extends StatelessWidget {
  const ResourcePage({super.key});

  Future<String?> _getUserInternshipType() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        QuerySnapshot userEnrollmentSnapshot = await FirebaseFirestore.instance
            .collection('enrolled_users')
            .where('userId', isEqualTo: user.uid)
            .get();

        if (userEnrollmentSnapshot.docs.isNotEmpty) {
          DocumentSnapshot userEnrollment = userEnrollmentSnapshot.docs.first;
          Map<String, dynamic> data = userEnrollment.data() as Map<String, dynamic>;
          return data['internshipTitle'];
        }
      } catch (e) {
        print("Error fetching user enrollment: $e");
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resources', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: FutureBuilder<String?>(
        future: _getUserInternshipType(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text('No resources available for your internship.'));
          }

          final internshipTitle = snapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('internships')
                .doc(internshipTitle)
                .collection('resource')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final resources = snapshot.data?.docs ?? [];
              if (resources.isEmpty) {
                return const Center(child: Text('No resources available.'));
              }
              return ListView.builder(
                itemCount: resources.length,
                itemBuilder: (context, index) {
                  final resource = resources[index].data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      color: const Color(0xFFE1BEE7),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(resource['name'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        subtitle: Text(resource['description']),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.deepPurple, size: 18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ResourceDetailedPage(
                                name: resource['name'],
                                description: resource['description'],
                                link: resource['link'],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
