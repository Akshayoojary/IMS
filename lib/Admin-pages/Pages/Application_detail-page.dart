import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ApplicationDetailPage extends StatefulWidget {
  final String documentId;
  final String collection;

  const ApplicationDetailPage({
    Key? key,
    required this.documentId,
    required this.collection,
  }) : super(key: key);

  @override
  _ApplicationDetailPageState createState() => _ApplicationDetailPageState();
}

class _ApplicationDetailPageState extends State<ApplicationDetailPage> {
  Future<Map<String, dynamic>?> _fetchApplicationDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(widget.collection)
          .doc(widget.documentId)
          .get();
      return doc.data();
    } catch (e) {
      print('Error fetching application details: $e');
      return null;
    }
  }

  void _openPDFViewer(String pdfUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PDFViewerPage(url: pdfUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchApplicationDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Application Details'),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Application Details'),
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Application Details'),
            ),
            body: const Center(child: Text('No data found')),
          );
        }

        final title = widget.collection == 'job_applications'
            ? data['jobTitle'] ?? 'No title'
            : data['internshipTitle'] ?? 'No title';
        final description = widget.collection == 'job_applications'
            ? data['jobDescription'] ?? 'No description'
            : data['internshipDescription'] ?? 'No description';
        final applicantName = data['userName'] ?? 'Unknown';
        final applicantEmail = data['userEmail'] ?? 'Unknown';
        final resumeUrl = data['resumeUrl'] ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Application Details'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Title: $title',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Description: $description',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Applicant Name: $applicantName',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Applicant Email: $applicantEmail',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (resumeUrl.isNotEmpty)
                  ElevatedButton(
                    onPressed: () => _openPDFViewer(resumeUrl),
                    child: const Text('View Resume'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                if (resumeUrl.isEmpty)
                  const Text(
                    'Resume: Not available',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PDFViewerPage extends StatelessWidget {
  final String url;

  const PDFViewerPage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Viewer'),
      ),
      body: SfPdfViewer.network(url),
    );
  }
}
