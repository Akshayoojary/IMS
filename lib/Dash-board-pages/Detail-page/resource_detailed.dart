import 'package:flutter/material.dart';
import 'webview_page.dart';

class ResourceDetailedPage extends StatelessWidget {
  final String name;
  final String description;
  final String link;

  const ResourceDetailedPage({
    super.key,
    required this.name,
    required this.description,
    required this.link,
  });

  void _openInAppWebView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewPage(
          url: link,
          title: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFFE1BEE7), // Light purple matching the card color
        elevation: 0,
      ),
      backgroundColor: Color(0xFFE1BEE7), // Light purple matching the card color
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _openInAppWebView(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue, // Background color of the link box
                  borderRadius: BorderRadius.circular(30), // Rounded corners
                ),
                child: Text(
                  'Open Resource',
                  style: const TextStyle(
                    color: Colors.white, // Text color
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
