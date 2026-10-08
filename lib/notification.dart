import 'package:flutter/material.dart';
import 'main.dart'; // 🔴 EdrolServerConfig read karne ke liye

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Updates & Offers", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      // 🔴 TicbullConfig ki jagah ab EdrolServerConfig use hoga
      body: EdrolServerConfig.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 80, color: Colors.grey[800]),
                  const SizedBox(height: 20),
                  const Text(
                    "No new notifications yet!",
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: EdrolServerConfig.notifications.length,
              itemBuilder: (context, index) {
                var notif = EdrolServerConfig.notifications[index];
                return Card(
                  color: const Color(0xFF1A1A1A),
                  clipBehavior: Clip.antiAlias, // Image ke corners round karne ke liye
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.grey[850]!),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🖼️ LIVE IMAGE BANNER: Agar admin panel se image bheji hai toh yahan dikhegi
                      if (notif['image_url'] != null && notif['image_url'].toString().isNotEmpty)
                        Image.network(
                          notif['image_url'],
                          width: double.infinity,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(), // Agar image load na ho toh error nahi aayega
                        ),
                      
                      // 📝 TEXT MESSAGE & DETAILS
                      ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.pinkAccent.withOpacity(0.2),
                          child: const Icon(Icons.campaign, color: Colors.pinkAccent),
                        ),
                        title: Text(
                          notif['title'] ?? "Notice",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            notif['message'] ?? "",
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        trailing: Text(
                          notif['date'] ?? "",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
