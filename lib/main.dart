import 'package:flutter/material.dart';
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
  
  String loadingText = "Aditi connect ho rahi hai... ❤️"; 
  // 🔴 NAYA: Progress bar ko chalane ke liye variable
  double? loadingProgress; 
  
  final TextEditingController _msgController = TextEditingController();
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
    
    // 🔴 NAYA: Progress string ke sath decimal value bhi aayegi line animation ke liye
    await _brain.initialize(
      onProgress: (String statusText, double? progressValue) {
        if(mounted) {
          setState(() {
            loadingText = statusText;
            loadingProgress = progressValue;
          });
        }
      }
    );
    
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

  Future<void> _sendMessage(bool isPhotoRequest) async {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"isMe": true, "text": text, "isImage": false});
    });
    _msgController.clear();

    if (isPhotoRequest) {
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
      setState(() {
         messages.add({"isMe": false, "text": "typing...", "isImage": false});
      });
      String aiResponse = "";
      int responseIndex = messages.length - 1; 

      _brain.sendChatMessage(text).listen((String token) {
        if(mounted) {
          setState(() {
            if(aiResponse.isEmpty && token.trim().isEmpty) return; 
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🔴 NAYA: Real Line Progress Bar Animation
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: loadingProgress, // Yahan percentage set hoti hai
                    minHeight: 10, // Line ki motai
                    backgroundColor: Colors.grey.shade800,
                    color: Colors.pinkAccent,
                  ),
                ),
                const SizedBox(height: 25),
                Text(
                  loadingText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 15),
                const Text(
                  "(1.5 GB file download hone me time lagta hai.\nKripya app background me chalne dein)",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aditi ❤️"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
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
              accountName: const Text("Premium Member"),
              accountEmail: Text(isSubscribed ? "Plan Active: $daysLeft days left" : "Plan Expired"),
              currentAccountPicture: const CircleAvatar(child: Icon(Icons.person)),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("New Chat"),
              onTap: () {
                setState(() {
                  messages.clear();
                  messages.add({"isMe": false, "text": "Bolo jaan, kya baat karni hai ab? 😘", "isImage": false});
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Chat History", style: TextStyle(color: Colors.grey)),
            ),
            ListTile(
              title: const Text("Late night talks..."),
              onTap: () {},
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    messages.clear();
                    messages.add({"isMe": false, "text": "Saari purani baatein delete kar di. Ab nayi shuruat karein? ❤️", "isImage": false});
                  });
                  Navigator.pop(context); 
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
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var msg = messages[index];
                if(msg["isImage"] == true) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
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
                              child: const Center(child: CircularProgressIndicator(color: Colors.pinkAccent)),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Text("Photo laane me error ho gaya 😢", style: TextStyle(color: Colors.red));
                          }
                        ),
                      )
                    )
                  );
                }
                return Align(
                  alignment: msg["isMe"] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg["isMe"] ? Colors.pink.shade700 : Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      msg["text"],
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          isSubscribed ? _buildChatInput() : _buildLockedInput() 
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.image, color: Colors.pinkAccent), 
            onPressed: () => _sendMessage(true) 
          ), 
          IconButton(
            icon: const Icon(Icons.send, color: Colors.pinkAccent), 
            onPressed: () => _sendMessage(false) 
          ), 
        ],
      ),
    );
  }

  Widget _buildLockedInput() {
    return Container(
      color: Colors.red.shade900,
      padding: const EdgeInsets.all(15),
      child: const Center(
        child: Text(
          "Your plan has expired! Please renew to continue chatting.",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
