import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vehicle_breakdown/DashboardScreen.dart';

class OTPAuthentication extends StatefulWidget {
  @override
  _OTPAuthenticationState createState() => _OTPAuthenticationState();
}

class _OTPAuthenticationState extends State<OTPAuthentication> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  String verificationId = "";
  bool otpSent = false;
  bool isLoading = false;
  int resendToken = 0;

  void sendOTP() async {
    setState(() {
      isLoading = true;
    });
    await _auth.verifyPhoneNumber(
      phoneNumber: "+91" + phoneController.text,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        navigateToDashboard();
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() {
          isLoading = false;
        });
        print("Verification Failed: ${e.message}");
      },
      codeSent: (String verId, int? token) {
        setState(() {
          verificationId = verId;
          otpSent = true;
          isLoading = false;
          resendToken = token ?? 0;
        });
      },
      forceResendingToken: resendToken,
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
  }

  void verifyOTP() async {
    setState(() {
      isLoading = true;
    });
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      saveUserToFirestore(userCredential.user!.uid);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("OTP Verification Failed: $e");
    }
  }

  void saveUserToFirestore(String uid) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'phone': phoneController.text,
      'role': 'user',
    });
    navigateToDashboard();
  }

  void navigateToDashboard() {
    setState(() {
      isLoading = false;
    });
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => DashboardScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("OTP Authentication", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextField(controller: phoneController, decoration: InputDecoration(labelText: "Phone Number")),
              SizedBox(height: 20),
              otpSent
                  ? TextField(controller: otpController, decoration: InputDecoration(labelText: "Enter OTP"))
                  : Container(),
              SizedBox(height: 20),
              isLoading
                  ? CircularProgressIndicator()
                  : Column(
                children: [
                  otpSent
                      ? ElevatedButton(onPressed: verifyOTP, child: Text("Verify OTP"))
                      : ElevatedButton(onPressed: sendOTP, child: Text("Send OTP")),
                  otpSent
                      ? TextButton(onPressed: sendOTP, child: Text("Resend OTP"))
                      : Container(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}