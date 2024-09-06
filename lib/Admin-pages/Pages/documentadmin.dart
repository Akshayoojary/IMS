import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Admin Dashboard',
      home: DocumentAdminPage(),
    );
  }
}

class DocumentAdminPage extends StatefulWidget {
  const DocumentAdminPage({super.key});

  @override
  _DocumentAdminPageState createState() => _DocumentAdminPageState();
}

class _DocumentAdminPageState extends State<DocumentAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  String? _fileName;
  String? _documentId; // To track the document being edited
  String? _selectedInternshipId; // To track the selected internship

  Future<List<QueryDocumentSnapshot>> _fetchInternships() async {
    final snapshot = await FirebaseFirestore.instance.collection('internships').get();
    return snapshot.docs;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null) {
      setState(() {
        _fileName = result.files.first.name;
      });
    }
  }

  Future<void> _saveDocument() async {
    if (_formKey.currentState!.validate()) {
      if (_documentId == null) {
        // Add new document
        await FirebaseFirestore.instance
            .collection('internships')
            .doc(_selectedInternshipId)
            .collection('documents')
            .add({
          'title': _titleController.text,
          'url': _urlController.text,
          'fileName': _fileName,
          'description': '', // Add any default or empty value for description
        });
      } else {
        // Update existing document
        await FirebaseFirestore.instance
            .collection('internships')
            .doc(_selectedInternshipId)
            .collection('documents')
            .doc(_documentId)
            .update({
          'title': _titleController.text,
          'url': _urlController.text,
          'fileName': _fileName,
          'description': '', // Add any default or empty value for description
        });
      }

      // Reset form and state
      _titleController.clear();
      _urlController.clear();
      setState(() {
        _fileName = null;
        _documentId = null;
        _selectedInternshipId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document Uploaded Successfully')),
      );
    }
  }

  void _editDocument(QueryDocumentSnapshot document) {
    setState(() {
      _titleController.text = document['title'];
      _urlController.text = document['url'];
      _fileName = document['fileName'];
      _documentId = document.id;
      _selectedInternshipId = document.reference.parent.parent?.id; // Get internship ID from parent
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Admin Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _fetchInternships(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No internships available.'));
            }

            final internships = snapshot.data!;
            return Column(
              children: [
                Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Document Title',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey[200],
                            prefixIcon: const Icon(Icons.title),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            labelText: 'Document URL',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey[200],
                            prefixIcon: const Icon(Icons.link),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a URL';
                            } else {
                              final uri = Uri.tryParse(value);
                              if (uri == null || !uri.hasAbsolutePath) {
                                return 'Please enter a valid URL';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedInternshipId,
                          hint: const Text('Select Internship'),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                            prefixIcon: const Icon(Icons.school),
                          ),
                          items: internships.map((internship) {
                            final data = internship.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: internship.id,
                              child: Text(data['name'] ?? 'No Name'), // Handle missing field
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedInternshipId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select an internship';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.attach_file),
                          label: Text(_fileName ?? 'Upload Document (PDF, JPG, PNG)'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _saveDocument,
                          child: const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _selectedInternshipId == null
                        ? null
                        : FirebaseFirestore.instance
                            .collection('internships')
                            .doc(_selectedInternshipId)
                            .collection('documents')
                            .snapshots(),
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
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(document['title']),
                              subtitle: Text(document['url']),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editDocument(document),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
