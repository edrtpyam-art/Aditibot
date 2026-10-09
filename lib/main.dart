import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart'; // Admin panel ke liye zaroori

void main() async {
  // App start hote hi Firebase aur background settings load karna
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  runApp(AditiApp());
}

class AditiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aditi AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Dark romantic theme
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
  
  // Message type karne ke liye controller
  final TextEditingController _msgController = TextEditingController();
  
  // Chat history screen par dikhane ke liye list
  List<Map<String, dynamic>> messages = [
    {"isMe": false, "text": "Hii jaan, kya kar rahe ho? ❤️", "isImage": false}
  ];

  @override
  void initState() {
    super.initState();
    _checkOfflineTimer(); // App khulte hi timer check hoga
  }

  // Offline Timer Logic
  Future<void> _checkOfflineTimer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? expiryDateStr = prefs.getString('expiry_date'); // Expiry date local storage se nikali
    
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

  // User ka message send karne ka function
  void _sendMessage(bool isPhotoRequest) {
    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      // User ka message screen par dikhao
      messages.add({"isMe": true, "text": text, "isImage": false});
    });
    
    _msgController.clear();

    // YAHAN AI BRAIN KO CALL JAYEGI
    if (isPhotoRequest) {
      // ImageEngine.generateRomanticPhoto(text)... call hoga
      print("Photo mangi hai: $text");
    } else {
      // AditiBrain.sendMessage(text)... call hoga
      print("Chat bheji hai: $text");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Aditi ❤️"),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // Notification screen open hogi
            },
          )
        ],
      ),
      // SIDE MENU (DRAWER)
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
              onPressed: () {
                setState(() {
                  messages.clear();
                  messages.add({"isMe": false, "text": "Bolo jaan, kya baat karni hai ab? 😘", "isImage": false});
                });
                Navigator.pop(context); // Menu band karne ke liye
              },
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Chat History", style: TextStyle(color: Colors.grey)),
            ),
            ListTile(
              title: Text("Late night talks..."),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // Local DB se chat delete karne ka logic
                },
              ),
            ),
          ],
        ),
      ),
      // MAIN CHAT AREA
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                var msg = messages[index];
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
          // CHAT INPUT YA LOCK SCREEN
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
            onPressed: () => _sendMessage(true) // Photo wali request bhejo
          ), 
          IconButton(
            icon: Icon(Icons.send, color: Colors.pinkAccent), 
            onPressed: () => _sendMessage(false) // Normal chat bhejo
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
