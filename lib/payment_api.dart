// File: lib/payment_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PaymentAPI {
  // 🔴 Tera naya Firebase Database URL (Vercel hata diya)
  static const String dbUrl = "https://edro-e45a8-default-rtdb.firebaseio.com/edrol_config/payment_system.json";

  // 1. Live Plan Check Karne Ka Function (Local Sub + Firebase Status)
  static Future<Map<String, dynamic>> checkUserSubscription() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool hasActiveSub = prefs.getBool('has_active_sub') ?? false;

      // Agar user ne pay kar diya hai (Premium member hai)
      if (hasActiveSub) {
        return {"is_active": true, "message": "Premium Unlocked"};
      }

      // Varna Firebase se check karo ki Admin ne payment ON rakhi hai ya OFF
      final response = await http.get(Uri.parse(dbUrl));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        bool isSystemActive = data['is_active'] ?? false;
        
        return {
          "is_active": isSystemActive, // Agar false hai, matlab app free chalne do
          "message": isSystemActive ? "Trial Expired! Upgrade needed." : "Free Mode Active"
        };
      }
      return {"is_active": false, "message": "Server error!"};
    } catch (e) {
      return {"is_active": false, "message": "Internet Error"};
    }
  }

  // 2. Live Pricing List Lane Ka Function (Direct Firebase se)
  static Future<List<dynamic>> getLivePlans() async {
    try {
      final response = await http.get(Uri.parse(dbUrl));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data != null && data['plans'] != null) {
          return data['plans']; // Ye Firebase se direct [ {name: "PRO", price: "₹499"} ] return karega
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
