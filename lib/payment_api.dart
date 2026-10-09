import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentController {
  final _dbRef = FirebaseDatabase.instance.ref("payment_settings");

  // 1. FREE TRIAL LOGIC (App install hote hi chalega)
  Future<void> checkAndApplyFreeTrial() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isNewUser = prefs.getBool('is_new_user') ?? true;

    if (isNewUser) {
      final snapshot = await _dbRef.child("free_trial_hours").get();
      int trialHours = (snapshot.value as int?) ?? 24; // Default 24 ghante

      DateTime expiryDate = DateTime.now().add(Duration(hours: trialHours));
      await prefs.setString('expiry_date', expiryDate.toIso8601String());
      await prefs.setBool('is_new_user', false); 
      print("Free Trial Activated for $trialHours hours!");
    }
  }

  // 2. CHECK PAYWALL & SHOW POPUP
  Future<void> showPaywallIfNeeded(BuildContext context) async {
    final snapshot = await _dbRef.get();
    
    if (snapshot.exists) {
      var data = snapshot.value as Map<dynamic, dynamic>;
      
      // Kill Switch: Agar admin ne payment off ki hai, to free chalega
      bool isPaymentEnabled = data['is_payment_enabled'] ?? true;
      if (!isPaymentEnabled) return; 

      Map<dynamic, dynamic> plans = data['plans'] ?? {};
      String paymentLink = data['payment_link'] ?? ""; // Aapka Cosmofeed Link

      _showPlansBottomSheet(context, plans, paymentLink);
    }
  }

  // 3. UI: DYNAMIC PLANS BOTTOM SHEET
  void _showPlansBottomSheet(BuildContext context, Map<dynamic, dynamic> plans, String paymentLink) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false, // Bina pay kiye back nahi ja payega
      backgroundColor: Colors.grey.shade900,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Text("Unlock Aditi ❤️", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Your free trial has ended. Choose a plan to continue chatting.", 
                   textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              SizedBox(height: 20),
              
              Expanded(
                child: ListView.builder(
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    String key = plans.keys.elementAt(index);
                    var plan = plans[key];

                    return Card(
                      color: Colors.pink.shade900,
                      child: ListTile(
                        title: Text(plan['name'], style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text("Validity: ${plan['validity_hours']} Hours", style: TextStyle(color: Colors.white70)),
                        trailing: Text(plan['price'], style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                        onTap: () {
                          // Plan par click karte hi gateway open hoga
                          _openPaymentGateway(paymentLink);
                        },
                      ),
                    );
                  },
                ),
              ),
              
              // Temporary button for Testing/Manual Approval (Aap isko baad me hata sakte hain)
              TextButton(
                onPressed: () => _manualUnlockForTesting(context), 
                child: Text("I have paid (Verify)", style: TextStyle(color: Colors.grey))
              )
            ],
          ),
        );
      }
    );
  }

  // 4. URL LAUNCHER (Cosmofeed open karne ke liye)
  Future<void> _openPaymentGateway(String url) async {
    Uri paymentUri = Uri.parse(url);
    if (await canLaunchUrl(paymentUri)) {
      await launchUrl(paymentUri, mode: LaunchMode.externalApplication); // Browser me khulega
    } else {
      print("Could not open payment link.");
    }
  }

  // 5. TEST/MANUAL UNLOCK (Kyuki external link direct app ko nahi batata ki payment hui ya nahi)
  Future<void> _manualUnlockForTesting(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime newExpiry = DateTime.now().add(Duration(hours: 24)); // 24 ghante add kar diye
    await prefs.setString('expiry_date', newExpiry.toIso8601String());
    
    Navigator.pop(context); // Popup band
  }
}
