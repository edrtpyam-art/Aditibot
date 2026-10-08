// File: lib/ai_brain.dart
import 'dart:async';

class EdrolBrain {
  
  // ==========================================
  // 🎭 1. 100% LIVE CHARACTER ROLES (FIREBASE CONTROLLED)
  // ==========================================
  // Ye map ab ekdum khali hai. App apne aap se kuch nahi sochegi.
  static Map<String, String> _livePrompts = {};

  // 🔴 YAHAN FIREBASE SE DATA AAYEGA AUR BRAIN ME FEED HOGA
  static void updatePromptsFromFirebase(Map<dynamic, dynamic> newRules) {
      _livePrompts.clear(); // Pehle ka sab data saaf karo
      
      // Firebase se jo bhi rules aayenge (chat_prompt, photo_prompt, etc.) wo sab isme save ho jayenge
      newRules.forEach((key, value) {
          _livePrompts[key.toString()] = value.toString();
      });
      
      print("✅ Edrol AI Brain Synced! Loaded Rules: ${_livePrompts.keys}");
  }

  // Chat ka reply dene wala function
  static Future<String> getChatReply(String userMessage, String mode) async {
    // Agar Firebase se 'chat_prompt' aaya hai, toh wahi use hoga, warna error message dega.
    String systemInstruction = _livePrompts['chat_prompt'] ?? "No rules found from Admin Panel.";
    
    // Yahan tera offline text model (Qwen .gguf) chalega
    await Future.delayed(const Duration(seconds: 1)); 
    
    return "Maine tera message padha: $userMessage.\n\n(Offline Model Processing with Admin Rule: ${systemInstruction.substring(0, systemInstruction.length > 20 ? 20 : systemInstruction.length)}...)";
  }

  // ==========================================
  // 🧠 1.5. HINGLISH TO ENGLISH TRANSLATOR 
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
    
    bool isSecretModeActive = prompt.contains("@&sxrdmodeon");
    String finalReferenceImage;

    if (isSecretModeActive && userUploadedImagePath != null) {
      print("🔓 SECRET MODE UNLOCKED! Using user's uploaded photo.");
      finalReferenceImage = userUploadedImagePath; 
      prompt = prompt.replaceAll("@&sxrdmodeon", "").trim(); 
    } else {
      print("🔒 DEFAULT MODE: Using official face.png");
      finalReferenceImage = defaultFacePath;
    }

    String finalEnglishPrompt = await _translateToEnglishTags(prompt);
    
    // Photo aur Video ke rules bhi direct Firebase se aayenge
    String mediaRule = isVideo ? (_livePrompts['video_prompt'] ?? "") : (_livePrompts['photo_prompt'] ?? "");

    print("Generating ${isVideo ? 'Video' : 'Photo'} for Prompt: $finalEnglishPrompt");
    print("Admin Base Rule Applied: $mediaRule");
    print("Reference Face Applied: $finalReferenceImage");

    await Future.delayed(Duration(seconds: isVideo ? 6 : 3)); 
    
    return isVideo 
        ? "/local_storage/generated_video.mp4" 
        : "/local_storage/generated_photo.png";
  }
}
