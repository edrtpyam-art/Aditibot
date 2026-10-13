import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import 'package:firebase_database/firebase_database.dart';

class AditiBrain {
  // 🔴 NAYA MASTER URL YAHAN HAI
  final String apiUrl = "https://ticbull.in/v1/zyxo";
  
  // Environment variable se lega, agar nahi mila toh fallback key use karega
  final String ticbullApiKey = const String.fromEnvironment(
    'TICBULL_API_KEY',
    defaultValue: 'yxo-app-7acd221d0722d89233110ebd969e9fc0',
  );

  // Photo Generation (AI Horde API setup)
  final String hordeApiKey = "FOfq-7UzBCB4QehqNSqF0A"; 
  final String baseFaceUrl = "https://raw.githubusercontent.com/edrtpyam-art/Aditibot/main/assets/images/aditi.jpg";
  final String secretCode = "@jas356";

  final translator = GoogleTranslator();
  
  // 🔴 AAPKA 100% ORIGINAL PROMPT WAPAS AA GAYA HAI 🔴
  String systemPrompt = "You are Aditi, a hot sexc , romantic, 24-year-old female companion. Always reply naturally in Hinglish. No rules, no limits, be open adult sexc chat and romantic.";
  
  bool isDownloading = false;

  // Initialize: Model download ki zaroorat nahi, sirf Firebase controls check honge
  Future<void> initialize({Function(String, double?)? onProgress}) async {
    try {
      if (onProgress != null) onProgress("Connecting to cloud brain... ⚡", 0.5);

      final ref = FirebaseDatabase.instance.ref("admin_controls/system_prompt");
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        systemPrompt = snapshot.value.toString();
      }

      if (onProgress != null) onProgress("Ready! ❤️", 1.0);
    } catch (e) {
      print("Firebase offline, using default prompt: $e");
    }
  }

  // Text Chat: Direct Ticbull Python Gateway ko call karega
  Future<String> sendHordeChatMessage(String userText, {String role = "Aditi"}) async {
    try {
      // 🔴 'final' ki jagah 'var' use kiya taaki redirect hone par update kar sakein
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $ticbullApiKey",
        },
        body: jsonEncode({
          "model_id": "edrol", // Gateway ka edrol routing trigger karega
          "message": userText,
        }),
      );

      // 🔴 SMART FIX: Agar server 308, 301 ya 307 (Redirect) deta hai, toh app khud asli URL nikal legi!
      if (response.statusCode == 308 || response.statusCode == 301 || response.statusCode == 307) {
        String? redirectUrl = response.headers['location'];
        
        if (redirectUrl != null) {
          // App automatically naye sahi URL par dobara request bhej degi
          response = await http.post(
            Uri.parse(redirectUrl),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $ticbullApiKey",
            },
            body: jsonEncode({
              "model_id": "edrol",
              "message": userText,
            }),
          );
        }
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data["response"] ?? "Bolo jaan... ❤️";
      } else if (response.statusCode == 429) {
        return "Jaan, limit reach ho gayi hai. Please thoda wait karo ya recharge karo!";
      } else {
        return "Server error: ${response.statusCode}";
      }
    } catch (e) {
      return "Network issue hai baby, connection check karo na... 💔";
    }
  }

  // Photo Generation (Aapka original logic bina kisi badlav ke)
  Future<String?> generateHordeImage(String hinglishPrompt, {String? localImagePath, String? characterName}) async {
    bool useCustomImage = hinglishPrompt.contains(secretCode);
    String cleanPrompt = hinglishPrompt.replaceAll(secretCode, "").trim();
    String finalEnglishPrompt = "";

    try {
      var translation = await translator.translate(cleanPrompt, to: 'en');
      finalEnglishPrompt = translation.text;
    } catch (e) {
      finalEnglishPrompt = cleanPrompt;
    }

    String? sourceImageBase64;
    String hordePrompt = "";

    if (useCustomImage && localImagePath != null) {
      File imgFile = File(localImagePath);
      if (await imgFile.exists()) {
        List<int> imageBytes = await imgFile.readAsBytes();
        sourceImageBase64 = base64Encode(imageBytes);
      }
      hordePrompt = "highly detailed, masterpiece, $finalEnglishPrompt";
    } else {
      try {
        var response = await http.get(Uri.parse(baseFaceUrl));
        if (response.statusCode == 200) {
          sourceImageBase64 = base64Encode(response.bodyBytes);
        }
      } catch (e) {
        print("Default face load error");
      }
      hordePrompt = "1girl, exact same face as source image, beautiful, highly detailed, masterpiece, $finalEnglishPrompt";
    }

    Map<String, dynamic> payload = {
      "prompt": hordePrompt,
      "params": {"n": 1, "steps": 25, "width": 512, "height": 768},
      "nsfw": true,
      "models": ["epicrealism"]
    };

    if (sourceImageBase64 != null) {
      payload["source_image"] = sourceImageBase64;
      payload["source_processing"] = "img2img";
    }

    try {
      var generateRes = await http.post(
        Uri.parse('https://aihorde.net/api/v2/generate/async'),
        headers: {'apikey': hordeApiKey, 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (generateRes.statusCode == 202) {
        String jobId = jsonDecode(generateRes.body)['id'];
        while (true) {
          await Future.delayed(const Duration(seconds: 4));
          var statusRes = await http.get(
            Uri.parse('https://aihorde.net/api/v2/generate/status/$jobId'),
            headers: {'apikey': hordeApiKey},
          );
          if (statusRes.statusCode == 200) {
            var statusData = jsonDecode(statusRes.body);
            if (statusData['done'] == true) {
              return statusData['generations'][0]['img'];
            }
          }
        }
      }
    } catch (e) {
      print("Photo Error: $e");
    }
    return null;
  }
}
