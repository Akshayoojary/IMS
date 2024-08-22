import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class TaskDetailedPage extends StatefulWidget {
  final String taskId;
  final String task;
  final String description;
  final DateTime deadline;
  final bool completed;

  const TaskDetailedPage({
    super.key,
    required this.taskId,
    required this.task,
    required this.description,
    required this.deadline,
    required this.completed,
  });

  @override
  _TaskDetailedPageState createState() => _TaskDetailedPageState();
}

class _TaskDetailedPageState extends State<TaskDetailedPage> {
  bool _isSubmitting = false;
  String? _filePath;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected.')),
      );
    }
  }

  Future<void> _submitTask() async {
    if (_filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file to submit.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('tasks').doc(widget.taskId).update({
        'completed': true,
        'submissionDate': Timestamp.now(),
        'submissionFilePath': _filePath,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task submitted successfully.')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting task: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFFC8E6C9), // Light green (Task color)
        elevation: 0,
      ),
      backgroundColor: Color(0xFFC8E6C9), // Light green (Task color)
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black87,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Deadline: ${widget.deadline.toLocal()}'.split(' ')[0],
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (widget.completed)
              const Text(
                'This task has already been completed.',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Pick File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // White to stand out on the green background
                        foregroundColor: Colors.black, // Text color on button
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Add some space between the buttons
                  Expanded(
                    child: _isSubmitting
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _submitTask,
                            child: const Text('Submit Task'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white, // White to stand out on the green background
                              foregroundColor: Colors.black, // Text color on button
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              textStyle: const TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
              if (_filePath != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    'Selected file: ${_filePath!.split('/').last}',
                    style: const TextStyle(color: Colors.black87, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
