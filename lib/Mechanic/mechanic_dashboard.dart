import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'mechanic_profile_form.dart';
import 'verified_mechanic_dashboard.dart';

class MechanicDashboard extends StatefulWidget {
  @override
  _MechanicDashboardState createState() => _MechanicDashboardState();
}

class _MechanicDashboardState extends State<MechanicDashboard> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool isLoading = true;
  bool? isVerified;
  bool hasProfile = false;
  bool isSubmitted = false;
  @override
  void initState() {
    super.initState();
    checkMechanicProfile();
  }

  Future<void> checkMechanicProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final doc = await _firestore.collection('mechanics').doc(uid).get();
      if (doc.exists) {
        hasProfile = true;
        // new flag
        isVerified = doc.data()?['isVerified'] ?? false;
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator());

    if (!hasProfile) {
      return MechanicProfileForm();
    }

    if (isSubmitted || (isVerified != null && !isVerified!))  {
      return Scaffold(
        appBar: AppBar(title: Text("Mechanic Dashboard")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user, size: 100, color: Colors.orange),
              SizedBox(height: 20),
              Text(
                "Your details are being verified.",
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 10),
              Text("Please check back soon."),
            ],
          ),
        ),
      );
    }

    // Verified Mechanic Dashboard
    return VerifiedMechanicDashboard();
  }
}
