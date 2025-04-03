import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Same imports...

class RegisterServiceProviderScreen extends StatefulWidget {
  @override
  _RegisterServiceProviderScreenState createState() => _RegisterServiceProviderScreenState();
}

class _RegisterServiceProviderScreenState extends State<RegisterServiceProviderScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String verificationId = "";
  bool isOtpSent = false;

  void sendOtp() async {
    String phone = "+91${phoneController.text.trim()}";
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          verifyAndSave("service_provider");
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
        },
        codeSent: (String verId, int? resendToken) {
          setState(() {
            verificationId = verId;
            isOtpSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verId) {
          verificationId = verId;
        },
        timeout: Duration(seconds: 60),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OTP send failed.")));
    }
  }

  void verifyOtp() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );
      await _auth.signInWithCredential(credential);
      verifyAndSave("service_provider");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid OTP")));
    }
  }

  void verifyAndSave(String role) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "role": role,
        "profile_completed": false,
        "uid": user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registered Successfully")));
      Navigator.pushReplacementNamed(context, "/serviceProviderDashboard");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register - Service Provider")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: "Owner Name")),
            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: "Phone Number")),
            if (isOtpSent) TextField(controller: otpController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Enter OTP")),
            SizedBox(height: 20),
            ElevatedButton(onPressed: isOtpSent ? verifyOtp : sendOtp, child: Text(isOtpSent ? "Verify OTP" : "Send OTP")),
          ],
        ),
      ),
    );
  }
}
