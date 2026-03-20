import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(KentoChatApp());

class KentoChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'КентоЧат',
      theme: ThemeData(
        primarySwatch: Colors.green,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF0B0B0F),
      ),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSavedName();
  }

  _loadSavedName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? saved = prefs.getString('username');
    if (saved != null) _controller.text = saved;
  }

  void _login() async {
    if (_controller.text.trim().isEmpty) {
      setState(() => _error = 'Введи ник');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://kentochat-server-production.up.railway.app/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': _controller.text.trim()}),
      );

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _controller.text.trim());
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatListScreen(
              userName: _controller.text.trim(),
              serverUrl: 'https://kentochat-server-production.up.railway.app',
            ),
          ),
        );
      } else {
        setState(() => _error = 'Ошибка входа');
      }
    } catch (e) {
      setState(() => _error = 'Ошибка: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat, size: 80, color: Colors.green),
              SizedBox(height: 40),
              TextField(
                controller: _controller,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Твой ник',
                  labelStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0xFF2C2C35),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  errorText: _error,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Войти', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatListScreen extends StatefulWidget {
  final String userName;
  final String serverUrl;

  ChatListScreen({required this.userName, required this.serverUrl});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('${widget.serverUrl}/api/users'),
      );
      
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _users.removeWhere((u) => u['username'] == widget.userName);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _openChat(String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          userName: widget.userName,
          otherUser: username,
          serverUrl: widget.serverUrl,
          users: _users.map<String>((u) => u['username'].toString()).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('КентоЧат'),
        backgroundColor: Colors.green,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(Icons.person),
                SizedBox(width: 4),
                Text(widget.userName),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(child: Text('Нет других пользователей'))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (ctx, i) {
                    final user = _users[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(user['username'][0].toUpperCase()),
                      ),
                      title: Text(user['username']),
                      subtitle: Text(
                        user['status'] == 'online' ? '🟢 Онлайн' : '⚫ Офлайн',
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: () => _openChat(user['username']),
                    );
                  },
                ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String userName;
  final String otherUser;
  final String serverUrl;
  final List<String> users;

  ChatScreen({
    required this.userName,
    required this.otherUser,
    required this.serverUrl,
    required this.users,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late IO.Socket socket;
  List<Map<String, dynamic>> _messages = [];
  TextEditingController _controller = TextEditingController();
  ScrollController _scrollController = ScrollController();
  bool _connected = false;
  bool _sending = false;
  
  // Для ответа и пересылки
  Map<String, dynamic>? _replyTo;
  Map<String, dynamic>? _forwardFrom;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _connect();
    _loadHistory();
  }

  void _connect() {
    socket = IO.io(widget.serverUrl, {
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      setState(() => _connected = true);
      socket.emit('login', {'username': widget.userName});
    });

    socket.on('new_message', (data) {
      if (data['from'] == widget.otherUser || data['from'] == widget.userName) {
        setState(() {
          _messages.add(Map<String, dynamic>.from(data));
        });
        _scrollToBottom();
      }
    });

    socket.onConnectError((data) => print('Socket error: $data'));
  }

  void _loadHistory() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.serverUrl}/api/messages/${widget.userName}?with=${widget.otherUser}'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
        _scrollToBottom();
      }
    } catch (e) {
      print('Ошибка загрузки истории: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage({String? text, String? fileId, String? fileType}) {
    final msgText = text ?? _controller.text.trim();
    if (msgText.isEmpty && fileId == null) return;
    
    // Если есть ответ, добавляем цитату
    String finalText = msgText;
    if (_replyTo != null && msgText.isNotEmpty) {
      finalText = '> ${_replyTo!['from']}: ${_getMessagePreview(_replyTo!)}\n\n$msgText';
    }
    
    socket.emit('private_message', {
      'to': widget.otherUser,
      'text': finalText,
      'file_id': fileId,
      'file_type': fileType,
    });
    
    _controller.clear();
    setState(() {
      _replyTo = null;
      _forwardFrom = null;
    });
  }

  String _getMessagePreview(Map<String, dynamic> msg) {
    if (msg['text'] != null && msg['text'].isNotEmpty) {
      return msg['text'].length > 50 ? '${msg['text'].substring(0, 50)}...' : msg['text'];
    } else if (msg['file_type'] == 'image') {
      return '📷 Фото';
    } else if (msg['file_type'] == 'video') {
      return '🎥 Видео';
    }
    return '📎 Файл';
  }

  void _showForwardDialog(Map<String, dynamic> msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Переслать', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1C1C24),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.users.length,
            itemBuilder: (ctx, i) {
              final user = widget.users[i];
              if (user == widget.userName) return SizedBox();
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Text(user[0].toUpperCase()),
                ),
                title: Text(user, style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  socket.emit('private_message', {
                    'to': user,
                    'text': msg['text'] ?? '',
                    'file_id': msg['file'],
                    'file_type': msg['file_type'],
                  });
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (picked != null) {
      await _uploadAndSendFile(picked, 'image');
    }
  }

  Future<void> _pickVideo() async {
    final XFile? picked = await _picker.pickVideo(
      source: ImageSource.gallery,
    );
    
    if (picked != null) {
      await _uploadAndSendFile(picked, 'video');
    }
  }

  Future<void> _uploadAndSendFile(XFile file, String type) async {
    setState(() => _sending = true);
    
    try {
      List<int> bytes = await file.readAsBytes();
      String base64 = base64Encode(bytes);
      
      String mimeType = type == 'image' ? 'image/jpeg' : 'video/mp4';
      if (file.name.endsWith('.png')) mimeType = 'image/png';
      if (file.name.endsWith('.mp4')) mimeType = 'video/mp4';
      
      final response = await http.post(
        Uri.parse('${widget.serverUrl}/api/upload'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'file': 'data:$mimeType;base64,$base64',
          'filename': file.name,
          'mime_type': mimeType,
        }),
      );
      
      if (response.statusCode == 200) {
        var fileData = json.decode(response.body);
        _sendMessage(
          text: '',
          fileId: fileData['file_id'],
          fileType: type,
        );
      }
    } catch (e) {
      print('Ошибка: $e');
    }
    
    setState(() => _sending = false);
  }

  void _showFilePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1C1C24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo, color: Colors.green),
              title: Text('Фото из галереи', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.video_library, color: Colors.green),
              title: Text('Видео из галереи', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFileWidget(Map<String, dynamic> msg) {
    if (msg['file_type'] == 'image') {
      return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.black,
              child: InteractiveViewer(
                child: Image.network(
                  '${widget.serverUrl}/api/file/${msg['file']}',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            '${widget.serverUrl}/api/file/${msg['file']}',
            height: 200,
            width: 250,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (msg['file_type'] == 'video') {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPlayerScreen(
                url: '${widget.serverUrl}/api/file/${msg['file']}',
              ),
            ),
          );
        },
        child: Container(
          height: 150,
          width: 200,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage('${widget.serverUrl}/api/file/${msg['file']}'),
              fit: BoxFit.cover,
              onError: (exception, stackTrace) => null,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black45,
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_filled,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    return Text('📎 Файл');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUser),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Индикатор ответа
          if (_replyTo != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.green.withOpacity(0.2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ответ для ${_replyTo!['from']}',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                        Text(
                          _getMessagePreview(_replyTo!),
                          style: TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: Colors.grey),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, i) {
                final msg = _messages[i];
                final isMe = msg['from'] == widget.userName;
                final time = msg['timestamp'] != null 
                    ? DateFormat('HH:mm').format(DateTime.parse(msg['timestamp']))
                    : '';
                
                return Container(
                  margin: EdgeInsets.only(bottom: 12, left: isMe ? 60 : 0, right: isMe ? 0 : 60),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isMe)
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.green,
                          child: Text(widget.otherUser[0].toUpperCase()),
                        ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Stack(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.green : Color(0xFF2C2C35),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                  bottomLeft: isMe ? Radius.circular(20) : Radius.circular(4),
                                  bottomRight: isMe ? Radius.circular(4) : Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (msg['file'] != null)
                                    _buildFileWidget(msg),
                                  if (msg['text'] != null && msg['text'].isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: msg['file'] != null ? 8 : 0),
                                      child: Text(
                                        msg['text'],
                                        style: TextStyle(
                                          fontStyle: msg['text'].startsWith('>') ? FontStyle.italic : FontStyle.normal,
                                          color: msg['text'].startsWith('>') ? Colors.grey : Colors.white,
                                        ),
                                      ),
                                    ),
                                  SizedBox(height: 4),
                                  Text(
                                    time,
                                    style: TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            // Меню для сообщения (три точки)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: PopupMenuButton(
                                icon: Icon(Icons.more_vert, size: 16, color: Colors.grey),
                                color: Color(0xFF2C2C35),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: Text('Ответить', style: TextStyle(color: Colors.white)),
                                    onTap: () => setState(() => _replyTo = msg),
                                  ),
                                  PopupMenuItem(
                                    child: Text('Переслать', style: TextStyle(color: Colors.white)),
                                    onTap: () => _showForwardDialog(msg),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_sending)
            Container(
              padding: EdgeInsets.all(8),
              color: Color(0xFF1C1C24),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Отправка...'),
                ],
              ),
            ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Color(0xFF1C1C24),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file, color: Colors.green),
                  onPressed: _showFilePicker,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF2C2C35),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _replyTo != null ? 'Написать ответ...' : 'Сообщение...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }
}

// Видео-плеер
class VideoPlayerScreen extends StatefulWidget {
  final String url;
  const VideoPlayerScreen({super.key, required this.url});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {
          _initialized = true;
        });
        _controller.play();
        setState(() => _isPlaying = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Видео'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        color: Colors.black,
        child: Center(
          child: _initialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      if (!_isPlaying)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _controller.play();
                              _isPlaying = true;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : const CircularProgressIndicator(),
        ),
      ),
      floatingActionButton: _initialized
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller.pause();
                    _isPlaying = false;
                  } else {
                    _controller.play();
                    _isPlaying = true;
                  }
                });
              },
              backgroundColor: Colors.green,
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            )
          : null,
    );
  }
}