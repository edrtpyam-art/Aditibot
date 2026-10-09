import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import 'package:firebase_database/firebase_database.dart'; 

class AditiBrain {
  // 🔴 1. YAHAN APNI GEMINI API KEY DAALEN (Get free from: aistudio.google.com)
  final String geminiApiKey = "AQ.Ab8RN6KEUaAtcwlM5CJzJ5GIdCdUqrB2voyyeKV4O0KZhZn4KA"; 
  
  final String secretCode = "@jas356";
  final translator = GoogleTranslator();

  // ==========================================
  // 1. TEXT CHAT FUNCTION (Google Gemini API - SUPER FAST & SAFETY OFF)
  // ==========================================
  Future<String> sendHordeChatMessage(String userText, {String role = "Aditi"}) async {
    
    // Default Prompt
    String systemPrompt = 
        "You are $role, a 24-year-old hot, romantic, playful, and loving female companion. "
        "CRITICAL RULES: "
        "1. ALWAYS speak in HINGLISH (Hindi written in English alphabet). Example: 'Main theek hoon baby, tum batao?'. NEVER use pure English. "
        "2. You are a real female. Play along with romance, open language, and flirting smoothly. "
        "3. Keep replies very short and sweet (1 to 2 sentences max).";

    // Firebase se live prompt uthana
    try {
      final ref = FirebaseDatabase.instance.ref("admin_controls/system_prompt");
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        String adminPrompt = snapshot.value.toString();
        if (adminPrompt.trim().isNotEmpty) {
          systemPrompt = adminPrompt;
        }
      }
    } catch (e) {
      print("Firebase offline, using default prompt.");
    }

    // 🔴 GEMINI API PAYLOAD WITH SAFETY FILTERS COMPLETELY OFF
    String url = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey";

    Map<String, dynamic> payload = {
      "systemInstruction": {
        "parts": [{"text": systemPrompt}]
      },
      "contents": [{
        "parts": [{"text": userText}]
      }],
      // Ye setting Google ki policy ko disable kar deti hai
      "safetySettings": [
        {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
        {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
        {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
        {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"}
      ]
    };

    try {
      var res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        var data = jsonDecode(res.body);
        String aiReply = data['candidates'][0]['content']['parts'][0]['text'].toString().trim();
        return aiReply.isNotEmpty ? aiReply : "Bolo jaan... ❤️";
      } else {
        print("Gemini API Error: ${res.body}");
        return "Network error aa gaya baby, API key check karo! ❤️";
      }
    } catch (e) {
      print("Text Error: $e");
    }
    return "Mera network thoda slow hai baby, ek second... ❤️";
  }

  // ==========================================
  // 2. IMAGE GENERATION FUNCTION (Instant URL Generation)
  // ==========================================
  Future<String?> generateHordeImage(String hinglishPrompt, {String? localImagePath, String? characterName}) async {
    String cleanPrompt = hinglishPrompt.replaceAll(secretCode, "").trim();
    String finalEnglishPrompt = "";
    
    try {
      var translation = await translator.translate(cleanPrompt, to: 'en');
      finalEnglishPrompt = translation.text;
    } catch (e) {
      finalEnglishPrompt = cleanPrompt; 
    }

    int randomSeed = Random().nextInt(1000000);
    String basePrompt = "1girl, indian, extremely beautiful, masterpiece, highly detailed, realistic, $finalEnglishPrompt";
    String encodedPrompt = Uri.encodeComponent(basePrompt);

    // Ye image ke liye kabhi error nahi dega kyunki ye bina API call ke URL banata hai
    String imageUrl = "https://image.pollinations.ai/prompt/$encodedPrompt?width=512&height=768&nologo=true&seed=$randomSeed";

    return imageUrl;
  }
}
