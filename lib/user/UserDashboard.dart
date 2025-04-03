import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vehicle_breakdown/LoginScreen.dart';
import 'package:vehicle_breakdown/user/SendRequestScreen.dart';
import 'package:vehicle_breakdown/user/maps_screen.dart';
import 'package:vehicle_breakdown/user/saved_contacts_screen.dart';

class UserDashboard extends StatefulWidget {
  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  String userName = "User";

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  void fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc['name'] != null) {
        setState(() {
          userName = userDoc['name'];
        });
      }
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text("Dashboard", style: TextStyle(color: Colors.white, fontSize: 20)),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome, $userName!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  buildDashboardCard(
                    title: "Find Nearby Mechanics",
                    icon: Icons.location_on,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SendRequestScreen()));
                    },
                  ),
                  SizedBox(height: 20),
                  buildDashboardCard(
                    title: "View Services",
                    icon: Icons.build,
                    color: Colors.teal,
                    onTap: () {
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => ServicesScreen()));
                    },
                  ),
                  SizedBox(height: 20),
                  buildDashboardCard(
                    title: "Help",
                    icon: Icons.help_outline,
                    color: Colors.amber,
                    onTap: () {
                      // Implement Help Screen Navigation
                    },
                  ),
                  SizedBox(height: 20),
                  buildDashboardCard(
                    title: "Logout",
                    icon: Icons.logout,
                    color: Colors.redAccent,
                    onTap: logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDashboardCard({required String title, required IconData icon, required Color color, required Function() onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }
}
