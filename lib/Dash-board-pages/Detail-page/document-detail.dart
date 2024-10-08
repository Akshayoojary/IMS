import 'package:flutter/material.dart';
import 'webview_page.dart';

class DocumentDetailedPage extends StatelessWidget {
  final String title;
  final String url;
  final String description;

  const DocumentDetailedPage({
    super.key,
    required this.title,
    required this.url,
    required this.description,
  });

  void _openWebView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewPage(
          url: url,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFFFF3E0), // Light orange matching the card color
        elevation: 0,
      ),
      backgroundColor: Color(0xFFFFF3E0), // Light orange matching the card color
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title: $title',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrangeAccent,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'URL: $url',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              'Description:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _openWebView(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.deepOrangeAccent, // Button color matching the theme
                  borderRadius: BorderRadius.circular(30), // Rounded corners
                ),
                child: const Text(
                  'Open Document',
                  style: TextStyle(
                    color: Colors.white, // White text for contrast
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
