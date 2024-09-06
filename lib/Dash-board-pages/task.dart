import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ims/Dash-board-pages/Detail-page/task_detailed_page.dart';

class TaskPage extends StatelessWidget {
  const TaskPage({super.key});

  Future<String?> _getUserInternshipTitle() async {
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
        title: const Text('Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: FutureBuilder<String?>(
        future: _getUserInternshipTitle(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No tasks available for your internship.'));
          }

          final internshipTitle = snapshot.data!;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('internships')
                .doc(internshipTitle)
                .collection('tasks')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final tasks = snapshot.data?.docs ?? [];
              if (tasks.isEmpty) {
                return const Center(child: Text('No tasks available.'));
              }
              return ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index].data() as Map<String, dynamic>;

                  // Check if deadline is a Timestamp or a String
                  DateTime? deadline;
                  if (task['deadline'] is Timestamp) {
                    deadline = (task['deadline'] as Timestamp).toDate();
                  } else if (task['deadline'] is String) {
                    try {
                      deadline = DateTime.parse(task['deadline'] as String);
                    } catch (e) {
                      print("Error parsing deadline: $e");
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      color: const Color(0xFFC8E6C9),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(task['task'] ?? 'No Task Name', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        subtitle: Text(
                          'Deadline: ${deadline != null ? deadline.toLocal().toString().split(' ')[0] : 'Unknown'}'
                        ),
                        trailing: Icon(
                          task['completed'] == true ? Icons.check_circle : Icons.circle,
                          color: task['completed'] == true ? Colors.green : Colors.grey,
                          size: 28,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailedPage(
                                taskId: task['id'] ?? 'Unknown',
                                task: task['task'] ?? 'No Task Name',
                                description: task['description'] ?? 'No Description',
                                deadline: deadline ?? DateTime.now(),
                                completed: task['completed'] ?? false,
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
