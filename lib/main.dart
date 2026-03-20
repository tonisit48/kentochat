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
        scaffoldBackgroundColor: Colors.transparent,
        fontFamily: 'System',
      ),
      home: LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
            Color(0xFF0F0F1F),
          ],
        ),
      ),
      child: child,
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _isRegistering = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadSavedName();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  Future<void> _loadSavedName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? saved = prefs.getString('username');
    if (saved != null) _usernameController.text = saved;
  }

  Future<void> _login() async {
    if (_usernameController.text.trim().isEmpty) {
      setState(() => _error = 'Введи ник');
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Введи пароль');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://kentochat-server-production.up.railway.app/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _usernameController.text.trim());
        await prefs.setString('password', _passwordController.text);
        
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ChatListScreen(
                userName: _usernameController.text.trim(),
                serverUrl: 'https://kentochat-server-production.up.railway.app',
              ),
              transitionsBuilder: (_, animation, __, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      } else {
        var data = json.decode(response.body);
        if (response.statusCode == 404) {
          setState(() {
            _error = 'Пользователь не найден. Зарегистрируйтесь.';
            _isRegistering = true;
          });
        } else {
          setState(() => _error = data['error'] ?? 'Ошибка входа');
        }
      }
    } catch (e) {
      setState(() => _error = 'Ошибка: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _register() async {
    if (_usernameController.text.trim().isEmpty) {
      setState(() => _error = 'Введи ник');
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Введи пароль');
      return;
    }
    if (_passwordController.text.length < 4) {
      setState(() => _error = 'Пароль должен быть не менее 4 символов');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://kentochat-server-production.up.railway.app/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        await _login();
      } else {
        var data = json.decode(response.body);
        setState(() => _error = data['error'] ?? 'Ошибка регистрации');
      }
    } catch (e) {
      setState(() => _error = 'Ошибка: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade700],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(Icons.chat_bubble_outline, size: 60, color: Colors.white),
                    ),
                    SizedBox(height: 40),
                    Text(
                      'КентоЧат',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: [Colors.green.shade400, Colors.green.shade300],
                          ).createShader(Rect.fromLTWH(0, 0, 200, 70)),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Чисто для своих',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    ),
                    SizedBox(height: 50),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _usernameController,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Твой ник',
                              labelStyle: TextStyle(color: Colors.grey.shade400),
                              hintText: 'Например: Димон',
                              hintStyle: TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Color(0xFF2C2C35),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.green, width: 2),
                              ),
                              prefixIcon: Icon(Icons.person, color: Colors.green),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: TextStyle(color: Colors.white, fontSize: 16),
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              labelStyle: TextStyle(color: Colors.grey.shade400),
                              hintText: 'Минимум 4 символа',
                              hintStyle: TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Color(0xFF2C2C35),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.green, width: 2),
                              ),
                              prefixIcon: Icon(Icons.lock, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ],
                    SizedBox(height: 30),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 5,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Войти', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isRegistering = !_isRegistering;
                          _error = null;
                        });
                      },
                      child: Text(
                        _isRegistering ? 'Уже есть аккаунт? Войти' : 'Нет аккаунта? Зарегистрироваться',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                    if (_isRegistering)
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade800,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('Зарегистрироваться', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
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

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();
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

  String _getAvatarColor(String name) {
    final colors = [
      '#FF5252', '#FF4081', '#E040FB', '#7C4DFF',
      '#536DFE', '#448AFF', '#40C4FF', '#18FFFF',
      '#64DD17', '#69F0AE', '#FFD740', '#FF6E40',
    ];
    int index = name.hashCode.abs() % colors.length;
    return colors[index];
  }

  void _openChat(String username) {
    List<String> userNames = _users.map<String>((u) => u['username'].toString()).toList();
    
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ChatScreen(
          userName: widget.userName,
          otherUser: username,
          serverUrl: widget.serverUrl,
          users: userNames,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: Offset(1, 0), end: Offset.zero).animate(animation),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('КентоЧат', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade700, Colors.green.shade900],
              ),
            ),
          ),
          actions: [
            Container(
              margin: EdgeInsets.only(right: 16),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.person, size: 18),
                  SizedBox(width: 4),
                  Text(widget.userName, style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        body: _loading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              )
            : _users.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Нет других пользователей', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (ctx, i) {
                      final user = _users[i];
                      return FadeTransition(
                        opacity: _animationController,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(-0.3, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(i * 0.1, 1.0, curve: Curves.easeOut),
                          )),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Color(0xFF2C2C35).withOpacity(0.8),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(int.parse(_getAvatarColor(user['username']).substring(1, 7), radix: 16) + 0xFF000000),
                                      Color(int.parse(_getAvatarColor(user['username']).substring(1, 7), radix: 16) + 0xFF000000).withOpacity(0.7),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    user['username'][0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                user['username'],
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: user['status'] == 'online' ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    user['status'] == 'online' ? 'Онлайн' : 'Офлайн',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: Icon(Icons.chevron_right, color: Colors.grey),
                              onTap: () => _openChat(user['username']),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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
  bool _isTyping = false;
  List<String> _typingUsers = [];
  
  Map<String, dynamic>? _replyTo;
  
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

    socket.on('user_typing', (data) {
      if (data['user'] == widget.otherUser) {
        setState(() {
          if (!_typingUsers.contains(data['user'])) {
            _typingUsers.add(data['user']);
          }
        });
        Future.delayed(Duration(seconds: 2), () {
          setState(() {
            _typingUsers.remove(data['user']);
          });
        });
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
      _isTyping = false;
    });
  }

  void _onTyping() {
    if (!_isTyping && _controller.text.isNotEmpty) {
      _isTyping = true;
      socket.emit('typing', {'user': widget.userName});
      Future.delayed(Duration(seconds: 2), () {
        _isTyping = false;
      });
    }
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

void _showMessageOptions(Map<String, dynamic> msg) {
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
            leading: Icon(Icons.reply, color: Colors.green),
            title: Text('Ответить', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              setState(() => _replyTo = msg);
            },
          ),
          ListTile(
            leading: Icon(Icons.forward, color: Colors.green),
            title: Text('Переслать', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _showForwardDialog(msg);
            },
          ),
          SizedBox(height: 20),
        ],
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
            child: Center(
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

  String _getAvatarColor(String name) {
    final colors = [
      '#FF5252', '#FF4081', '#E040FB', '#7C4DFF',
      '#536DFE', '#448AFF', '#40C4FF', '#18FFFF',
      '#64DD17', '#69F0AE', '#FFD740', '#FF6E40',
    ];
    int index = name.hashCode.abs() % colors.length;
    return colors[index];
  }

Widget _buildMessage(Map<String, dynamic> msg, bool isMe) {
  final time = msg['timestamp'] != null 
      ? DateFormat('HH:mm').format(DateTime.parse(msg['timestamp']))
      : '';
  
  return GestureDetector(
    onLongPress: () {
      _showMessageOptions(msg);
    },
    child: AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Container(
              width: 36,
              height: 36,
              margin: EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(int.parse(_getAvatarColor(widget.otherUser).substring(1, 7), radix: 16) + 0xFF000000),
                    Color(int.parse(_getAvatarColor(widget.otherUser).substring(1, 7), radix: 16) + 0xFF000000).withOpacity(0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.otherUser[0].toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [Color(0xFF2C2C35), Color(0xFF1C1C24)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: isMe ? Radius.circular(20) : Radius.circular(4),
                  bottomRight: isMe ? Radius.circular(4) : Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
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
          ),
        ],
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.otherUser, style: TextStyle(fontWeight: FontWeight.bold)),
              if (_typingUsers.isNotEmpty)
                Text(
                  'печатает...',
                  style: TextStyle(fontSize: 12, color: Colors.greenAccent),
                ),
            ],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.green.shade700, Colors.green.shade900],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            if (_replyTo != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
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
                  return _buildMessage(msg, isMe);
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
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.green)),
                    ),
                    SizedBox(width: 8),
                    Text('Отправка...', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Color(0xFF1C1C24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
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
                        onChanged: (text) => _onTyping(),
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
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade700],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: Colors.white),
                        onPressed: () => _sendMessage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }
}

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