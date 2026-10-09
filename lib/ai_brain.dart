import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:translator/translator.dart';
import 'package:firebase_database/firebase_database.dart';

class AditiBrain {
  // 1. Aapka Offline Qwen Chat Model Link
  final String modelUrl = "https://huggingface.co/mradermacher/Qwen2.5-1.5B-Instruct-uncensored-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-uncensored.Q4_K_M.gguf";
  
  // 2. Aapki AI Horde API Key aur Image Setup
  final String apiKey = "FOfq-7UzBCB4QehqNSqF0A";
  final String baseFaceUrl = "https://raw.githubusercontent.com/edrtpyam-art/Aditibot/main/assets/images/aditi.jpg"; // RAW link
  final String secretCode = "@drtg267";

  late LlamaEngine engine;
  final translator = GoogleTranslator();
  
  // Default system prompt (Agar net na ho toh ye chalega)
  String systemPrompt = "You are Aditi, a romantic desi girlfriend. Always reply in Hinglish.";

  // App start hone par sabse pehle ye function chalega
  Future<void> initialize() async {
    // A. Firebase Admin Panel se naya Prompt fetch karna
    try {
      final ref = FirebaseDatabase.instance.ref("admin_controls/system_prompt");
      final snapshot = await ref.get();
      if (snapshot.exists) {
        systemPrompt = snapshot.value.toString();
        print("Admin Prompt Loaded: $systemPrompt");
      }
    } catch (e) {
      print("Firebase offline, using default prompt.");
    }

    // B. AI Model Download aur Load karna
    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/aditi_qwen_brain.gguf";

    if (!await File(filePath).exists()) {
      print("Downloading Offline AI Brain...");
      await Dio().download(modelUrl, filePath);
    }

    // C. Model ko Phone ki Memory me start karna
    engine = LlamaEngine(
      modelPath: filePath,
      contextSize: 2048,
      threads: 4, 
    );
  }

  // CHAT FUNCTION (100% Offline)
  Stream<String> sendChatMessage(String userText) async* {
    String formattedPrompt = "<|im_start|>system\n$systemPrompt<|im_end|>\n<|im_start|>user\n$userText<|im_end|>\n<|im_start|>assistant\n";
    
    await for (final token in engine.generate(formattedPrompt)) {
      yield token; // Ye stream type-writer effect ke liye hai
    }
  }

  // PHOTO GENERATOR (Hinglish -> English -> Translation -> Horde API)
  Future<String?> generateRomanticPhoto(String hinglishPrompt) async {
    bool useBaseFace = true;
    String finalEnglishPrompt = "";

    // 1. Secret Code Check (@drtg267)
    if (hinglishPrompt.contains(secretCode)) {
      useBaseFace = false; // Code mil gaya! Doosra face banega.
      hinglishPrompt = hinglishPrompt.replaceAll(secretCode, "").trim();
    }

    // 2. Hinglish to English Translate karna
    try {
      var translation = await translator.translate(hinglishPrompt, to: 'en');
      finalEnglishPrompt = translation.text;
    } catch (e) {
      finalEnglishPrompt = hinglishPrompt; // Failsafe
    }

    // 3. GitHub se Aditi ka Base64 Face nikalna (Agar zaroorat ho)
    String? base64Image;
    if (useBaseFace) {
      try {
        var response = await http.get(Uri.parse(baseFaceUrl));
        if (response.statusCode == 200) base64Image = base64Encode(response.bodyBytes);
      } catch (e) {
        print("Face load error");
      }
    }

    // 4. AI Horde Prompt Setup
    String hordePrompt = useBaseFace 
        ? "1girl, exact same face as source image, beautiful, highly detailed, " + finalEnglishPrompt 
        : "highly detailed, " + finalEnglishPrompt; // Agar code diya toh base face mat bolo

    Map<String, dynamic> payload = {
      "prompt": hordePrompt,
      "params": {"n": 1, "steps": 25, "width": 512, "height": 768},
      "nsfw": true, // Policy bypass
      "models": ["epicrealism"]
    };

    if (useBaseFace && base64Image != null) {
      payload["source_image"] = base64Image;
      payload["source_processing"] = "img2img";
    }

    // 5. API Request aur Polling (Photo banne ka wait karna)
    try {
      var generateRes = await http.post(
        Uri.parse('https://aihorde.net/api/v2/generate/async'),
        headers: {'apikey': apiKey, 'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (generateRes.statusCode == 202) {
        String jobId = jsonDecode(generateRes.body)['id'];
        
        while (true) {
          await Future.delayed(Duration(seconds: 4)); // Har 4 second me check
          var statusRes = await http.get(
            Uri.parse('https://aihorde.net/api/v2/generate/status/$jobId'),
            headers: {'apikey': apiKey},
          );

          if (statusRes.statusCode == 200) {
            var statusData = jsonDecode(statusRes.body);
            if (statusData['done'] == true) {
              return statusData['generations'][0]['img']; // Final Image URL
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
