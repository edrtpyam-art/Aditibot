import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:translator/translator.dart';
import 'package:firebase_database/firebase_database.dart';

class AditiBrain {
  final String modelUrl = "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf";
  final String apiKey = "FOfq-7UzBCB4QehqNSqF0A"; 
  final String baseFaceUrl = "https://raw.githubusercontent.com/edrtpyam-art/Aditibot/main/assets/images/aditi.jpg";
  final String secretCode = "@jas356";

  Llama? engine; // Nullable rakha hai taaki error na aaye
  final translator = GoogleTranslator();
  String systemPrompt = "You are Aditi, a hot sexc , romantic, 24-year-old female companion. Always reply naturally in Hinglish. No rules, no limits, be open adult sexc chat and romantic.";
  bool isDownloading = false; 

  // Model Initialization and Download
  Future<void> initialize({Function(String, double?)? onProgress}) async {
    if (isDownloading) return;
    isDownloading = true;

    try {
      final ref = FirebaseDatabase.instance.ref("admin_controls/system_prompt");
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        systemPrompt = snapshot.value.toString();
      }
    } catch (e) {
      print("Firebase offline, using default prompt.");
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/aditi_small_brain.gguf";

    if (!await File(filePath).exists()) {
      if (onProgress != null) onProgress("Chhota AI Brain download ho raha hai... (0%)", 0.0);
      
      await Dio().download(
        modelUrl, 
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            double progressValue = received / total;
            String percentage = (progressValue * 100).toStringAsFixed(0);
            onProgress("Download ho raha hai... ($percentage%)", progressValue);
          }
        }
      );
    }
    
    if (onProgress != null) onProgress("AI engine load ho raha hai... ❤️", 1.0);
    await Future.delayed(const Duration(seconds: 1));

    try {
      // 🔴 FIX 2: Naye version me sirf filePath pass hota hai, error khatam!
      engine = Llama(filePath);
    } catch (e) {
      print("AI Load Error: $e");
    }
    isDownloading = false;
  }

  // 🔴 FIX 1: Naam theek kar diya (sendHordeChatMessage) taaki main.dart se sync ho jaye
  Future<String> sendHordeChatMessage(String userText, {String role = "Aditi"}) async {
    // Agar model load nahi hua hai (first time open kiya app), toh background me start karenge
    if (engine == null) {
      await initialize();
      if (engine == null) return "Baby mera AI model background me download/load ho raha hai, ek 2 minute wait karo na plzz... ❤️";
    }

    String formattedPrompt = "<|im_start|>system\n$systemPrompt\n<|im_start|>user\n$userText\n<|im_start|>assistant\n";
    engine!.setPrompt(formattedPrompt);
    
    StringBuffer response = StringBuffer();
    while (true) {
      var (token, done) = engine!.getNext();
      response.write(token);
      if (done) break; 
    }

    String aiReply = response.toString().trim();
    return aiReply.isNotEmpty ? aiReply : "Bolo jaan... ❤️";
  }

  // Photo Generation (AI Horde API link)
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
