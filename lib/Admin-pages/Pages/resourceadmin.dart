import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ResourceAdminPage extends StatefulWidget {
  const ResourceAdminPage({Key? key}) : super(key: key);

  @override
  _ResourceAdminPageState createState() => _ResourceAdminPageState();
}

class _ResourceAdminPageState extends State<ResourceAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkController = TextEditingController();
  String? _resourceId;
  String? _selectedInternshipId;

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _linkController.clear();
    _resourceId = null;
  }

  Future<void> _saveResource() async {
    if (_formKey.currentState!.validate() && _selectedInternshipId != null) {
      final resourceData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'link': _linkController.text,
        'createdAt': Timestamp.now(),
      };

      if (_resourceId == null) {
        // Add new resource
        await FirebaseFirestore.instance
            .collection('internships')
            .doc(_selectedInternshipId)
            .collection('resource')
            .add(resourceData);
      } else {
        // Update existing resource
        await FirebaseFirestore.instance
            .collection('internships')
            .doc(_selectedInternshipId)
            .collection('resource')
            .doc(_resourceId)
            .update(resourceData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_resourceId == null ? 'Resource added successfully' : 'Resource updated successfully')),
      );

      _clearForm();
    }
  }

  void _editResource(DocumentSnapshot resource) {
    setState(() {
      _nameController.text = resource['name'] ?? '';
      _descriptionController.text = resource['description'] ?? '';
      _linkController.text = resource['link'] ?? '';
      _resourceId = resource.id;
    });
  }

  String _getInternshipDisplayName(DocumentSnapshot doc) {
    if (doc.data() is Map<String, dynamic>) {
      final data = doc.data() as Map<String, dynamic>;
      return data['name'] ?? data['title'] ?? data['id'] ?? 'Unnamed Internship';
    }
    return 'Unnamed Internship';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Admin Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('internships').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No internships available');
                }
                return DropdownButtonFormField<String>(
                  value: _selectedInternshipId,
                  decoration: InputDecoration(
                    labelText: 'Select Internship',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  items: snapshot.data!.docs.map((doc) {
                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(_getInternshipDisplayName(doc)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedInternshipId = value;
                      _clearForm();
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Resource Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter a resource name' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Resource Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter a resource description' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _linkController,
                    decoration: InputDecoration(
                      labelText: 'Resource Link',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter a resource link';
                      if (!Uri.tryParse(value!)!.hasAbsolutePath) return 'Please enter a valid URL';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: _clearForm,
                        child: const Text('Clear'),
                      ),
                      ElevatedButton(
                        onPressed: _saveResource,
                        child: Text(_resourceId == null ? 'Add Resource' : 'Update Resource'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('internships')
                    .doc(_selectedInternshipId)
                    .collection('resource')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No resources available.'));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final resource = snapshot.data!.docs[index];
                      return Card(
                        child: ListTile(
                          title: Text(resource['name'] ?? 'Unnamed Resource'),
                          subtitle: Text('Description: ${resource['description'] ?? 'No description'}\nLink: ${resource['link'] ?? 'No link'}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editResource(resource),
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
