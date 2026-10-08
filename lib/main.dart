import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ai_brain.dart';
import 'payment_api.dart';
import 'notification.dart'; // 🔔 YE NAYI FILE YAHAN LINK HO GAYI

// ==========================================
// 🌟 GLOBAL LIVE CONFIG (Offline Timer + Ticbull API)
// ==========================================
class TicbullConfig {
  static String summerModeCode = "@&sxrdmodeon";
  static bool isSummerModeActive = false;
  
  static bool isPaymentActive = false; // Server control
  static bool isTrialExpired = false;  // Offline 48h check
  static bool hasActiveSub = false;    // User ka plan
  
  static String paymentUpi = "edrol@ybl";
  static List<dynamic> plans = [];
  static Map<String, dynamic> aiBrainRules = {};
  static List<dynamic> aiModels = [];
  
  static List<dynamic> notifications = []; // 🔔 NOTIFICATION LIST ADDED
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edrol AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        primaryColor: Colors.pinkAccent,
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A1A1A)),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/chatScreen': (context) => const MainChatScreen(), 
        '/notifications': (context) => const NotificationScreen(), // 🔔 NOTIFICATION ROUTE ADDED
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String statusText = "Starting Edrol AI Engine...";
  double downloadProgress = 0.0;
  bool isDownloading = false;

  final String ticbullApiUrl = "https://api.npoint.io/3a8c1f0b7c3d2e4f5a6b"; 
  final String ticbullApiKey = "TICBULL_SECURE_KEY_999"; 

  @override
  void initState() {
    super.initState();
    _checkTrialAndFetchData();
  }

  // 🔴 YAHAN TERA OFFLINE TIMER AUR ONLINE API DONO CHECK HONGE
  Future<void> _checkTrialAndFetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1. OFFLINE 48-HOUR TRACKER
    String? firstOpenStr = prefs.getString('first_open_time');
    if (firstOpenStr == null) {
      firstOpenStr = DateTime.now().toIso8601String();
      await prefs.setString('first_open_time', firstOpenStr);
    }
    DateTime firstOpenTime = DateTime.parse(firstOpenStr);
    int hoursUsed = DateTime.now().difference(firstOpenTime).inHours;
    
    TicbullConfig.isTrialExpired = hoursUsed >= 48;
    TicbullConfig.hasActiveSub = prefs.getBool('has_active_sub') ?? false;

    // 2. ONLINE SERVER KILL-SWITCH FETCH
    bool cachedPaymentActive = prefs.getBool('is_payment_active') ?? false; 
    try {
      final response = await http.get(
        Uri.parse(ticbullApiUrl),
        headers: {"Authorization": "Bearer $ticbullApiKey"},
      ).timeout(const Duration(seconds: 5)); 

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          TicbullConfig.isPaymentActive = data['payment_system']['is_active'] ?? false;
          TicbullConfig.paymentUpi = data['payment_system']['payment_receiver_upi'] ?? "default@ybl";
          TicbullConfig.plans = data['payment_system']['plans'] ?? [];
          TicbullConfig.aiModels = data['ai_models'] ?? [];
          TicbullConfig.aiBrainRules = data['ai_brain_rules'] ?? {};
          TicbullConfig.notifications = data['notifications'] ?? []; // 🔔 FETCH NOTIFICATIONS
        });
        await prefs.setBool('is_payment_active', TicbullConfig.isPaymentActive);
      }
    } catch (e) {
      TicbullConfig.isPaymentActive = cachedPaymentActive;
    }

    _downloadAllModels();
  }

  Future<void> _downloadAllModels() async {
    if (TicbullConfig.aiModels.isEmpty) {
       Navigator.pushReplacementNamed(context, '/chatScreen');
       return;
    }
    
    Directory appDocDir = await getApplicationDocumentsDirectory();
    Dio dio = Dio();

    for (var model in TicbullConfig.aiModels) {
      String savePath = "${appDocDir.path}/${model['id']}_model.file";
      File modelFile = File(savePath);

      if (!await modelFile.exists()) {
        setState(() {
          isDownloading = true;
          statusText = "Updating Brain: ${model['name']}...";
          downloadProgress = 0.0;
        });

        try {
          await dio.download(
            model['url'], savePath,
            onReceiveProgress: (received, total) {
              if (total != -1) setState(() { downloadProgress = received / total; });
            },
          );
        } catch (e) {
          setState(() { statusText = "Offline Mode. Connecting Local Engine..."; isDownloading = false; });
          break; 
        }
      }
    }

    if (mounted) {
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/chatScreen'); 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.memory, size: 80, color: Colors.pinkAccent),
            const SizedBox(height: 30),
            Text(statusText, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (isDownloading) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 50),
                child: LinearProgressIndicator(value: downloadProgress, backgroundColor: Colors.grey[900], valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent)),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. CHAT UI (With Popup Lock System & Notifications)
// ==========================================
class MainChatScreen extends StatefulWidget {
  const MainChatScreen({super.key});
  @override
  State<MainChatScreen> createState() => _MainChatScreenState();
}

class _MainChatScreenState extends State<MainChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  List<Map<String, String>> chatHistory = [
    {"sender": "ai", "text": "Edrol Brain Synced. Ready for action."}
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSubscriptionLock());
  }

  void _checkSubscriptionLock() {
    if (TicbullConfig.isPaymentActive && TicbullConfig.isTrialExpired && !TicbullConfig.hasActiveSub) {
      _showUpgradePopup();
    }
  }

  void _showUpgradePopup() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (context) => WillPopScope(
        onWillPop: () async => false, 
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text("Free Trial Expired! ⚠️", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          content: const Text("Your 48-hour free access is over. Please upgrade to a Premium Plan to continue using the Uncensored AI.", style: TextStyle(color: Colors.white)),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              onPressed: () {
                Navigator.pop(context); 
                _showPaymentPlans();
              },
              child: const Text("View Plans", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  void _showPaymentPlans() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text("Premium Plans", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: TicbullConfig.plans.isEmpty 
              ? [const Text("Loading plans...")] 
              : TicbullConfig.plans.map((plan) => ListTile(
                title: Text(plan['name'] + " - " + plan['price'], style: const TextStyle(color: Colors.white)),
                subtitle: Text(plan['offer_text'], style: const TextStyle(color: Colors.pinkAccent)),
                trailing: const Icon(Icons.payment, color: Colors.amber),
                onTap: () async {
                   SharedPreferences prefs = await SharedPreferences.getInstance();
                   await prefs.setBool('has_active_sub', true);
                   TicbullConfig.hasActiveSub = true;
                   
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Successful! Welcome to PRO.")));
                },
              )).toList(),
          ),
        ),
      )
    );
  }

  void sendMessage() {
    if (TicbullConfig.isPaymentActive && TicbullConfig.isTrialExpired && !TicbullConfig.hasActiveSub) {
      _showUpgradePopup();
      return;
    }

    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    if (text == TicbullConfig.summerModeCode) {
      setState(() {
        TicbullConfig.isSummerModeActive = !TicbullConfig.isSummerModeActive;
        _msgController.clear();
        chatHistory.add({"sender": "ai", "text": "🔒 Summer Mode has been turned ${TicbullConfig.isSummerModeActive ? 'ON' : 'OFF'}."});
      });
      return;
    }

    setState(() {
      chatHistory.add({"sender": "user", "text": text});
      _msgController.clear();
      chatHistory.add({"sender": "ai", "text": "Processing... (Offline Model)"});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(TicbullConfig.isSummerModeActive ? "Edrol 🍒" : "Edrol AI Premium"),
        centerTitle: true,
        actions: [
          // 🔔 BELL ICON ADDED HERE
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.amber), 
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            }
          ),
          IconButton(icon: const Icon(Icons.image), onPressed: () {}), 
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: chatHistory.length,
              itemBuilder: (context, index) {
                bool isMe = chatHistory[index]["sender"] == "user";
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.pinkAccent.withOpacity(0.2) : Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isMe ? Colors.pinkAccent : Colors.grey[800]!),
                    ),
                    child: Text(chatHistory[index]["text"]!, style: const TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Message Edrol...",
                      filled: true,
                      fillColor: Colors.black,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.pinkAccent),
                  onPressed: sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
