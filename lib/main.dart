import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'dart:io';
import 'package:url_launcher/url_launcher.dart'; 
import 'package:firebase_core/firebase_core.dart';          
import 'package:firebase_database/firebase_database.dart';  
import 'package:image_picker/image_picker.dart'; // 👈 Gallery ke liye import

import 'ai_brain.dart';
import 'payment_api.dart';
import 'notification.dart'; 

// ==========================================
// 🌟 DYNAMIC FIREBASE CONFIG (EDROLAI)
// ==========================================
class EdrolServerConfig {
  static String summerModeCode = "@&sxrdmodeon";
  static bool isSummerModeActive = false;
  
  static bool isPaymentActive = false; 
  static bool isTrialExpired = false;  
  static bool hasActiveSub = false;    
  
  static List<dynamic> plans = [];
  static Map<String, dynamic> aiBrainRules = {};
  static List<dynamic> aiModels = []; 
  static List<dynamic> notifications = []; 
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
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
        '/notifications': (context) => const NotificationScreen(), 
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
  String statusText = "Syncing with Edrol Servers...";
  double downloadProgress = 0.0;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    _fetchFirebaseDataAndCheckTrial();
  }

  Future<void> _fetchFirebaseDataAndCheckTrial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? firstOpenStr = prefs.getString('first_open_time');
    if (firstOpenStr == null) {
      firstOpenStr = DateTime.now().toIso8601String();
      await prefs.setString('first_open_time', firstOpenStr);
    }
    DateTime firstOpenTime = DateTime.parse(firstOpenStr);
    int hoursUsed = DateTime.now().difference(firstOpenTime).inHours;
    
    EdrolServerConfig.isTrialExpired = hoursUsed >= 48;
    EdrolServerConfig.hasActiveSub = prefs.getBool('has_active_sub') ?? false;

    bool cachedPaymentActive = prefs.getBool('is_payment_active') ?? false; 
    try {
      DatabaseReference ref = FirebaseDatabase.instance.ref("edrol_config");
      final snapshot = await ref.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        
        setState(() {
          EdrolServerConfig.isPaymentActive = data['payment_system']?['is_active'] ?? false;
          EdrolServerConfig.plans = data['payment_system']?['plans'] ?? [];
          
          if(data['ai_models'] != null) {
            EdrolServerConfig.aiModels = List.from(data['ai_models']); 
          }
          
          EdrolServerConfig.aiBrainRules = data['ai_brain_rules'] ?? {};
          if(data['notifications'] != null) {
             EdrolServerConfig.notifications = List.from(data['notifications']); 
          }
        });
        await prefs.setBool('is_payment_active', EdrolServerConfig.isPaymentActive);

        // 🔴 MAJOR FIX 1: Firebase rules seedha AI Brain me feed ho gaye!
        EdrolBrain.updatePromptsFromFirebase(EdrolServerConfig.aiBrainRules);
      }
    } catch (e) {
      EdrolServerConfig.isPaymentActive = cachedPaymentActive;
    }

    _downloadDynamicModels();
  }

  Future<void> _downloadDynamicModels() async {
    if (EdrolServerConfig.aiModels.isEmpty) {
       Navigator.pushReplacementNamed(context, '/chatScreen');
       return;
    }
    
    Directory appDocDir = await getApplicationDocumentsDirectory();
    Dio dio = Dio();

    for (var model in EdrolServerConfig.aiModels) {
      String savePath = "${appDocDir.path}/${model['id']}_model.file";
      File modelFile = File(savePath);

      if (!await modelFile.exists()) {
        setState(() {
          isDownloading = true;
          statusText = "Downloading ${model['name']}...\nDo not close app";
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
          setState(() { statusText = "Offline. Connecting Local Engine..."; isDownloading = false; });
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
// 3. CHAT UI WITH PHOTO UPLOAD & SUBSCRIPTION
// ==========================================
class MainChatScreen extends StatefulWidget {
  const MainChatScreen({super.key});
  @override
  State<MainChatScreen> createState() => _MainChatScreenState();
}

class _MainChatScreenState extends State<MainChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ImagePicker _picker = ImagePicker(); // 🔴 Gallery Picker Tool
  
  List<Map<String, String>> chatHistory = [
    {"sender": "ai", "text": "Edrol Brain Synced. Ready for action."}
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSubscriptionLock());
  }

  void _checkSubscriptionLock() {
    if (EdrolServerConfig.isPaymentActive && EdrolServerConfig.isTrialExpired && !EdrolServerConfig.hasActiveSub) {
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
          content: const Text("Your 48-hour free access is over. Please upgrade to a Premium Plan to continue using the AI.", style: TextStyle(color: Colors.white)),
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

  void _openPaymentGateway(String url) async {
    final Uri paymentUri = Uri.parse(url);
    if (!await launchUrl(paymentUri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open Payment Gateway!")));
    }
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
            children: EdrolServerConfig.plans.isEmpty 
              ? [const Text("Loading plans...")] 
              : EdrolServerConfig.plans.map((plan) => ListTile(
                title: Text(plan['name'] + " - " + plan['price'], style: const TextStyle(color: Colors.white)),
                subtitle: Text(plan['offer_text'], style: const TextStyle(color: Colors.pinkAccent)),
                trailing: const Icon(Icons.payment, color: Colors.amber),
                onTap: () {
                   if (plan['payment_link'] != null) {
                     _openPaymentGateway(plan['payment_link']);
                   }
                },
              )).toList(),
          ),
          actions: [
             TextButton(
               onPressed: () async {
                 SharedPreferences prefs = await SharedPreferences.getInstance();
                 await prefs.setBool('has_active_sub', true);
                 EdrolServerConfig.hasActiveSub = true;
                 Navigator.pop(context);
               },
               child: const Text("Debug: Mark Paid", style: TextStyle(color: Colors.grey))
             )
          ]
        ),
      )
    );
  }

  // 🔴 MAJOR FIX 2: Photo Upload Logic 
  Future<void> _pickAndProcessImage() async {
    // Payment Check before uploading
    if (EdrolServerConfig.isPaymentActive && EdrolServerConfig.isTrialExpired && !EdrolServerConfig.hasActiveSub) {
      _showUpgradePopup();
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        chatHistory.add({"sender": "user", "text": "📷 [Photo Selected]"});
        chatHistory.add({"sender": "ai", "text": "Analyzing your photo..."});
      });

      // Photo ko seedha AI Brain me process hone bhej diya
      String aiResponse = await EdrolBrain.generateMedia("Analyze image", image.path, false);
      
      setState(() {
        chatHistory.add({"sender": "ai", "text": "Image Processed: Saved at $aiResponse"});
      });
    }
  }

  void sendMessage() async {
    if (EdrolServerConfig.isPaymentActive && EdrolServerConfig.isTrialExpired && !EdrolServerConfig.hasActiveSub) {
      _showUpgradePopup();
      return;
    }

    String text = _msgController.text.trim();
    if (text.isEmpty) return;

    if (text == EdrolServerConfig.summerModeCode) {
      setState(() {
        EdrolServerConfig.isSummerModeActive = !EdrolServerConfig.isSummerModeActive;
        _msgController.clear();
        chatHistory.add({"sender": "ai", "text": "🔒 Summer Mode has been turned ${EdrolServerConfig.isSummerModeActive ? 'ON' : 'OFF'}."});
      });
      return;
    }

    setState(() {
      chatHistory.add({"sender": "user", "text": text});
      _msgController.clear();
    });

    // Yahan active chat rule se AI reply aayega
    String aiReply = await EdrolBrain.getChatReply(text, "Default");
    
    setState(() {
      chatHistory.add({"sender": "ai", "text": aiReply});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(EdrolServerConfig.isSummerModeActive ? "Edrol 🍒" : "Edrol AI Premium"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.amber), 
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            }
          ),
          // 🔴 PHOTO ICON AB GALLERY KHOLEGA!
          IconButton(icon: const Icon(Icons.image), onPressed: _pickAndProcessImage), 
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
