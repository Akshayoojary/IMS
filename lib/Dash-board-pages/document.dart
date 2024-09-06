import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ims/Dash-board-pages/Detail-page/document-detail.dart';

class DocumentPage extends StatelessWidget {
  const DocumentPage({Key? key}) : super(key: key);

  Future<String?> _getUserInternshipType() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        print("Fetching enrollment for user: ${user.uid}");
        QuerySnapshot userEnrollmentSnapshot = await FirebaseFirestore.instance
            .collection('enrolled_users')
            .where('userId', isEqualTo: user.uid)
            .get();

        if (userEnrollmentSnapshot.docs.isNotEmpty) {
          DocumentSnapshot userEnrollment = userEnrollmentSnapshot.docs.first;
          Map<String, dynamic> data = userEnrollment.data() as Map<String, dynamic>;
          
          if (data.containsKey('internshipTitle')) {
            print("User enrolled in internship: ${data['internshipTitle']}");
            return data['internshipTitle'];
          } else {
            print("'internshipTitle' field not found in the user enrollment document");
            print("Available fields: ${data.keys.join(', ')}");
            return null;
          }
        } else {
          print("User not enrolled in any internship");
          return null;
        }
      } catch (e) {
        print("Error fetching user enrollment: $e");
        return null;
      }
    } else {
      print("User is not authenticated");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Documents',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrangeAccent,
        elevation: 0,
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!authSnapshot.hasData) {
            return const Center(child: Text('Please log in to access documents.'));
          }

          return FutureBuilder<String?>(
            future: _getUserInternshipType(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('You are not enrolled in any internship.'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Navigate to internship enrollment page
                          print("Navigate to internship enrollment");
                        },
                        child: const Text('Enroll in an Internship'),
                      ),
                    ],
                  ),
                );
              }

              final internshipTitle = snapshot.data!;
              print("Querying documents for internship: $internshipTitle");

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('internships')
                    .doc(internshipTitle) // Assuming internshipTitle is used as document ID
                    .collection('documents') // Access the 'documents' subcollection
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print("Error fetching documents: ${snapshot.error}");
                    return Center(child: Text('Error: Unable to fetch documents. Please try again later.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final documents = snapshot.data?.docs ?? [];
                  print("Fetched ${documents.length} documents for internship: $internshipTitle");
                  if (documents.isEmpty) {
                    return const Center(child: Text('No documents available for your internship.'));
                  }
                  return ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final document = documents[index].data() as Map<String, dynamic>;
                      print("Document ${index + 1}: ${document['title']}");
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Card(
                          color: const Color(0xFFFFF3E0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            title: Text(
                              document['title'] ?? 'No Title',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              document['description'] ?? 'No Description',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            trailing: const Icon(
                              Icons.open_in_new,
                              color: Colors.deepOrangeAccent,
                              size: 20,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DocumentDetailedPage(
                                    title: document['title'] ?? 'No Title',
                                    url: document['url'] ?? '',
                                    description: document['description'] ?? 'No Description',
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
          );
        },
      ),
    );
  }
}
