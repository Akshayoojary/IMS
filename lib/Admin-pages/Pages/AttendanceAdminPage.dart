import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceAdminPage extends StatefulWidget {
  @override
  _AttendanceAdminPageState createState() => _AttendanceAdminPageState();
}

class _AttendanceAdminPageState extends State<AttendanceAdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedInternshipTitle = 'Domain Connect (GoDaddy)'; // Default or selected internship title

  // Use nullable types to avoid LateInitializationError
  Stream<QuerySnapshot>? _userStream;
  Stream<QuerySnapshot>? _attendanceStream;

  @override
  void initState() {
    super.initState();
    _updateStreams();
  }

  void _updateStreams() {
    setState(() {
      _userStream = _firestore
          .collection('enrolled_users')
          .where('internshipTitle', isEqualTo: _selectedInternshipTitle)
          .snapshots();

      _attendanceStream = _firestore
          .collection('attendance')
          .where('internshipTitle', isEqualTo: _selectedInternshipTitle)
          .snapshots();
    });
  }

  Future<void> _markAttendance(String userId, String status) async {
    try {
      final attendanceData = {
        'userId': userId,
        'status': status,
        'internshipTitle': _selectedInternshipTitle,
        'timestamp': Timestamp.now(),
      };

      final existingAttendanceQuery = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: userId)
          .where('internshipTitle', isEqualTo: _selectedInternshipTitle)
          .get();

      if (existingAttendanceQuery.docs.isNotEmpty) {
        // Update existing attendance record
        final existingDocId = existingAttendanceQuery.docs.first.id;
        await _firestore.collection('attendance').doc(existingDocId).update(attendanceData);
      } else {
        // Add new attendance record
        await _firestore.collection('attendance').add(attendanceData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance marked as $status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking attendance: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _updateStreams();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedInternshipTitle,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedInternshipTitle = newValue!;
                  _updateStreams();
                });
              },
              items: <String>[
                'Domain Connect (GoDaddy)',
                'Hosting',
                // Add other internship titles here
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _userStream,
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (userSnapshot.hasError) {
                  return Center(child: Text('Error: ${userSnapshot.error}'));
                }

                final userDocs = userSnapshot.data?.docs ?? [];
                if (userDocs.isEmpty) {
                  return Center(child: Text('No users enrolled.'));
                }

                return ListView.builder(
                  itemCount: userDocs.length,
                  itemBuilder: (context, index) {
                    final userData = userDocs[index].data() as Map<String, dynamic>;
                    final userId = userData['userId'];
                    final userName = userData['name'] ?? userData['userName'] ?? 'Unknown';

                    // Debugging output
                    print('User Data: $userData');

                    return ListTile(
                      title: Text(userName),
                      trailing: PopupMenuButton<String>(
                        onSelected: (status) {
                          _markAttendance(userId, status);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'present',
                            child: Text('Mark as Present'),
                          ),
                          PopupMenuItem(
                            value: 'absent',
                            child: Text('Mark as Absent'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
