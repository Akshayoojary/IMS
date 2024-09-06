import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class ResumeViewerPage extends StatelessWidget {
  final String path;

  const ResumeViewerPage({
    super.key,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Viewer'),
      ),
      body: PDFView(
        filePath: path,
      ),
    );
  }
}
