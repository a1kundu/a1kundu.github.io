import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blog Writer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const BlogWriterPage(),
    );
  }
}

class BlogWriterPage extends StatefulWidget {
  const BlogWriterPage({super.key});

  @override
  State<BlogWriterPage> createState() => _BlogWriterPageState();
}

class _BlogWriterPageState extends State<BlogWriterPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _generateFilename(String title) {
    return title
            .toLowerCase()
            .replaceAll(' ', '-')
            .replaceAll(RegExp(r'[^a-z0-9\-]'), '')
            .replaceAll(RegExp(r'-+'), '-') +
        '.md';
  }

  Future<void> _savePost() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and content')),
      );
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final blogDir = Directory('${directory.path}/blogs');
    await blogDir.create(recursive: true);

    final filename = _generateFilename(_titleController.text);
    final file = File('${blogDir.path}/$filename');
    await file.writeAsString(_contentController.text);

    // Load existing posts.json or create new
    final postsFile = File('${blogDir.path}/posts.json');
    List<Map<String, dynamic>> posts = [];
    if (await postsFile.exists()) {
      final content = await postsFile.readAsString();
      posts = List<Map<String, dynamic>>.from(json.decode(content));
    }

    final newPost = {
      'title': _titleController.text,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'filename': filename,
      'deleted': false,
    };
    posts.add(newPost);

    await postsFile.writeAsString(json.encode(posts));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Post saved: $filename')));

    // Clear fields
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blog Post Writer')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: const Text('Select Date'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: 'Content (Markdown)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _savePost,
              child: const Text('Save Post'),
            ),
          ],
        ),
      ),
    );
  }
}
