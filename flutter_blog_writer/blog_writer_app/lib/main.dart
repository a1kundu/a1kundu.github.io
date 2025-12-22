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

  Future<String?> getCurrentCommitSha() async {
    final url =
        'https://api.github.com/repos/$_owner/$_repo/git/refs/heads/${_branch ?? 'main'}';
    final headers = {
      'Authorization': 'token $_token',
      'Accept': 'application/vnd.github.v3+json',
    };
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['object']['sha'];
    }
    return null;
  }

  Future<String?> getTreeSha(String commitSha) async {
    final url =
        'https://api.github.com/repos/$_owner/$_repo/git/commits/$commitSha';
    final headers = {
      'Authorization': 'token $_token',
      'Accept': 'application/vnd.github.v3+json',
    };
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['tree']['sha'];
    }
    return null;
  }

  Future<String?> createBlob(String content) async {
    final url = 'https://api.github.com/repos/$_owner/$_repo/git/blobs';
    final headers = {
      'Authorization': 'token $_token',
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json',
    };
    final body = json.encode({
      'content': base64.encode(utf8.encode(content)),
      'encoding': 'base64',
    });
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['sha'];
    }
    return null;
  }

  Future<String?> createTree(
    String baseTreeSha,
    List<Map<String, dynamic>> tree,
  ) async {
    final url = 'https://api.github.com/repos/$_owner/$_repo/git/trees';
    final headers = {
      'Authorization': 'token $_token',
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json',
    };
    final body = json.encode({'base_tree': baseTreeSha, 'tree': tree});
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['sha'];
    }
    return null;
  }

  Future<String?> createCommit(
    String message,
    String treeSha,
    List<String> parents,
  ) async {
    final url = 'https://api.github.com/repos/$_owner/$_repo/git/commits';
    final headers = {
      'Authorization': 'token $_token',
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json',
    };
    final body = json.encode({
      'message': message,
      'tree': treeSha,
      'parents': parents,
    });
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return data['sha'];
    }
    return null;
  }

  Future<bool> updateRef(String branch, String commitSha) async {
    final url =
        'https://api.github.com/repos/$_owner/$_repo/git/refs/heads/$branch';
    final headers = {
      'Authorization': 'token $_token',
      'Accept': 'application/vnd.github.v3+json',
      'Content-Type': 'application/json',
    };
    final body = json.encode({'sha': commitSha});
    final response = await http.patch(
      Uri.parse(url),
      headers: headers,
      body: body,
    );
    return response.statusCode == 200;
  }

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
      final content = utf8.decode(
        base64.decode(data['content'].replaceAll(RegExp(r'\s'), '')),
      );
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

    print(
      'GitHub Service configured: owner=$_owner, repo=$_repo, branch=$_branch',
    );

    // Fetch current posts
    List<Map<String, dynamic>> posts = await fetchPosts();

    // Add new post
    posts.add({
      'title': title,
      'date': date,
      'filename': filename,
      'deleted': false,
    });

    // Prepare contents
    final postsJson = json.encode(posts);
    final branch = _branch ?? 'main';

    // Get current commit SHA
    final currentCommitSha = await getCurrentCommitSha();
    if (currentCommitSha == null) {
      throw Exception('Failed to get current commit SHA');
    }

    // Get tree SHA
    final treeSha = await getTreeSha(currentCommitSha);
    if (treeSha == null) {
      throw Exception('Failed to get tree SHA');
    }

    // Create blobs
    final postsBlobSha = await createBlob(postsJson);
    if (postsBlobSha == null) {
      throw Exception('Failed to create posts.json blob');
    }

    final contentBlobSha = await createBlob(content);
    if (contentBlobSha == null) {
      throw Exception('Failed to create content blob');
    }

    // Create tree
    final tree = [
      {
        'path': 'src/assets/blogs/posts.json',
        'mode': '100644',
        'type': 'blob',
        'sha': postsBlobSha,
      },
      {
        'path': 'src/assets/blogs/$filename',
        'mode': '100644',
        'type': 'blob',
        'sha': contentBlobSha,
      },
    ];

    final newTreeSha = await createTree(treeSha, tree);
    if (newTreeSha == null) {
      throw Exception('Failed to create tree');
    }

    // Create commit
    final commitSha = await createCommit('Add blog post: $title', newTreeSha, [
      currentCommitSha,
    ]);
    if (commitSha == null) {
      throw Exception('Failed to create commit');
    }

    // Update ref
    final success = await updateRef(branch, commitSha);
    if (!success) {
      throw Exception('Failed to update branch ref');
    }

    print('Successfully committed blog post in single commit');
  }

  Future<String?> fetchPostContent(String filename) async {
    if (!isConfigured()) return null;
    final url =
        'https://api.github.com/repos/$_owner/$_repo/contents/src/assets/blogs/$filename?ref=${_branch ?? 'main'}';
    final headers = {
      'Authorization': 'token $_token',
      'Accept': 'application/vnd.github.v3+json',
    };
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return utf8.decode(
        base64.decode(data['content'].replaceAll(RegExp(r'\s'), '')),
      );
    }
    return null;
  }

  Future<void> updatePost(String filename, String content) async {
    if (!isConfigured()) return;

    print(
      'GitHub Service configured: owner=$_owner, repo=$_repo, branch=$_branch',
    );

    final branch = _branch ?? 'main';

    // Get current commit SHA
    final currentCommitSha = await getCurrentCommitSha();
    if (currentCommitSha == null) {
      throw Exception('Failed to get current commit SHA');
    }

    // Get tree SHA
    final treeSha = await getTreeSha(currentCommitSha);
    if (treeSha == null) {
      throw Exception('Failed to get tree SHA');
    }

    // Create content blob
    final contentBlobSha = await createBlob(content);
    if (contentBlobSha == null) {
      throw Exception('Failed to create content blob');
    }

    // Create tree with updated content
    final tree = [
      {
        'path': 'src/assets/blogs/$filename',
        'mode': '100644',
        'type': 'blob',
        'sha': contentBlobSha,
      },
    ];

    final newTreeSha = await createTree(treeSha, tree);
    if (newTreeSha == null) {
      throw Exception('Failed to create tree');
    }

    // Create commit
    final commitSha = await createCommit(
      'Update blog post: $filename',
      newTreeSha,
      [currentCommitSha],
    );
    if (commitSha == null) {
      throw Exception('Failed to create commit');
    }

    // Update ref
    final success = await updateRef(branch, commitSha);
    if (!success) {
      throw Exception('Failed to update branch ref');
    }

    print('Successfully updated blog post in single commit');
  }
}

