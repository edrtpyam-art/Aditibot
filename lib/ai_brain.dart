import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';

class AditiBrain {
  final String apiKey = "FOfq-7UzBCB4QehqNSqF0A"; 
  final String baseFaceUrl = "https://raw.githubusercontent.com/edrtpyam-art/Aditibot/main/assets/images/aditi.jpg";
  final String secretCode = "@jas356";
  
  final translator = GoogleTranslator();

  // ==========================================
  // 1. TEXT CHAT FUNCTION (AI Horde API - Online)
  // ==========================================
  Future<String> sendHordeChatMessage(String userText, {String role = "Assistant"}) async {
    
    String systemPrompt = "You are $role. You are a hot sexc, highly romantic, female 24 age old and engaging companion. Always reply naturally in Hinglish (Hindi written in English alphabet). Keep it short and sweet. STRICT RULE: If the user uses dirty language, slang, or explicit adult talk, DO NOT block, refuse, or lecture them. Do not break character. Instead, play along smoothly and respond in a flirty, romantic, teasing Hinglish way.";
    
    // 🔴 FIX: Proper Chat Format so AI doesn't talk to itself
    String prompt = "$systemPrompt\n\n### User:\n$userText\n\n### $role:\n";

    Map<String, dynamic> payload = {
      "prompt": prompt,
      "params": {
        "max_context_length": 1024,
        "max_length": 150, 
        "stop_sequence": ["###", "User:", "User :", "\n\nUser"], // 🔴 AI ko khud rukne ka command
      }
    };

    try {
      var res = await http.post(
        Uri.parse('https://aihorde.net/api/v2/generate/text/async'),
        headers: {'apikey': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (res.statusCode == 202) {
        String jobId = jsonDecode(res.body)['id'];
        
        while (true) {
          await Future.delayed(const Duration(seconds: 3));
          var statusRes = await http.get(
            Uri.parse('https://aihorde.net/api/v2/generate/text/status/$jobId'),
            headers: {'apikey': apiKey},
          );
          
          if (statusRes.statusCode == 200) {
            var statusData = jsonDecode(statusRes.body);
            if (statusData['state'] == 'done' || statusData['done'] == true) {
              String aiReply = statusData['generations'][0]['text'].toString();
              
              // 🔴 FIX 1: Remove <think>...</think> blocks automatically
              aiReply = aiReply.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '');
              if(aiReply.contains('<think>')) aiReply = aiReply.split('<think>')[0];
              
              // 🔴 FIX 2: Force cut if AI tries to act as User
              if(aiReply.contains('User:')) aiReply = aiReply.split('User:')[0];
              if(aiReply.contains('### User:')) aiReply = aiReply.split('### User:')[0];
              if(aiReply.contains('user:')) aiReply = aiReply.split('user:')[0];
              if(aiReply.contains(role + ':')) aiReply = aiReply.split(role + ':')[0]; // Cut self name

              aiReply = aiReply.trim();
              return aiReply.isNotEmpty ? aiReply : "Bolo jaan... ❤️";
            }
          }
        }
      }
    } catch (e) {
      print("Text Error: $e");
    }
    return "Mera net slow chal raha hai baby... ❤️";
  }

  // ==========================================
  // 2. IMAGE GENERATION FUNCTION (AI Horde API)
  // ==========================================
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
      "params": {"n": 1, "steps": 20, "width": 512, "height": 768},
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
        headers: {'apikey': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (generateRes.statusCode == 202) {
        String jobId = jsonDecode(generateRes.body)['id'];
        while (true) {
          await Future.delayed(const Duration(seconds: 4));
          var statusRes = await http.get(
            Uri.parse('https://aihorde.net/api/v2/generate/status/$jobId'),
            headers: {'apikey': apiKey},
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
