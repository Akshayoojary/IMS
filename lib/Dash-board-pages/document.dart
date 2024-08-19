import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ims/Dash-board-pages/Detail-page/document-detail.dart';


class DocumentPage extends StatelessWidget {
  const DocumentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('documents').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final documents = snapshot.data?.docs ?? [];
          if (documents.isEmpty) {
            return const Center(child: Text('No documents available.'));
          }
          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DocumentDetailedPage(
                        title: document['title'],
                        url: document['url'],
                        description: document['description'],
                      ),
                    ),
                  );
                },
                child: ListTile(
                  title: Text(document['title']),
                  subtitle: Text(document['url']),
                  trailing: const Icon(Icons.open_in_new),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
