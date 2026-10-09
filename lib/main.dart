import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(AditiApp());

class AditiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aditi AI',
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
                // Chat clear karo aur Aditi ka naya welcome message lao
              },
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Chat History", style: TextStyle(color: Colors.grey)),
            ),
            // Example of a Chat History Item with Delete Option
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
            child: ListView(
              // Yahan aapke chat bubbles aayenge
            ),
          ),
          // CHAT INPUT YA LOCK SCREEN
          isSubscribed 
            ? _buildChatInput() // Agar plan hai toh type karne do
            : _buildLockedInput() // Agar expire ho gaya toh lock kar do
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
            child: TextField(decoration: InputDecoration(hintText: "Message Aditi...")),
          ),
          IconButton(icon: Icon(Icons.image), onPressed: () {}), // Photo request
          IconButton(icon: Icon(Icons.send), onPressed: () {}), // Send msg
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
