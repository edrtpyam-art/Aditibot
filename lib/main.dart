import 'package:flutter/material.dart';
import 'dart:async'; // Animation aur timer ke liye

void main() {
  runApp(EdrolAIApp());
}

class EdrolAIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Edrol AI',
      // Premium Pink Theme Setup
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A), // Dark premium background
        primaryColor: Colors.pinkAccent,
        colorScheme: ColorScheme.dark(
          primary: Colors.pinkAccent,
          secondary: Colors.pink,
        ),
      ),
      home: SplashScreen(), // App shuru hote hi pehle Splash Screen aayegi
    );
  }
}

// ==========================================
// SPLASH SCREEN (ANIMATED)
// ==========================================
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // Animation Logic (Fade In)
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // 4 second baad ChatScreen par chala jayega
    Timer(const Duration(seconds: 4), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => ChatScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Deep black background
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main Logo (31480.png)
              Image.asset(
                'assets/images/logo.png', // Tera wo professional logo
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 20),
              
              // App Name
              const Text(
                'EDROL AI',
                style: TextStyle(
                  color: Colors.pinkAccent,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              
              // Tagline
              const Text(
                'All-In-One Open Chat',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              
              const SizedBox(height: 100),
              
              // Powered By Section (Neeche)
              Column(
                children: [
                  const Text(
                    'POWERED BY',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // DragoEagle ka chota logo
                      ClipOval(
                        child: Image.asset(
                          'assets/images/logo2.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'DRAGOEAGLE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// MAIN CHAT SCREEN (Placeholder)
// ==========================================
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edrol AI', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 1,
        shadowColor: Colors.pinkAccent,
      ),
      body: Center(
        child: Text(
          "Yahan teri 459MB GGUF wali chat aayegi!",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
