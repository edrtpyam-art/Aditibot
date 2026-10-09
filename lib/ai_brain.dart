import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:translator/translator.dart';
import 'package:firebase_database/firebase_database.dart';

class AditiBrain {
  final String modelUrl = "https://huggingface.co/mradermacher/Qwen2.5-1.5B-Instruct-uncensored-GGUF/resolve/main/Qwen2.5-1.5B-Instruct-uncensored.Q4_K_M.gguf";
  final String apiKey = "FOfq-7UzBCB4QehqNSqF0A";
  final String baseFaceUrl = "https://raw.githubusercontent.com/edrtpyam-art/Aditibot/main/assets/images/aditi.jpg";
  final String secretCode = "@drtg267";

  late Llama engine;
  final translator = GoogleTranslator();
  String systemPrompt = "You are Aditi, a hot sexc romantic desi girlfriend. Always reply in Hinglish.";

  // 🔴 NAYA: Progress percentage (double) bhi bhejenge progress bar ke liye
  Future<void> initialize({Function(String, double?)? onProgress}) async {
    try {
      final ref = FirebaseDatabase.instance.ref("admin_controls/system_prompt");
      final snapshot = await ref.get();
      if (snapshot.exists) {
        systemPrompt = snapshot.value.toString();
      }
    } catch (e) {
      print("Firebase offline, using default prompt.");
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = "${dir.path}/aditi_qwen_brain.gguf";

    if (!await File(filePath).exists()) {
      print("Downloading Offline AI Brain...");
      if (onProgress != null) onProgress("AI Brain download shuru ho raha hai...", 0.0);
      
      await Dio().download(
        modelUrl, 
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && onProgress != null) {
            double progressValue = received / total;
            String percentage = (progressValue * 100).toStringAsFixed(0);
            // Progress bar ki value aur text dono bhej rahe hain
            onProgress("AI Brain download ho raha hai... ($percentage%)", progressValue);
          }
        }
      );
    }
    
    if (onProgress != null) {
      onProgress("AI ko memory me load kiya ja raha hai... ❤️\n(Isme thoda time lag sakta hai)", 1.0);
    }

    // 🔴 CRASH FIX: 1 second ka delay taaki 100% ka animation pura ho sake
    // aur app freeze na ho jab Llama engine load ho raha ho.
    await Future.delayed(const Duration(seconds: 1));

    try {
      engine = Llama(
        filePath,
        modelParams: ModelParams(),
        contextParams: ContextParams(), 
        samplerParams: SamplerParams(),
      );
    } catch (e) {
      print("AI Load Error: $e");
      if (onProgress != null) onProgress("AI load hone me error aayi!", 0.0);
    }
  }

  Stream<String> sendChatMessage(String userText) async* {
    String formattedPrompt = "<|im_start|>system\n$systemPrompt<|im_end|>\n<|im_start|>user\n$userText<|im_end|>\n<|im_start|>assistant\n";
    engine.setPrompt(formattedPrompt);
    while (true) {
      var (token, done) = engine.getNext();
      if (done) break;
      yield token; 
    }
  }

  Future<String?> generateRomanticPhoto(String hinglishPrompt) async {
    bool useBaseFace = true;
    String finalEnglishPrompt = "";

    if (hinglishPrompt.contains(secretCode)) {
      useBaseFace = false; 
      hinglishPrompt = hinglishPrompt.replaceAll(secretCode, "").trim();
    }

    try {
      var translation = await translator.translate(hinglishPrompt, to: 'en');
      finalEnglishPrompt = translation.text;
    } catch (e) {
      finalEnglishPrompt = hinglishPrompt; 
    }

    String? base64Image;
    if (useBaseFace) {
      try {
        var response = await http.get(Uri.parse(baseFaceUrl));
        if (response.statusCode == 200) base64Image = base64Encode(response.bodyBytes);
      } catch (e) {
        print("Face load error");
      }
    }

    String hordePrompt = useBaseFace 
        ? "1girl, exact same face as source image, beautiful, highly detailed, " + finalEnglishPrompt 
        : "highly detailed, " + finalEnglishPrompt; 

    Map<String, dynamic> payload = {
      "prompt": hordePrompt,
      "params": {"n": 1, "steps": 25, "width": 512, "height": 768},
      "nsfw": true,
      "models": ["epicrealism"]
    };

    if (useBaseFace && base64Image != null) {
      payload["source_image"] = base64Image;
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
