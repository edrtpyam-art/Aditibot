import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'ai_brain.dart';

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
        scaffoldBackgroundColor: const Color(0xFF120E1A), // Deep Purple/Dark Background
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD81B60), // Pink Accent
          secondary: Color(0xFF8E24AA), // Purple Accent
          surface: Color(0xFF1E1826),
        ),
        fontFamily: 'Roboto', // Professional Font
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
  bool isLoading = true;

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AditiBrain _brain = AditiBrain();

  // Chat list
  List<Map<String, dynamic>> messages = [];
  
  // Custom Character State
  String currentCharacterName = "AI";
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
    setState(() {
      isLoading = false;
      // Start with empty screen, no fake history
    });
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
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // 🔴 Image Picker Logic
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        messages.add({
          "isMe": true,
          "text": "Uploaded Image",
          "isImage": true,
          "localImagePath": image.path,
        });
      });
      _scrollToBottom();
      // Pass path to text controller for user reference (optional)
      _msgController.text += " [Image Uploaded] ";
    }
  }

  Future<void> _sendMessage() async {
    String text = _msgController.text.trim();
    if (text.isEmpty && !messages.any((m) => m["isMe"] == true && m.containsKey("localImagePath"))) return;

    _emojiAnimController.forward(from: 0.0); // Trigger emoji animation

    String? localImagePath;
    // Check if the last user message was an image to send along with text
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

    // 🔴 Logic to check for image generation or chat
    if (text.toLowerCase().contains("photo") || text.toLowerCase().contains("image") || localImagePath != null) {
      String? imageUrl = await _brain.generateHordeImage(
        text, 
        localImagePath: localImagePath,
        characterName: currentCharacterName
      );
      
      if (mounted) {
        setState(() {
          messages.removeLast(); // Remove typing indicator
          if (imageUrl != null) {
            messages.add({"isMe": false, "text": imageUrl, "isImage": true, "isNetworkImage": true});
          } else {
            messages.add({"isMe": false, "text": "Error generating image.", "isImage": false});
          }
        });
        _scrollToBottom();
      }
    } else {
      // Normal Chat
      String aiResponse = await _brain.sendHordeChatMessage(text, role: currentCharacterRole);
      
      if (mounted) {
        setState(() {
          messages.removeLast(); // Remove typing indicator
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
          title: const Text("Custom Character", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Name (e.g. Rahul, Priya)", labelStyle: TextStyle(color: Colors.white54)),
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => name = val,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Role/Personality (e.g. Strict boss, Best friend)", labelStyle: TextStyle(color: Colors.white54)),
                style: const TextStyle(color: Colors.white),
                onChanged: (val) => role = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: () {
                setState(() {
                  currentCharacterName = name.isNotEmpty ? name : "AI";
                  currentCharacterRole = role.isNotEmpty ? role : "Assistant";
                  messages.add({"isMe": false, "text": "Hi, I am $currentCharacterName. I'm here as your $currentCharacterRole.", "isImage": false});
                });
                Navigator.pop(context);
              },
              child: const Text("Set"),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD81B60))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        // Clean look: No top title, or very minimal
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text("Premium Member", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(isSubscribed ? "Plan Active: $daysLeft days left" : "Plan Expired", style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add, color: Colors.white),
              title: const Text("New Chat", style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() { messages.clear(); });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.white),
              title: const Text("Custom Character", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showCustomCharacterDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text("App Model Info", style: TextStyle(color: Colors.white)),
              onTap: () {
                // Show Model Info
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Powered by AI Horde Uncensored Models")));
                Navigator.pop(context);
              },
            ),
             ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text("Manual Edit/Chat", style: TextStyle(color: Colors.white)),
              onTap: () {
                // Placeholder for manual editing
                Navigator.pop(context);
              },
            ),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              title: const Text("Clear History", style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                setState(() { messages.clear(); });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var msg = messages[index];
                bool isMe = msg["isMe"] ?? false;

                // Image Rendering
                if (msg["isImage"] == true) {
                  Widget imageWidget;
                  if (msg["isNetworkImage"] == true) {
                     imageWidget = Image.network(msg["text"], fit: BoxFit.cover);
                  } else if (msg["localImagePath"] != null) {
                     imageWidget = Image.file(File(msg["localImagePath"]), fit: BoxFit.cover);
                  } else {
                     imageWidget = const Text("Image missing");
                  }

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageWidget,
                      ),
                    ),
                  );
                }

                // Text Rendering
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                      ),
                    ),
                    child: msg["isTyping"] == true 
                      ? const SizedBox(height: 20, width: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                      : Text(
                          msg["text"],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.whitee70, 
                            fontSize: 16, 
                            fontWeight: FontWeight.w500 // Bolder text
                          ),
                        ),
                  ),
                );
              },
            ),
          ),
          
          // Animated Emoji Layer (Simplistic representation)
          FadeTransition(
            opacity: _emojiAnimController,
            child: ScaleTransition(
              scale: _emojiAnimController,
              child: const Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 20.0, bottom: 80.0),
                  child: Text("✨", style: TextStyle(fontSize: 30)),
                )
              ),
            ),
          ),

          isSubscribed ? _buildChatInput() : _buildLockedInput()
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.photo_library, color: Colors.white70),
              onPressed: _pickImage,
            ),
            Expanded(
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
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
      color: Colors.red.shade900,
      padding: const EdgeInsets.all(15),
      child: const Center(
        child: Text(
          "Your plan has expired! Please renew.",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
