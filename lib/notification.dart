import 'package:flutter/material.dart';
import 'main.dart'; // TicbullConfig ko read karne ke liye

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
      body: TicbullConfig.notifications.isEmpty
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
              itemCount: TicbullConfig.notifications.length,
              itemBuilder: (context, index) {
                var notif = TicbullConfig.notifications[index];
                return Card(
                  color: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.grey[850]!),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
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
                );
              },
            ),
    );
  }
}
