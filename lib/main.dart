import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'ai_brain.dart';
import 'notification.dart'; 

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
        // 🔴 ROMANTIC THEME: Deep Dark Rose Background
        scaffoldBackgroundColor: const Color(0xFF170F11), 
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF4081), // Hot Pink/Rose Accent
          secondary: Color(0xFF2D1B24), // Soft Dark Pink-Grey for bubbles
          surface: Color(0xFF1E1418), // Slightly lighter background for cards
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

class _ChatScreenState extends State<ChatScreen> {
  bool isSubscribed = true;
  int daysLeft = 0;
  
  bool isLoading = true;
  String downloadStatus = "Connecting to Aditi... 💖";
  double downloadProgress = 0.0;

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AditiBrain _brain = AditiBrain();

  List<Map<String, dynamic>> messages = [];
  
  String currentCharacterName = "Aditi";
  String currentCharacterRole = "Companion"; // Default role slightly romantic

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _checkOfflineTimer();
    
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
          "text": "Image Uploaded 📸",
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Your Companion ✨", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: "Character Name", 
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
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
                  labelText: "Role (e.g. Girlfriend, Wifey)", 
                  labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
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
                foregroundColor: Colors.white, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                setState(() {
                  currentCharacterName = name.isNotEmpty ? name : "Aditi";
                  currentCharacterRole = role.isNotEmpty ? role : "Companion";
                  messages.add({"isMe": false, "text": "Hi baby, I am $currentCharacterName. Let's talk... 💕", "isImage": false});
                });
                Navigator.pop(context);
              },
              child: const Text("Update", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2), 
                      blurRadius: 50, 
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
                    const Center(
                      child: Icon(Icons.favorite, color: Colors.white, size: 40),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              Text(
                downloadStatus,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              
              const Text(
                "Connecting to secure premium server.\nPlease wait a moment.",
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
    if (isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  child: Icon(Icons.favorite, size: 16, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 10),
                Text(
                  currentCharacterName, 
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Colors.white),
                ),
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
                        borderRadius: BorderRadius.circular(20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      // User message uses Hot Pink, AI uses Soft Dark Rose-Grey
                      color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(24),
                        topRight: const Radius.circular(24),
                        bottomLeft: isMe ? const Radius.circular(24) : const Radius.circular(6),
                        bottomRight: isMe ? const Radius.circular(6) : const Radius.circular(24),
                      ),
                      boxShadow: [
                        if (isMe) BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
                      ]
                    ),
                    // 🔴 FIX: YAHAN SE CIRCLE HATA DIYA HAI AUR PYARA SA TEXT LAGA DIYA HAI
                    child: msg["isTyping"] == true 
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.favorite, size: 14, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text("Typing... 💕", style: TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),
                          ],
                        )
                      : Text(
                          msg["text"],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.white.withOpacity(0.9), 
                            fontSize: 15.5, 
                            fontWeight: FontWeight.w400,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Edrol AI", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text("Premium Active 💖", style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
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
            _drawerItem(Icons.favorite_border_rounded, "AI Model / Character", () {
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
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white10),
                ),
                child: TextField(
                  controller: _msgController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Message Aditi...",
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
                boxShadow: [
                  BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))
                ]
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      padding: const EdgeInsets.all(15),
      child: const SafeArea(
        child: Text("Premium Plan Expired.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
