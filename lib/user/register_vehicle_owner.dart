import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:vehicle_breakdown/user/UserDashboard.dart';

class RegisterVehicleOwnerScreen extends StatefulWidget {
  @override
  _RegisterVehicleOwnerScreenState createState() => _RegisterVehicleOwnerScreenState();
}

class _RegisterVehicleOwnerScreenState extends State<RegisterVehicleOwnerScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String verificationId = "";
  bool isOtpSent = false;

  void sendOtp() async {
    String phone = "+91${phoneController.text.trim()}";
    if (phone.length != 13) { // +91 included, total should be 13 characters
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enter a valid 10-digit phone number")));
      return;
    }
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          verifyAndSave("user");
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

  void verifyOtp(String otp) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      verifyAndSave("user");
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
        "uid": user.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registered Successfully")));
        Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserDashboard()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register - Vehicle Owner"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10, // Ensuring user enters only 10 digits
                decoration: InputDecoration(
                  labelText: "Phone Number (10 digits)",
                  border: OutlineInputBorder(),
                  counterText: "", // Hide counter below the text field
                ),
              ),
              SizedBox(height: 20),
              if (isOtpSent) PinCodeTextField(
                appContext: context,
                length: 6,
                onChanged: (value) {},
                onCompleted: verifyOtp,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(5),
                  fieldHeight: 50,
                  fieldWidth: 40,
                  activeFillColor: Colors.white,
                  inactiveFillColor: Colors.deepPurple[50],
                  selectedFillColor: Colors.deepPurple[100],
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: isOtpSent ? null : sendOtp,
                child: Text(isOtpSent ? "OTP Sent" : "Send OTP"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.deepPurple,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
