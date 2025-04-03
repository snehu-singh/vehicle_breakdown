import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vehicle_breakdown/LoginScreen.dart';
import 'package:vehicle_breakdown/Mechanic/AcceptedJobScreen.dart';
import 'package:vehicle_breakdown/Mechanic/AvailableJobRequestsScreen.dart';
import 'package:vehicle_breakdown/Mechanic/SeeUpdateProfileScreen.dart';

class VerifiedMechanicDashboard extends StatefulWidget {
  const VerifiedMechanicDashboard({super.key});

  @override
  State<VerifiedMechanicDashboard> createState() => _VerifiedMechanicDashboardState();
}

class _VerifiedMechanicDashboardState extends State<VerifiedMechanicDashboard> {
  String? mechanicId;
  bool isAvailable = true;

  @override
  void initState() {
    super.initState();
    getMechanicId();
  }

  Future<void> getMechanicId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => mechanicId = user.uid);
      final doc = await FirebaseFirestore.instance.collection('mechanics').doc(mechanicId).get();
      if (doc.exists && doc.data()?['isAvailable'] != null) {
        setState(() => isAvailable = doc['isAvailable']);
      }
    }
  }

  void toggleAvailability(bool value) async {
    setState(() => isAvailable = value);


    if (mechanicId != null) {

      await FirebaseFirestore.instance.collection('mechanics').doc(mechanicId).update({
        'isAvailable': isAvailable,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mechanicId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mechanic Dashboard",style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          buildDashboardTile(
            title: isAvailable ? "Available for Jobs" : "Not Available",
            icon: isAvailable ? Icons.check_circle : Icons.remove_circle,
            color: isAvailable ? Colors.green : Colors.red,
            onTap: () => toggleAvailability(!isAvailable),
          ),
          const SizedBox(height: 20),
          buildDashboardTile(
            title: "See & Update Profile",
            icon: Icons.person,
            color: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SeeUpdateProfileScreen())),
          ),
          const SizedBox(height: 20),
          buildDashboardTile(
            title: "View Job Requests",
            icon: Icons.work,
            color: Colors.orange,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AvailableJobRequestsScreen())),
          ),
          const SizedBox(height: 20),
          buildDashboardTile(
            title: "View Accepted Jobs",
            icon: Icons.check,
            color: Colors.green,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AcceptedJobScreen())),
          ),
          const SizedBox(height: 20),
          buildDashboardTile(
            title: "Help",
            icon: Icons.help_outline,
            color: Colors.amber,
            onTap: () {}, // Placeholder for actual functionality
          ),
          const SizedBox(height: 20),
          buildDashboardTile(
            title: "Logout",
            icon: Icons.logout,
            color: Colors.redAccent,
            onTap: logout,// Placeholder for actual functionality
          ),
        ],
      ),
    );
  }
  void logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()  ));
  }

  Widget buildDashboardTile({required String title, required IconData icon, required Color color, Function()? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 2)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