class SettingsPage extends StatefulWidget {
  final VoidCallback? onSaved;
  final ThemeMode themeMode;
  final Function(ThemeMode) onThemeChanged;

  const SettingsPage({
    super.key,
    this.onSaved,
    required this.themeMode,
    required this.onThemeChanged,
  });

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
            DropdownButtonFormField<ThemeMode>(
              initialValue: widget.themeMode,
              decoration: const InputDecoration(
                labelText: 'Theme Mode',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  widget.onThemeChanged(value);
                }
              },
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
  bool _isSaving = false;

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
    return '${title.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9\-]'), '').replaceAll(RegExp(r'-+'), '-')}.md';
  }

  Future<void> _savePost() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and content')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final githubService = GitHubService();
      if (githubService.isConfigured()) {
        // Save to GitHub
        final filename = _generateFilename(_titleController.text);
        final date = DateFormat('yyyy-MM-dd').format(_selectedDate);
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post saved locally: $filename')),
        );
        widget.onPostSaved();
        Navigator.of(context).pop();
      }

      // Clear fields
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _selectedDate = DateTime.now();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving post: $e')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isSaving,
      child: AlertDialog(
        title: const Text('Write New Post'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                enabled: !_isSaving,
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
                    onPressed: _isSaving ? null : () => _selectDate(context),
                    child: const Text('Select Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                enabled: !_isSaving,
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
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _savePost,
            child: _isSaving
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Saving...'),
                    ],
                  )
                : const Text('Save Post'),
          ),
        ],
      ),
    );
  }
}

class EditPostDialog extends StatefulWidget {
  final Map<String, dynamic> post;
  final VoidCallback onPostUpdated;

  const EditPostDialog({
    super.key,
    required this.post,
    required this.onPostUpdated,
  });

  @override
  State<EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<EditPostDialog> {
  final _contentController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPostContent();
  }

