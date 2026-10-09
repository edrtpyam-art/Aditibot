import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart'; // 🔴 Firebase add kiya

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔴 Admin Panel ka Firebase reference jahan notifications save honge
    final DatabaseReference _notifRef = FirebaseDatabase.instance.ref("admin_controls/notifications");

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Updates & Offers", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
      ),
      // 🔴 StreamBuilder lagaya taaki real-time (live) update mile
      body: StreamBuilder(
        stream: _notifRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          
          // Data load ho raha hai
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
          }

          // Agar data empty hai ya Admin ne kuch nahi bheja
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return _buildEmptyState();
          }

          // Firebase se data parse karna
          var data = snapshot.data!.snapshot.value;
          List<Map<dynamic, dynamic>> notifications = [];

          if (data is List) {
            // Agar Firebase ne List ke format me data bheja
            for (var item in data) {
              if (item != null) notifications.add(Map<dynamic, dynamic>.from(item));
            }
          } else if (data is Map) {
            // Agar Firebase ne Map (Keys) ke format me data bheja
            data.forEach((key, value) {
              notifications.add(Map<dynamic, dynamic>.from(value));
            });
          }

          // Sabse naya message sabse upar dikhane ke liye reverse kar diya
          notifications = notifications.reversed.toList();

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          // 🔴 Aapka UI yahan se waisa hi hai, bas ab data Firebase se aa raha hai
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              var notif = notifications[index];
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
                        notif['image_url'].toString(),
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(), 
                      ),
                    
                    // 📝 TEXT MESSAGE & DETAILS
                    ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.pinkAccent.withOpacity(0.2),
                        child: const Icon(Icons.campaign, color: Colors.pinkAccent),
                      ),
                      title: Text(
                        notif['title']?.toString() ?? "Notice",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          notif['message']?.toString() ?? "",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      trailing: Text(
                        notif['date']?.toString() ?? "",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Khali screen ka design
  Widget _buildEmptyState() {
    return Center(
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
    );
  }
}
