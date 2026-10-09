import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
// 🔴 Naye Imports: Brain aur Notification screen ko link karne ke liye
import 'ai_brain.dart';
import 'notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase init error: $e");
  }

  runApp(AditiApp());
}

class AditiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edrol AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool isSubscribed = true;
  int daysLeft = 0;
  bool isLoading = true; 
  
  final TextEditingController _msgController = TextEditingController();
  // 🔴 Brain object banaya
  final AditiBrain _brain = AditiBrain(); 
  
  List<Map<String, dynamic>> messages = [
    {"isMe": false, "text": "Hii jaan, kya kar rahe ho? ❤️", "isImage": false}
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _checkOfflineTimer();
    // 🔴 App start hote hi offline AI model ko load karo
    await _brain.initialize();
    
    if(mounted) {
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
      
      if (now.isAfter(expiryDate)) {
        setState(() { isSubscribed = false; daysLeft = 0; });
      } else {
        setState(() {
          isSubscribed = true;
          daysLeft = expiryDate.difference(now).inDays;
        });
      }
    }
  }

  // 🔴 REAL AI LOGIC ATTACHED
  Future<void> _sendMessage(bool isPhotoRequest) async {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"isMe": true, "text": text, "isImage": false});
    });
    
    _msgController.clear();

    if (isPhotoRequest) {
      // 1. Photo Request (AI Horde API)
      setState(() {
         messages.add({"isMe": false, "text": "Ek minute rukna baby, main ready ho rahi hoon... 😘", "isImage": false});
      });
      
      String? imageUrl = await _brain.generateRomanticPhoto(text);
      
      if(imageUrl != null && mounted) {
        setState(() {
          messages.add({"isMe": false, "text": imageUrl, "isImage": true});
        });
      }
    } else {
      // 2. Chat Request (Offline Qwen Model)
      // Typing indicator ke liye ek blank message banaya
      setState(() {
         messages.add({"isMe": false, "text": "typing...", "isImage": false});
      });

      String aiResponse = "";
      int responseIndex = messages.length - 1; // Last message ka index

      // Stream ko listen karna taki word-by-word type ho
      _brain.sendChatMessage(text).listen((String token) {
        if(mounted) {
          setState(() {
            if(aiResponse.isEmpty && token.trim().isEmpty) return; // ignore initial empty spaces
            
            // "typing..." ko hatakar asli text lagao
            if(messages[responseIndex]["text"] == "typing...") {
               messages[responseIndex]["text"] = ""; 
            }
            
            aiResponse += token;
            messages[responseIndex]["text"] = aiResponse;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.pinkAccent),
              const SizedBox(height: 20),
              const Text(
                "Aditi connect ho rahi hai... ❤️",
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Aditi ❤️"),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // 🔴 FIXED: Notification icon dabane par ab screen khulegi
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
            },
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("Premium Member"),
              accountEmail: Text(isSubscribed ? "Plan Active: $daysLeft days left" : "Plan Expired"),
              currentAccountPicture: CircleAvatar(child: Icon(Icons.person)),
            ),
            ListTile(
              leading: Icon(Icons.add),
              title: Text("New Chat"),
              onTap: () {
                setState(() {
                  messages.clear();
                  messages.add({"isMe": false, "text": "Bolo jaan, kya baat karni hai ab? 😘", "isImage": false});
                });
                Navigator.pop(context);
              },
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Chat History", style: TextStyle(color: Colors.grey)),
            ),
            ListTile(
              title: Text("Late night talks..."),
              onTap: () {},
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // 🔴 FIXED: Delete dabane par chat history saaf ho jayegi
                  setState(() {
                    messages.clear();
                    messages.add({"isMe": false, "text": "Saari purani baatein delete kar di. Ab nayi shuruat karein? ❤️", "isImage": false});
                  });
                  Navigator.pop(context); // drawer band karo
                },
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var msg = messages[index];
                
                // 🔴 NEW: Agar photo hai, toh NetworkImage dikhao
                if(msg["isImage"] == true) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          msg["text"],
                          width: 250,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              width: 250, height: 250, color: Colors.grey[800],
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Text("Photo laane me error ho gaya 😢", style: TextStyle(color: Colors.red));
                          }
                        ),
                      )
                    )
                  );
                }

                // Normal Text Message
                return Align(
                  alignment: msg["isMe"] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg["isMe"] ? Colors.pink.shade700 : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      msg["text"],
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          isSubscribed 
            ? _buildChatInput() 
            : _buildLockedInput() 
        ],
      ),
    );
  }

  Widget _buildChatInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _msgController,
              decoration: InputDecoration(
                hintText: "Message Aditi...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: EdgeInsets.symmetric(horizontal: 15),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.image, color: Colors.pinkAccent), 
            onPressed: () => _sendMessage(true) 
          ), 
          IconButton(
            icon: Icon(Icons.send, color: Colors.pinkAccent), 
            onPressed: () => _sendMessage(false) 
          ), 
        ],
      ),
    );
  }

  Widget _buildLockedInput() {
    return Container(
      color: Colors.red.shade900,
      padding: EdgeInsets.all(15),
      child: Center(
        child: Text(
          "Your plan has expired! Please renew to continue chatting.",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
