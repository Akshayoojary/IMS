import 'package:flutter/material.dart';
import 'package:ims/Dash-board-pages/Detail-page/webview_page.dart';

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
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title: $title',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              'URL: $url',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'Description:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _openWebView(context),
              child: const Text('Open Document'),
            ),
          ],
        ),
      ),
    );
  }
}
