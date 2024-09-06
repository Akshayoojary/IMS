import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceAdminPage extends StatefulWidget {
  @override
  _AttendanceAdminPageState createState() => _AttendanceAdminPageState();
}

class _AttendanceAdminPageState extends State<AttendanceAdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedInternshipTitle = ''; // Default or selected internship title
  List<String> _internshipTitles = [];
  DateTime? _selectedDate; // Added date selection

  Stream<QuerySnapshot>? _userStream;
  Stream<QuerySnapshot>? _attendanceStream;

  @override
  void initState() {
    super.initState();
    _loadInternshipTitles();
  }

  void _loadInternshipTitles() async {
    final internshipQuery = await _firestore.collection('internships').get();
    final titles = internshipQuery.docs.map((doc) => doc['title'] as String).toList();

    setState(() {
      _internshipTitles = titles;
      if (_internshipTitles.isNotEmpty) {
        _selectedInternshipTitle = _internshipTitles.first; // Set default selection
        _updateStreams();
      }
    });
  }

  void _updateStreams() {
    if (_selectedInternshipTitle.isNotEmpty) {
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
  }

  Future<void> _markAttendance(String userId, String status) async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date.')),
      );
      return;
    }

    try {
      final attendanceData = {
        'userId': userId,
        'status': status,
        'internshipTitle': _selectedInternshipTitle,
        'date': Timestamp.fromDate(_selectedDate!), // Add the selected date to the record
        'timestamp': Timestamp.now(),
      };

      final existingAttendanceQuery = await _firestore
          .collection('attendance')
          .where('userId', isEqualTo: userId)
          .where('internshipTitle', isEqualTo: _selectedInternshipTitle)
          .where('date', isEqualTo: Timestamp.fromDate(_selectedDate!))
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

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _updateStreams(); // Update streams to reflect the new date
      });
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
              _loadInternshipTitles(); // Refresh the list of internships
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown for selecting internship
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButton<String>(
                value: _selectedInternshipTitle.isNotEmpty ? _selectedInternshipTitle : null,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedInternshipTitle = newValue!;
                    _updateStreams();
                  });
                },
                hint: Text('Select Internship'),
                items: _internshipTitles.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // Date picker button
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blueGrey[50],
                ),
                child: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : 'Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(height: 16),
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

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 2,
                        child: ListTile(
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
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
