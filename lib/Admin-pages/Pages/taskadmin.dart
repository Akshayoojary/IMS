import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskAdminPage extends StatefulWidget {
  const TaskAdminPage({Key? key}) : super(key: key);

  @override
  _TaskAdminPageState createState() => _TaskAdminPageState();
}

class _TaskAdminPageState extends State<TaskAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _taskController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _videoLinkController = TextEditingController();
  final _resourcesController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedInternshipId;
  String? _taskId;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _deadlineController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  void _clearForm() {
    _taskController.clear();
    _deadlineController.clear();
    _videoLinkController.clear();
    _resourcesController.clear();
    _taskId = null;
    _selectedDate = null;
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate() && _selectedInternshipId != null) {
      final taskData = {
        'task': _taskController.text,
        'deadline': _deadlineController.text,
        'videoLink': _videoLinkController.text,
        'resources': _resourcesController.text,
        'createdAt': Timestamp.now(),
      };

      if (_taskId == null) {
        // Add new task
        await FirebaseFirestore.instance
            .collection('internships')
            .doc(_selectedInternshipId)
            .collection('tasks')
            .add(taskData);
      } else {
        // Update existing task
        await FirebaseFirestore.instance
            .collection('internships')
            .doc(_selectedInternshipId)
            .collection('tasks')
            .doc(_taskId)
            .update(taskData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_taskId == null ? 'Task added successfully' : 'Task updated successfully')),
      );

      _clearForm();
    }
  }

  void _editTask(DocumentSnapshot task) {
    setState(() {
      _taskController.text = task['task'] ?? '';
      _deadlineController.text = task['deadline'] ?? '';
      _videoLinkController.text = task['videoLink'] ?? '';
      _resourcesController.text = task['resources'] ?? '';
      _taskId = task.id;
      _selectedDate = DateTime.tryParse(task['deadline'] ?? '');
    });
  }

  String _getInternshipDisplayName(DocumentSnapshot doc) {
    // Try to find a suitable field to display for the internship
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
        title: const Text('Task Admin Dashboard'),
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
            if (_selectedInternshipId != null) ...[
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _taskController,
                      decoration: InputDecoration(
                        labelText: 'Task',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter a task' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _deadlineController,
                      decoration: InputDecoration(
                        labelText: 'Deadline',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) => value?.isEmpty ?? true ? 'Please select a deadline' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _videoLinkController,
                      decoration: InputDecoration(
                        labelText: 'Video Link',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Please enter a video link';
                        if (!Uri.tryParse(value!)!.hasAbsolutePath) return 'Please enter a valid URL';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _resourcesController,
                      decoration: InputDecoration(
                        labelText: 'Resources',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter resources' : null,
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
                          onPressed: _saveTask,
                          child: Text(_taskId == null ? 'Add Task' : 'Update Task'),
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
                      .collection('tasks')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No tasks available.'));
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final task = snapshot.data!.docs[index];
                        return Card(
                          child: ListTile(
                            title: Text(task['task'] ?? 'Unnamed Task'),
                            subtitle: Text('Deadline: ${task['deadline'] ?? 'Not set'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editTask(task),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}