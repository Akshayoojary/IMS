import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ims/Admin-pages/Pages/Application_detail-page.dart';

class ApplicationsAdminPage extends StatefulWidget {
  const ApplicationsAdminPage({super.key});

  @override
  _ApplicationsAdminPageState createState() => _ApplicationsAdminPageState();
}

class _ApplicationsAdminPageState extends State<ApplicationsAdminPage> {
  late Stream<QuerySnapshot> _jobApplicationsStream;
  late Stream<QuerySnapshot> _internshipApplicationsStream;

  @override
  void initState() {
    super.initState();
    _jobApplicationsStream = FirebaseFirestore.instance.collection('job_applications').snapshots();
    _internshipApplicationsStream = FirebaseFirestore.instance.collection('internship_applications').snapshots();
  }

  Future<void> _refreshApplications() async {
    // Refresh the streams to get the latest data
    setState(() {
      _jobApplicationsStream = FirebaseFirestore.instance.collection('job_applications').snapshots();
      _internshipApplicationsStream = FirebaseFirestore.instance.collection('internship_applications').snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applications Admin'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshApplications,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildSectionTitle('Job Applications'),
              _buildApplicationsList(_jobApplicationsStream, 'job_applications', 'job'),
              _buildSectionTitle('Internship Applications'),
              _buildApplicationsList(_internshipApplicationsStream, 'internship_applications', 'internship'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildApplicationsList(Stream<QuerySnapshot> stream, String collection, String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          print('Error fetching $collection: ${snapshot.error}');
          return Center(child: Text('Error fetching $collection applications.'));
        }

        final applications = snapshot.data?.docs ?? [];

        if (applications.isEmpty) {
          return Center(child: Text('No $collection applications found.'));
        }

        // Adjusted logic to include 'applied' status as pending
        final pendingApplications = applications.where((doc) => 
          (doc.data() as Map<String, dynamic>)['status'] == 'pending' || 
          (doc.data() as Map<String, dynamic>)['status'] == 'applied' || 
          (doc.data() as Map<String, dynamic>)['status'] == null
        ).toList();
        final acceptedApplications = applications.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'accepted').toList();
        final rejectedApplications = applications.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'rejected').toList();

        return Column(
          children: [
            _buildApplicationSection('Pending Applications', pendingApplications, collection, type),
            _buildApplicationSection('Accepted Applications', acceptedApplications, collection, type),
            _buildApplicationSection('Rejected Applications', rejectedApplications, collection, type),
          ],
        );
      },
    );
  }

  Widget _buildApplicationSection(String title, List<QueryDocumentSnapshot> applications, String collection, String type) {
    if (applications.isEmpty) {
      return Container(); // If no applications, return empty container
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final application = applications[index].data() as Map<String, dynamic>?;

            if (application == null) {
              return const Center(child: Text('No data found.'));
            }

            final title = type == 'job' ? application['jobTitle'] ?? 'No title' : application['internshipTitle'] ?? 'No title';
            final description = type == 'job' ? application['jobDescription'] ?? 'No description' : application['internshipDescription'] ?? 'No description';
            final applicantName = application['userName'] ?? 'Unknown';
            final applicantEmail = application['userEmail'] ?? 'Unknown';
            final applicationId = applications[index].id;
            final applicationDate = (application['appliedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final status = application['status'] ?? 'pending';

            return Card(
              child: ListTile(
                title: Text(title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(description),
                    Text('Applicant: $applicantName'),
                    Text('Date: ${applicationDate.toLocal()}'.split(' ')[0]), // Displaying date part only
                    Text('Status: ${status[0].toUpperCase() + status.substring(1)}'), // Capitalize status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ApplicationDetailPage(
                                documentId: applicationId,
                                collection: type == 'job' ? 'job_applications' : 'internship_applications',
                              ),
                            ),
                          ),
                          child: const Text('View Details'),
                        ),
                        if (status == 'pending' || status == 'applied') ...[
                          TextButton(
                            onPressed: () => _updateApplicationStatus(applicationId, collection, 'accepted', applicantEmail),
                            child: const Text('Accept', style: TextStyle(color: Colors.green)),
                          ),
                          TextButton(
                            onPressed: () => _updateApplicationStatus(applicationId, collection, 'rejected', applicantEmail),
                            child: const Text('Reject', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _updateApplicationStatus(String docId, String collection, String status, String applicantEmail) async {
    // Update the application status in Firestore
    await FirebaseFirestore.instance.collection(collection).doc(docId).update({'status': status});

    // Notify user (This can be replaced with a notification system if needed)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Application $status successfully.')),
    );
  }
}
