// File: lib/main.dart
import 'package:flutter/material.dart';
import 'dart:async';

// Dono alag files ko yahan bulaya gaya hai!
import 'ai_brain.dart';    // AI ka logic
import 'payment_api.dart'; // Payment aur Admin ka logic

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
  
  Timer? _subscriptionTimer;
  bool _isPlanActive = true; 
  String _userId = "user_12345"; // Ye phone me login karne wale ka ID hoga

  @override
  void initState() {
    super.initState();
    // App start hote hi payment check karo
    _verifyPaymentLive();

    // Har 10 minute me chup-chaap background me check karega
    _subscriptionTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      _verifyPaymentLive();
    });
  }

  // ==========================================
  // 💰 CONNECTION TO PAYMENT API FILE
  // ==========================================
  Future<void> _verifyPaymentLive() async {
    print("Vercel Admin Panel se live status check kar raha hu...");
    
    // Yahan humne teri NAYI file (PaymentAPI) ko call kiya!
    Map<String, dynamic> status = await PaymentAPI.checkUserSubscription(_userId);
    
    setState(() {
      _isPlanActive = status['is_active'] ?? false;
    });

    // Agar plan expire ho gaya admin panel se, toh app lock ho jayegi
    if (!_isPlanActive) {
      _showPaymentPopup(status['message'] ?? "Plan Expired!");
    }
  }

  @override
  void dispose() {
    _subscriptionTimer?.cancel();
    super.dispose();
  }

  // ==========================================
  // 🧠 CHAT LOGIC (Connected to ai_brain.dart)
  // ==========================================
  Future<void> _handleSendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Msg bhejne se pehle check karo plan active hai ya nahi
    if (!_isPlanActive) {
      _showPaymentPopup("Bhai plan expire ho gaya hai, renew karwa!");
      return;
    }

    setState(() { _messages.add({"role": "user", "text": text}); });
    _messageController.clear();

    // AI file ko bulaya
    String aiReply = await EdrolBrain.getResponse(text, _currentMode);

    setState(() { _messages.add({"role": "ai", "text": aiReply}); });
  }

  void _showPaymentPopup(String message) {
    showDialog(
      barrierDismissible: false, // User bina pay kiye back nahi ja sakta
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Subscription Required", style: TextStyle(color: Colors.pinkAccent)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              // Yahan Live pricing lane ka code chalega: PaymentAPI.getLivePlans()
              print("Live plans dikhao");
            },
            child: const Text("View Plans & Pay"),
          )
        ],
      )
    );
  }

  // ... (Baaki wahi same Chat UI jo pehle diya tha) ...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text("Edrol AI", style: TextStyle(color: Colors.pinkAccent)),
        backgroundColor: Colors.black,
      ),
      body: Center(child: Text("Chat UI Here", style: TextStyle(color: Colors.white))),
    );
  }
}
