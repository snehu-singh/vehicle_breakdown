import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  String verificationId = "";
  bool isOtpSent = false;
  String selectedRole = "user"; // Default role: Normal User
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void sendOtp() async {
    String phoneNumber = "+91${phoneController.text.trim()}";
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${e.message}")),
          );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send OTP. Please try again.")),
      );
    }
  }

  void verifyOtp() async {
    String otp = otpController.text.trim();
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Store user details in Firestore
      await FirebaseFirestore.instance.collection("users").doc(userCredential.user!.uid).set({
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "uid": userCredential.user!.uid,
        "role": selectedRole, // Store user role
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration Successful!")),
      );

      // Navigate based on role
      if (selectedRole == "service_provider") {
        Navigator.pushReplacementNamed(context, "/serviceProviderDashboard");
      } else {
        Navigator.pushReplacementNamed(context, "/userDashboard");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid OTP. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Full Name"),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: "Enter Phone Number"),
            ),

            // **Role Selection**
            Column(
              children: [
                ListTile(
                  title: Text("Vehicle Owner"),
                  leading: Radio(
                    value: "user",
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value.toString();
                      });
                    },
                  ),
                ),
                ListTile(
                  title: Text("Service Provider"),
                  leading: Radio(
                    value: "service_provider",
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setState(() {
                        selectedRole = value.toString();
                      });
                    },
                  ),
                ),
              ],
            ),

            if (isOtpSent)
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Enter OTP"),
              ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: isOtpSent ? verifyOtp : sendOtp,
              child: Text(isOtpSent ? "Verify OTP" : "Send OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
