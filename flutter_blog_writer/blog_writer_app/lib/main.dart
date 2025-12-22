import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class GitHubService {
  static final GitHubService _instance = GitHubService._internal();
  factory GitHubService() => _instance;
  GitHubService._internal();

  String? _token;
  String? _owner;
  String? _repo;
  String? _branch;

  void configure(String token, String owner, String repo, String branch) {
    _token = token;
    _owner = owner;
    _repo = repo;
    _branch = branch;
  }

  bool isConfigured() => _token != null;

  Future<List<Map<String, dynamic>>> fetchPosts() async {
    if (!isConfigured()) return [];
    final url =
        'https://api.github.com/repos/$_owner/$_repo/contents/src/assets/blogs/posts.json?ref=${_branch ?? 'main'}';
    final headers = {
      'Authorization': 'token $_token',
      'Accept': 'application/vnd.github.v3+json',
    };
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final content = utf8.decode(base64.decode(data['content']));
      return List<Map<String, dynamic>>.from(json.decode(content));
    }
    return [];
  }

  Future<void> savePost(
    String title,
    String date,
    String filename,
    String content,
  ) async {
    if (!isConfigured()) return;

    // Fetch current posts
    List<Map<String, dynamic>> posts = await fetchPosts();

    // Add new post
    posts.add({
      'title': title,
      'date': date,
      'filename': filename,
      'deleted': false,
    });

    // Update or create posts.json
    final postsJson = json.encode(posts);
    final url =
        'https://api.github.com/repos/$_owner/$_repo/contents/src/assets/blogs/posts.json';
    final headers = {
      'Authorization': 'token $_token',
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json',
    };
    final branch = _branch ?? 'main';

    final getResponse = await http.get(
      Uri.parse('$url?ref=$branch'),
      headers: headers,
    );
    if (getResponse.statusCode == 200) {
      final data = json.decode(getResponse.body);
      final sha = data['sha'];
      final putResponse = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          'message': 'Add blog post: $title',
          'content': base64.encode(utf8.encode(postsJson)),
          'branch': branch,
          'sha': sha,
        }),
      );
      if (putResponse.statusCode != 200 && putResponse.statusCode != 201) {
        throw Exception('Failed to update posts.json: ${putResponse.body}');
      }
    } else {
      final postResponse = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode({
          'message': 'Create posts.json and add blog post: $title',
          'content': base64.encode(utf8.encode(postsJson)),
          'branch': branch,
        }),
      );
      if (postResponse.statusCode != 201) {
        throw Exception('Failed to create posts.json: ${postResponse.body}');
      }
    }

    // Create .md file
    final mdUrl =
        'https://api.github.com/repos/$_owner/$_repo/contents/src/assets/blogs/$filename';
    final mdResponse = await http.post(
      Uri.parse(mdUrl),
      headers: headers,
      body: json.encode({
        'message': 'Add blog post content: $title',
        'content': base64.encode(utf8.encode(content)),
        'branch': branch,
      }),
    );
    if (mdResponse.statusCode != 201) {
      throw Exception('Failed to create $filename: ${mdResponse.body}');
    }
  }
}

class SettingsPage extends StatefulWidget {
  final VoidCallback? onSaved;

  const SettingsPage({super.key, this.onSaved});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _tokenController = TextEditingController();
  final _ownerController = TextEditingController();
  final _repoController = TextEditingController();
  final _branchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _tokenController.text = prefs.getString('github_token') ?? '';
    _ownerController.text = prefs.getString('github_owner') ?? '';
    _repoController.text = prefs.getString('github_repo') ?? '';
    _branchController.text = prefs.getString('github_branch') ?? 'main';
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('github_token', _tokenController.text);
    await prefs.setString('github_owner', _ownerController.text);
    await prefs.setString('github_repo', _repoController.text);
    await prefs.setString('github_branch', _branchController.text);

    // Configure GitHub service
    GitHubService().configure(
      _tokenController.text,
      _ownerController.text,
      _repoController.text,
      _branchController.text,
    );

    widget.onSaved?.call();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'GitHub Access Token',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ownerController,
              decoration: const InputDecoration(
                labelText: 'Repository Owner',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _repoController,
              decoration: const InputDecoration(
                labelText: 'Repository Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _branchController,
              decoration: const InputDecoration(
                labelText: 'Branch',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class PostWriterDialog extends StatefulWidget {
  final VoidCallback onPostSaved;

  const PostWriterDialog({super.key, required this.onPostSaved});

  @override
  State<PostWriterDialog> createState() => _PostWriterDialogState();
}

class _PostWriterDialogState extends State<PostWriterDialog> {
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

    final githubService = GitHubService();
    if (githubService.isConfigured()) {
      // Save to GitHub
      final filename = _generateFilename(_titleController.text);
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
      try {
        await githubService.savePost(
          _titleController.text,
          date,
          filename,
          _contentController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post saved to GitHub: $filename')),
        );
        widget.onPostSaved();
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving to GitHub: $e')));
        return;
      }
    } else {
      // Fallback to local save
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
      ).showSnackBar(SnackBar(content: Text('Post saved locally: $filename')));
      widget.onPostSaved();
      Navigator.of(context).pop();
    }

    // Clear fields
    _titleController.clear();
    _contentController.clear();
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Write New Post'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            TextField(
              controller: _contentController,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Content (Markdown)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _savePost, child: const Text('Save Post')),
      ],
    );
  }
}

class PostsListPage extends StatefulWidget {
  const PostsListPage({super.key});

  @override
  State<PostsListPage> createState() => _PostsListPageState();
}

class _PostsListPageState extends State<PostsListPage> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });
    final posts = await GitHubService().fetchPosts();
    setState(() {
      _posts = posts.where((post) => !post['deleted']).toList()
        ..sort(
          (a, b) =>
              DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])),
        );
      _isLoading = false;
    });
  }

  void _showAddPostDialog() {
    showDialog(
      context: context,
      builder: (context) => PostWriterDialog(onPostSaved: _loadPosts),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Posts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
          ? const Center(child: Text('No posts found'))
          : ListView.builder(
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return ListTile(
                  title: Text(post['title']),
                  subtitle: Text('Date: ${post['date']}'),
                  trailing: Text(post['filename']),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPostDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isConfigured = false;

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  Future<void> _checkConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('github_token');
    final owner = prefs.getString('github_owner');
    final repo = prefs.getString('github_repo');
    final branch = prefs.getString('github_branch') ?? 'main';

    if (token != null && owner != null && repo != null) {
      GitHubService().configure(token, owner, repo, branch);
      setState(() {
        _isConfigured = true;
      });
    }
  }

  void _onSettingsSaved() {
    _checkConfiguration();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConfigured) {
      return MaterialApp(
        title: 'Blog Writer - Setup',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: SettingsPage(onSaved: _onSettingsSaved),
      );
    }

    return MaterialApp(
      title: 'Blog Writer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PostsListPage(),
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

    final githubService = GitHubService();
    if (githubService.isConfigured()) {
      // Save to GitHub
      final filename = _generateFilename(_titleController.text);
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
      try {
        await githubService.savePost(
          _titleController.text,
          date,
          filename,
          _contentController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post saved to GitHub: $filename')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving to GitHub: $e')));
        return;
      }
    } else {
      // Fallback to local save
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
      ).showSnackBar(SnackBar(content: Text('Post saved locally: $filename')));
    }

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
