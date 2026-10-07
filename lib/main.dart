import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// 🌟 YAHAN TERI DONO FILES LINK HO GAYI HAIN 🌟
import 'ai_brain.dart';
import 'payment_api.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Edrol AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => DownloadModelScreen(),
        '/chatScreen': (context) => const DummyChatScreen(), 
      },
    );
  }
}

class DownloadModelScreen extends StatefulWidget {
  @override
  _DownloadModelScreenState createState() => _DownloadModelScreenState();
}

class _DownloadModelScreenState extends State<DownloadModelScreen> {
  bool isDownloading = false;
  double downloadProgress = 0.0;
  String statusText = "Checking AI Engines...";

  final List<Map<String, String>> aiModels = [
    {
      "fileName": "qwen_chat.gguf",
      "url": "https://huggingface.co/Edrrt/edrol-ai-engine/resolve/main/qwen1_5-0_5b-chat-q5_k_m.gguf",
      "displayName": "Chat Engine (459 MB)"
    },
    {
      "fileName": "epicrealism_photo.safetensors",
      "url": "https://huggingface.co/Edrrt/edrol-ai-engine/resolve/main/epicrealism_naturalSinRC1VAE.safetensors",
      "displayName": "Photo Engine (2.1 GB)"
    },
    {
      "fileName": "animatelcm_video.ckpt",
      "url": "https://huggingface.co/wangfuyun/AnimateLCM/resolve/main/AnimateLCM_sd15_t2v.ckpt",
      "displayName": "Video Engine (1.8 GB)"
    }
  ];

  @override
  void initState() {
    super.initState();
    _downloadAllModels();
  }

  Future<void> _downloadAllModels() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    Dio dio = Dio();

    for (int i = 0; i < aiModels.length; i++) {
      String savePath = "${appDocDir.path}/${aiModels[i]['fileName']}";
      File modelFile = File(savePath);

      if (!await modelFile.exists()) {
        setState(() {
          isDownloading = true;
          statusText = "Downloading ${aiModels[i]['displayName']}...\n(One-time setup)";
          downloadProgress = 0.0;
        });

        try {
          await dio.download(
            aiModels[i]['url']!,
            savePath,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                setState(() {
                  downloadProgress = received / total;
                });
              }
            },
          );
        } catch (e) {
          setState(() {
            statusText = "Download Failed for ${aiModels[i]['displayName']}. Check Internet.";
            isDownloading = false;
          });
          return; 
        }
      }
    }

    if (mounted) {
      setState(() {
        isDownloading = false;
        statusText = "All AI Engines Ready!";
      });

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/chatScreen'); 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.memory, size: 80, color: Colors.pinkAccent),
              const SizedBox(height: 30),
              Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (isDownloading) ...[
                LinearProgressIndicator(
                  value: downloadProgress,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
                  minHeight: 8,
                ),
                const SizedBox(height: 10),
                Text(
                  "${(downloadProgress * 100).toStringAsFixed(1)}%",
                  style: const TextStyle(color: Colors.white70),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class DummyChatScreen extends StatelessWidget {
  const DummyChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edrol AI Chat")),
      body: const Center(
        child: Text(
          "Welcome to Uncensored Edrol AI!",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
