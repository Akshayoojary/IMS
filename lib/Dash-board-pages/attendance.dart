import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({Key? key}) : super(key: key);

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final DateTime _firstDay = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late DateTime _lastDay;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<DateTime> _attendanceDays = [];

  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    _loadAttendanceData();
  }

  void _loadAttendanceData() async {
    if (_currentUser == null) return;

    try {
      FirebaseFirestore.instance
          .collection('attendance')
          .where('userId', isEqualTo: _currentUser!.uid)
          .snapshots()
          .listen((snapshot) {
        setState(() {
          _attendanceDays = snapshot.docs.where((doc) {
            Timestamp timestamp = doc['date'];
            DateTime date = timestamp.toDate();
            return date.isAfter(_firstDay) && date.isBefore(_lastDay.add(Duration(days: 1)));
          }).map((doc) {
            Timestamp timestamp = doc['date'];
            return timestamp.toDate();
          }).toList();
        });
      }, onError: (error) {
        print("Error loading attendance data: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load attendance data')),
        );
      });
    } catch (e) {
      print("Exception in _loadAttendanceData: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred while loading attendance data')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalDays = DateTime.now().difference(_firstDay).inDays + 1;
    final int attendedDays = _attendanceDays.length;
    final double attendancePercentage = attendedDays / totalDays;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Attendance', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCalendar(),
              SizedBox(height: 20),
              Text(
                'Attendance Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildAttendanceSummary(attendancePercentage, attendedDays, totalDays),
              SizedBox(height: 20),
              Divider(thickness: 1),
              SizedBox(height: 20),
              Text(
                'Attendance Records',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildAttendanceRecords(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: _firstDay,
      lastDay: _lastDay,
      focusedDay: _focusedDay,
      calendarFormat: CalendarFormat.week,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: Colors.blue.shade200,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        weekendTextStyle: TextStyle(color: Colors.red),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
      ),
    );
  }

  Widget _buildAttendanceSummary(double percentage, int attended, int total) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularPercentIndicator(
            radius: 80.0,
            lineWidth: 8.0,
            percent: percentage,
            center: Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            progressColor: Colors.green,
            backgroundColor: Colors.grey.shade200,
          ),
          SizedBox(height: 20),
          Text(
            'You have attended $attended out of $total days.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceRecords() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('userId', isEqualTo: _currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No attendance records.'));
        }

        final attendanceDocs = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: attendanceDocs.length,
          itemBuilder: (context, index) {
            final attendanceData = attendanceDocs[index].data() as Map<String, dynamic>;
            final status = attendanceData['status'] as String;
            final date = (attendanceData['date'] as Timestamp).toDate();

            return ListTile(
              title: Text('Date: ${DateFormat('yyyy-MM-dd').format(date)}'),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status.toLowerCase() == 'present' ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