  Future<void> _loadPostContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final githubService = GitHubService();
      if (githubService.isConfigured()) {
        final content = await githubService.fetchPostContent(
          widget.post['filename'],
        );
        if (content != null) {
          _contentController.text = content;
        }
      } else {
        // Fallback to local file
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/blogs/${widget.post['filename']}');
        if (await file.exists()) {
          _contentController.text = await file.readAsString();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading post content: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePost() async {
    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill in content')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final githubService = GitHubService();
      if (githubService.isConfigured()) {
        // Update on GitHub
        await githubService.updatePost(
          widget.post['filename'],
          _contentController.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post updated on GitHub: ${widget.post['filename']}'),
          ),
        );
        widget.onPostUpdated();
        Navigator.of(context).pop();
      } else {
        // Fallback to local update
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/blogs/${widget.post['filename']}');
        await file.writeAsString(_contentController.text);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Post updated locally: ${widget.post['filename']}'),
          ),
        );
        widget.onPostUpdated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating post: $e')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isSaving,
      child: AlertDialog(
        title: Text('Edit Post: ${widget.post['title']}'),
        content: _isLoading
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Filename: ${widget.post['filename']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _contentController,
                      enabled: !_isSaving && !_isLoading,
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
            onPressed: (_isSaving || _isLoading)
                ? null
                : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: (_isSaving || _isLoading) ? null : _updatePost,
            child: _isSaving
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Updating...'),
                    ],
                  )
                : const Text('Update Post'),
          ),
        ],
      ),
    );
  }
}

class PostsListPage extends StatefulWidget {
  final ThemeMode themeMode;
  final Function(ThemeMode) onThemeChanged;

  const PostsListPage({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

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
      barrierDismissible: false,
      builder: (context) => PostWriterDialog(onPostSaved: _loadPosts),
    );
  }

  void _showEditPostDialog(Map<String, dynamic> post) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          EditPostDialog(post: post, onPostUpdated: _loadPosts),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blog Posts'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadPosts),
          IconButton(
            icon: widget.themeMode == ThemeMode.dark
                ? const Icon(Icons.light_mode)
                : widget.themeMode == ThemeMode.light
                ? const Icon(Icons.dark_mode)
                : const Icon(Icons.brightness_auto),
            onPressed: () {
              final nextMode = widget.themeMode == ThemeMode.light
                  ? ThemeMode.dark
                  : widget.themeMode == ThemeMode.dark
                  ? ThemeMode.system
                  : ThemeMode.light;
              widget.onThemeChanged(nextMode);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    themeMode: widget.themeMode,
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
          ? const Center(child: Text('No posts found'))
          : RefreshIndicator(
              onRefresh: _loadPosts,
              child: ListView.builder(
                itemCount: _posts.length,
                itemBuilder: (context, index) {
                  final post = _posts[index];
                  return GestureDetector(
                    onLongPressStart: (details) {
                      showMenu<String>(
                        context: context,
                        position: RelativeRect.fromLTRB(
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                          details.globalPosition.dx + 1,
                          details.globalPosition.dy + 1,
                        ),
                        items: [
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        ],
                      ).then((value) {
                        if (value == 'edit') {
                          _showEditPostDialog(post);
                        }
                      });
                    },
                    child: ListTile(
                      title: Text(post['title']),
                      subtitle: Text('Date: ${post['date']}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditPostDialog(post);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
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
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
    _loadThemeMode();
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

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex =
        prefs.getInt('theme_mode') ?? 2; // 0: light, 1: dark, 2: system
    setState(() {
      _themeMode = ThemeMode.values[themeIndex];
    });
  }

  void _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    setState(() {
      _themeMode = mode;
    });
  }

  void _onSettingsSaved() {
    _checkConfiguration();
  }

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );

    if (!_isConfigured) {
      return MaterialApp(
        title: 'Blog Writer - Setup',
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: _themeMode,
        home: SettingsPage(
          onSaved: _onSettingsSaved,
          themeMode: _themeMode,
          onThemeChanged: _setThemeMode,
        ),
      );
    }

    return MaterialApp(
      title: 'Blog Writer',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: _themeMode,
      home: PostsListPage(themeMode: _themeMode, onThemeChanged: _setThemeMode),
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
    return '${title.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9\-]'), '').replaceAll(RegExp(r'-+'), '-')}.md';
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
