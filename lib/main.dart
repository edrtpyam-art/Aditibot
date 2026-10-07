// File: lib/main.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'ai_brain.dart'; // Brain file ko yahan import kiya

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ChatScreen(),
  ));
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  String _currentMode = "Education";
  
  // Subscription variables
  Timer? _subscriptionTimer;
  bool _isPlanActive = true; 

  @override
  void initState() {
    super.initState();
    // TIMER LOGIC: Har 1 ghante me payment check karega
    _subscriptionTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _checkSubscriptionStatus();
    });
  }

  @override
  void dispose() {
    _subscriptionTimer?.cancel(); // App band hone par timer rok do
    super.dispose();
  }

  // ==========================================
  // 💰 PAYMENT CHECK LOGIC
  // ==========================================
  Future<void> _checkSubscriptionStatus() async {
    // Yahan teri Vercel API hit hogi: https://aditibot.vercel.app/api/verify-license
    print("Checking payment status in background...");
    
    // Maan le Vercel ne bola expire ho gaya:
    // setState(() { _isPlanActive = false; });
  }

  // ==========================================
  // 🔗 CONNECTING BODY TO BRAIN
  // ==========================================
  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;

    if (!_isPlanActive) {
      _showPaymentPopup();
      return;
    }

    setState(() { _messages.add({"role": "user", "text": text}); });
    _messageController.clear();

    // BODY NE BRAIN KO BULAYA (Alag file se)
    String aiReply = await EdrolBrain.getResponse(text, _currentMode);

    setState(() { _messages.add({"role": "ai", "text": aiReply}); });
  }

  void _showPaymentPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Plan Expired!", style: TextStyle(color: Colors.pinkAccent)),
        content: const Text("Bhai, ₹29 ka recharge karwa le, Edrol AI offline hai.", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Pay Now"),
          )
        ],
      )
    );
  }

  // ==========================================
  // 🎨 UI DESIGN (Shortened for preview)
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _currentMode,
            dropdownColor: const Color(0xFF1A1A1A),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.pinkAccent),
            items: ["Education", "Girlfriend", "Wife"].map((String mode) {
              return DropdownMenuItem<String>(
                value: mode,
                child: Text(mode, style: const TextStyle(color: Colors.white)),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() { _currentMode = newValue!; _messages.clear(); });
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isUser = _messages[index]["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    color: isUser ? Colors.pinkAccent.withOpacity(0.2) : const Color(0xFF1A1A1A),
                    child: Text(_messages[index]["text"]!, style: const TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: "Message...", hintStyle: TextStyle(color: Colors.white54)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.pinkAccent),
                  onPressed: () => _handleSendMessage(_messageController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
