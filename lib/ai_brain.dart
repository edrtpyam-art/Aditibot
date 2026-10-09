import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
// 🔴 NAYA: Firebase wapas add kar diya gaya hai!
import 'package:firebase_database/firebase_database.dart'; 

class AditiBrain {
  final String secretCode = "@jas356";
  final translator = GoogleTranslator();

  // ==========================================
  // 1. TEXT CHAT FUNCTION (Pollinations API + Firebase Admin)
  // ==========================================
  Future<String> sendHordeChatMessage(String userText, {String role = "Aditi"}) async {
    
    // Default Prompt (Agar Firebase ya net thoda slow ho)
    String systemPrompt = 
        "You are $role, a 24-year-old hot, romantic, playful, and loving sexc hot warm female companion. "
        "CRITICAL RULES: "
        "1. ALWAYS speak in HINGLISH (Hindi written in English alphabet). Example: 'Main theek hoon baby, tum batao?'. NEVER use pure English. "
        "2. You are a real female. Play along with romance sexc full opan language and flirting smoothly. "
        "3. Keep replies very short and sweet (1 to 2 sentences max).";

    // 🔴 FIREBASE CHECK: Admin Panel se live prompt uthana
    try {
      final ref = FirebaseDatabase.instance.ref("admin_controls/system_prompt");
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        String adminPrompt = snapshot.value.toString();
        if (adminPrompt.trim().isNotEmpty) {
          systemPrompt = adminPrompt; // App ab Admin Panel ki baat manega
        }
      }
    } catch (e) {
      print("Firebase offline, using default prompt.");
    }

    try {
      var res = await http.post(
        Uri.parse('https://text.pollinations.ai/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "messages": [
            {"role": "system", "content": systemPrompt},
            {"role": "user", "content": userText}
          ],
          "model": "mistral" // Fast aur smart model
        }),
      );

      if (res.statusCode == 200) {
        String aiReply = res.body.toString().trim();
        
        // Failsafe: Agar AI apna naam pehle likh de toh usko cut kar do
        if(aiReply.contains('User:')) aiReply = aiReply.split('User:')[0];
        if(aiReply.contains(role + ':')) aiReply = aiReply.split(role + ':')[0];
        if(aiReply.startsWith('"') && aiReply.endsWith('"')) {
          aiReply = aiReply.substring(1, aiReply.length - 1);
        }

        return aiReply.isNotEmpty ? aiReply : "Bolo jaan... ❤️";
      }
    } catch (e) {
      print("Text Error: $e");
    }
    return "Mera network thoda slow hai baby, ek second... ❤️";
  }

  // ==========================================
  // 2. IMAGE GENERATION FUNCTION (Pollinations API - Instant URL)
  // ==========================================
  Future<String?> generateHordeImage(String hinglishPrompt, {String? localImagePath, String? characterName}) async {
    String cleanPrompt = hinglishPrompt.replaceAll(secretCode, "").trim();
    String finalEnglishPrompt = "";
    
    // Hinglish to English translation
    try {
      var translation = await translator.translate(cleanPrompt, to: 'en');
      finalEnglishPrompt = translation.text;
    } catch (e) {
      finalEnglishPrompt = cleanPrompt; // Failsafe
    }

    // Ek unique seed generate karenge taaki har baar nayi photo aaye
    int randomSeed = Random().nextInt(1000000);
    
    // Prompt ko thoda aur realistic aur sundar banane ke liye keywords
    String basePrompt = "1girl, indian, extremely beautiful, masterpiece, highly detailed, realistic, $finalEnglishPrompt";
    
    // Prompt ko URL format me encode karna zaroori hai
    String encodedPrompt = Uri.encodeComponent(basePrompt);

    // KAMAAL KI BAAT: Pollinations direct ek URL banata hai aur usme hi image hoti hai!
    String imageUrl = "https://image.pollinations.ai/prompt/$encodedPrompt?width=512&height=768&nologo=true&seed=$randomSeed";

    return imageUrl;
  }
}
