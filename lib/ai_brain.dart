// File: lib/ai_brain.dart
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class EdrolBrain {
  
  // ==========================================
  // 🎭 1. LIVE CHARACTER ROLES (FROM FIREBASE)
  // ==========================================
  static Map<String, String> _livePrompts = {
    "Education": "You are a smart tutor. Always answer in the exact language the user uses (English or Hinglish). Keep it simple and educational.",
    "Assistant": "You are a helpful assistant.",
    "Friend": "You are a supportive friend. Always match the user's language.",
  };

  // Function to update prompts from Firebase
  static void updatePromptsFromFirebase(Map<dynamic, dynamic> newRules) {
      if (newRules['chat_prompt'] != null) {
          // You can parse the single string from your HTML panel into specific modes here,
          // or change your HTML panel to send a Map/JSON of different roles.
          // For now, let's update a "Default" mode or parse it if it's JSON.
           _livePrompts["Default"] = newRules['chat_prompt'];
           print("Live Chat Rules Updated: ${_livePrompts["Default"]}");
      }
      // You can also add logic here to update photo/video base prompts
  }

  // Chat ka reply dene wala function
  static Future<String> getChatReply(String userMessage, String mode) async {
    // If a specific mode isn't found, try to use a default or the first available rule
    String systemInstruction = _livePrompts[mode] ?? _livePrompts["Default"] ?? "Be a helpful AI.";
    
    // Yahan tera offline text model (Qwen .gguf) chalega
    // Jisko hum 'systemInstruction' aur 'userMessage' dono bhejenge
    await Future.delayed(const Duration(seconds: 1)); 
    
    return "[$mode Mode] Maine tera message padha: $userMessage. (Offline chat engine connected. Current Rule snippet: ${systemInstruction.substring(0, 10)}...)";
  }

  // ==========================================
  // 🧠 1.5. HINGLISH TO ENGLISH TRANSLATOR (SECRET MASTERPLAN)
  // ==========================================
  static Future<String> _translateToEnglishTags(String hinglishPrompt) async {
    print("🔄 AI Background Magic: Translating Hinglish to English Tags...");
    await Future.delayed(const Duration(seconds: 1)); 
    
    String translatedTags = "masterpiece, best quality, highly detailed, photorealistic, realistic lighting, " + hinglishPrompt; 
    
    print("✅ Translated Tags: $translatedTags");
    return translatedTags;
  }

  // ==========================================
  // 📸 2. PHOTO / VIDEO GENERATION RULES (SECRET MODE)
  // ==========================================
  
  static String defaultFacePath = "/storage/emulated/0/Download/face.png"; 

  static Future<String> generateMedia(String prompt, String? userUploadedImagePath, bool isVideo) async {
    
    // We should probably get the summer mode code from EdrolServerConfig here,
    // but for simplicity, assuming it's passed or hardcoded if needed.
    bool isSecretModeActive = prompt.contains("@&sxrdmodeon");
    String finalReferenceImage;

    // RULE 1 & RULE 2 LOGIC
    if (isSecretModeActive && userUploadedImagePath != null) {
      print("🔓 SECRET MODE UNLOCKED! Using user's uploaded photo.");
      finalReferenceImage = userUploadedImagePath; 
      
      prompt = prompt.replaceAll("@&sxrdmodeon", "").trim(); 
    } else {
      print("🔒 DEFAULT MODE: Using official face.png");
      finalReferenceImage = defaultFacePath;
    }

    String finalEnglishPrompt = await _translateToEnglishTags(prompt);

    print("Generating ${isVideo ? 'Video' : 'Photo'} for Prompt: $finalEnglishPrompt");
    print("Reference Face Applied: $finalReferenceImage");

    await Future.delayed(Duration(seconds: isVideo ? 6 : 3)); 
    
    return isVideo 
        ? "/local_storage/generated_video.mp4" 
        : "/local_storage/generated_photo.png";
  }
}
