import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vehicle_breakdown/Mechanic/mechanic_dashboard.dart';
import 'package:vehicle_breakdown/user/UserDashboard.dart';
import 'LoginScreen.dart';
import 'choose_registration_role.dart';

class AuthSelectionScreen extends StatefulWidget {
  @override
  _AuthSelectionScreenState createState() => _AuthSelectionScreenState();
}

class _AuthSelectionScreenState extends State<AuthSelectionScreen> {
  bool isChecking = true;

  @override
  void initState() {
    super.initState();
    checkIfLoggedIn();
  }

  void checkIfLoggedIn() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        if (doc.exists && doc['role'] != null) {
          String role = doc['role'];
          if (role == "service_provider") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => MechanicDashboard()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => UserDashboard()),
            );
          }
          return;
        }
      } catch (e) {
        debugPrint("Error checking role: $e");
      }
    }

    // If not logged in or error occurred
    setState(() {
      isChecking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple, // Attractive purple theme
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome to Vehicle Breakdown Service",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple[300], // Lighter shade of purple for contrast
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                },
                child: Text("Login"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, minimumSize: Size(200, 50),
                  backgroundColor: Colors.deepPurple, // For better readability
                  shape: RoundedRectangleBorder( // Rounded corners for a modern look
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChooseRegistrationRole()));
                },
                child: Text("Register"),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.deepPurple, minimumSize: Size(200, 50),
                  backgroundColor: Colors.purple[100], // Text color matching the darker purple
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
