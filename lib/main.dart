import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'ai_brain.dart';
import 'notification.dart'; // Apna notification page yahan link rakhna

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase init error: $e");
  }
  runApp(const AditiApp());
}

class AditiApp extends StatelessWidget {
  const AditiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edrol AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF131314), 
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFB388FF), 
          secondary: Color(0xFF1E1F20), 
          surface: Color(0xFF1E1F20), 
        ),
        fontFamily: 'Roboto',
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  bool isSubscribed = true;
  int daysLeft = 0;
  
  // 🔴 NAYA: Download State Variables
  bool isLoading = true;
  String downloadStatus = "Initializing AI Engine...";
  double downloadProgress = 0.0;

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AditiBrain _brain = AditiBrain();

  List<Map<String, dynamic>> messages = [];
  
  String currentCharacterName = "Aditi";
  String currentCharacterRole = "Assistant";

  late AnimationController _emojiAnimController;

  @override
  void initState() {
    super.initState();
    _emojiAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initializeApp();
  }

  @override
  void dispose() {
    _emojiAnimController.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _checkOfflineTimer();
    
    // 🔴 NAYA: AI Model Download Initialization with Live Progress
    if (isSubscribed) {
      await _brain.initialize(
        onProgress: (status, progress) {
          if (mounted) {
            setState(() {
              downloadStatus = status;
              if (progress != null) {
                downloadProgress = progress;
              }
            });
          }
        }
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkOfflineTimer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? expiryDateStr = prefs.getString('expiry_date');
    if (expiryDateStr != null) {
      DateTime expiryDate = DateTime.parse(expiryDateStr);
      DateTime now = DateTime.now();
      setState(() {
        if (now.isAfter(expiryDate)) {
          isSubscribed = false;
          daysLeft = 0;
        } else {
          isSubscribed = true;
          daysLeft = expiryDate.difference(now).inDays;
        }
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,      
      maxHeight: 800,
      imageQuality: 60,   
    );
    
    if (image != null) {
      setState(() {
        messages.add({
          "isMe": true,
          "text": "Image Uploaded",
          "isImage": true,
          "localImagePath": image.path,
        });
      });
      _scrollToBottom();
      _msgController.text = _msgController.text + " " + _brain.secretCode; 
    }
  }

  Future<void> _sendMessage() async {
    String text = _msgController.text.trim();
    if (text.isEmpty && !messages.any((m) => m["isMe"] == true && m.containsKey("localImagePath"))) return;

    _emojiAnimController.forward(from: 0.0);

    String? localImagePath;
    if (messages.isNotEmpty && messages.last["isMe"] == true && messages.last.containsKey("localImagePath")) {
      localImagePath = messages.last["localImagePath"];
    }

    if (text.isNotEmpty) {
      setState(() {
        messages.add({"isMe": true, "text": text, "isImage": false});
      });
    }
    _msgController.clear();
    _scrollToBottom();

    setState(() {
       messages.add({"isMe": false, "text": "...", "isImage": false, "isTyping": true});
    });
    _scrollToBottom();

    if (text.toLowerCase().contains("photo") || text.toLowerCase().contains("image") || localImagePath != null) {
      String? imageUrl = await _brain.generateHordeImage(
        text, 
        localImagePath: localImagePath,
        characterName: currentCharacterName
      );
      
      if (mounted) {
        setState(() {
          messages.removeLast();
          if (imageUrl != null) {
            messages.add({"isMe": false, "text": imageUrl, "isImage": true, "isNetworkImage": true});
          } else {
            messages.add({"isMe": false, "text": "Network issue baby, photo nahi aayi 😢", "isImage": false});
          }
        });
        _scrollToBottom();
      }
    } else {
      String aiResponse = await _brain.sendHordeChatMessage(text, role: currentCharacterRole);
      
      if (mounted) {
        setState(() {
          messages.removeLast(); 
          messages.add({"isMe": false, "text": aiResponse, "isImage": false});
        });
        _scrollToBottom();
        _emojiAnimController.forward(from: 0.0);
      }
    }
  }

  void _showCustomCharacterDialog() {
    String name = currentCharacterName;
    String role = currentCharacterRole;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Select AI Model / Role", style: TextStyle(color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: "Character Name", 
                  labelStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => name = val,
                controller: TextEditingController(text: currentCharacterName),
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  labelText: "Role (e.g. GF, Boss, Teacher)", 
                  labelStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary)),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => role = val,
                controller: TextEditingController(text: currentCharacterRole),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                setState(() {
                  currentCharacterName = name.isNotEmpty ? name : "AI";
                  currentCharacterRole = role.isNotEmpty ? role : "Assistant";
                  messages.add({"isMe": false, "text": "Hi, I am $currentCharacterName. Ready to chat! ✨", "isImage": false});
                });
                Navigator.pop(context);
              },
              child: const Text("Update Model", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }

  // 🔴 NAYA: Professional Download & Loading Screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF131314),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing Progress Circle
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15), 
                      blurRadius: 40, 
                      spreadRadius: 10
                    ),
                  ]
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: downloadProgress > 0 ? downloadProgress : null,
                      strokeWidth: 6,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                      strokeCap: StrokeCap.round,
                    ),
                    Center(
                      child: Text(
                        "${(downloadProgress * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Status Text
              Text(
                downloadStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              
              // Warning Text
              const Text(
                "First time setup. Please keep the app open.\nThis model runs 100% offline & private.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔴 NAYA: Agar download chal raha hai, toh premium loading screen dikhao
    if (isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF131314),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white70),
        centerTitle: false,
        titleSpacing: 0,
        title: InkWell(
          onTap: _showCustomCharacterDialog,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentCharacterName, 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildModernDrawer(), 
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var msg = messages[index];
                bool isMe = msg["isMe"] ?? false;

                if (msg["isImage"] == true) {
                  Widget imageWidget;
                  if (msg["isNetworkImage"] == true) {
                     imageWidget = Image.network(msg["text"], fit: BoxFit.cover);
                  } else if (msg["localImagePath"] != null) {
                     imageWidget = Image.file(File(msg["localImagePath"]), fit: BoxFit.cover);
                  } else {
                     imageWidget = const SizedBox();
                  }

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: imageWidget,
                      ),
                    ),
                  );
                }

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? Theme.of(context).colorScheme.primary.withOpacity(0.9) : Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                      ),
                    ),
                    child: msg["isTyping"] == true 
                      ? const SizedBox(height: 20, width: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)))
                      : Text(
                          msg["text"],
                          style: TextStyle(
                            color: isMe ? Colors.black87 : Colors.white, 
                            fontSize: 15.5, 
                            fontWeight: isMe ? FontWeight.w500 : FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                  ),
                );
              },
            ),
          ),
          isSubscribed ? _buildModernChatInput() : _buildLockedInput()
        ],
      ),
    );
  }

  Widget _buildModernDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF131314),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Edrol AI", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text("Premium Active", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 10),
            
            _drawerItem(Icons.chat_bubble_outline_rounded, "New Chat", () {
              setState(() { messages.clear(); });
              Navigator.pop(context);
            }),
            _drawerItem(Icons.tune_rounded, "AI Model / Character", () {
              Navigator.pop(context);
              _showCustomCharacterDialog();
            }),
            _drawerItem(Icons.info_outline_rounded, "App Info", () {
              Navigator.pop(context);
            }),
            
            const Spacer(),
            const Divider(color: Colors.white10, height: 1),
            _drawerItem(Icons.delete_outline_rounded, "Clear History", () {
              setState(() { messages.clear(); });
              Navigator.pop(context);
            }, isDestructive: true),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: isDestructive ? Colors.redAccent : Colors.white70, size: 22),
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.redAccent : Colors.white, fontSize: 15)),
      onTap: onTap,
    );
  }

  Widget _buildModernChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF131314),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1F20),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: IconButton(
                icon: const Icon(Icons.add_photo_alternate_outlined, color: Colors.white70, size: 22),
                onPressed: _pickImage,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1F20),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  controller: _msgController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.black87, size: 20),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedInput() {
    return Container(
      width: double.infinity,
      color: Colors.redAccent.withOpacity(0.1),
      padding: const EdgeInsets.all(15),
      child: const SafeArea(
        child: Text("Premium Plan Expired.", textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
