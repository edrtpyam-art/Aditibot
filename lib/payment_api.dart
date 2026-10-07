// File: lib/payment_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentAPI {
  // Tera Vercel backend URL (Jahan tera admin panel hoga)
  static const String serverUrl = "https://aditibot.vercel.app/api";

  // 1. Live Plan Check Karne Ka Function
  static Future<Map<String, dynamic>> checkUserSubscription(String userId) async {
    try {
      // App tere Vercel server se puchegi ki is user ka kya status hai
      final response = await http.post(
        Uri.parse("$serverUrl/verify-license"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"user_id": userId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
        // Ye return karega: { "is_active": true, "plan": "Wife Mode", "expiry": "1 hour left" }
      } else {
        return {"is_active": false, "message": "Server Down!"};
      }
    } catch (e) {
      return {"is_active": false, "message": "Internet Error"};
    }
  }

  // 2. Live Pricing List Lane Ka Function (Taaki tu admin panel se price badal sake)
  static Future<List<dynamic>> getLivePlans() async {
    try {
      final response = await http.get(Uri.parse("$serverUrl/get-plans"));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['plans'];
        // Ye Vercel se list layega: [ {name: "GF Mode", price: 29, duration: "1 Day"} ]
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
