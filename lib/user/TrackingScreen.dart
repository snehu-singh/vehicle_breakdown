import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:math';

import 'package:vehicle_breakdown/user/UserDashboard.dart';

class TrackingScreen extends StatefulWidget {
  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  String status = "Request Sent";
  DocumentSnapshot? jobSnapshot;
  GoogleMapController? mapController;
  Marker? userMarker;
  Marker? mechanicMarker;
  LatLng? userLocation;
  LatLng? mechanicLocation;
  Set<Polyline> polylines = {};
  String eta = "";

  @override
  void initState() {
    super.initState();
    _trackRequestStatus();
  }

  void _trackRequestStatus() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    FirebaseFirestore.instance
        .collection('job_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;
      final data = doc.data();
      setState(() {
        jobSnapshot = doc;
        status = data['status'];
      });

      if (status == 'pending' && data['mechanicId'] != null) {
        _loadMapData(data);
      }


      if (status == 'completed') {
        _showCompletionScreen();
        _navigateToThankYouPage();
      }



    });
  }
  void _showCompletionScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Service Completed", style: TextStyle(color: Colors.green)),
          content: Text("Your service request has been successfully completed."),
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: TextStyle(color: Colors.deepPurple)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToThankYouPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => UserDashboard()),
    );

  }
  Future<void> _loadMapData(Map<String, dynamic> jobData) async {
    userLocation = LatLng(
      jobData['location']['latitude'],
      jobData['location']['longitude'],
    );

    final mechanicDoc = await FirebaseFirestore.instance
        .collection('mechanics')
        .doc(jobData['mechanicId'])
        .get();
    final mechanicData = mechanicDoc.data()!;

    mechanicLocation = LatLng(
      mechanicData['latitude'],
      mechanicData['longitude'],
    );
    if (!mounted) return;

    // Add markers
    setState(() {
      userMarker = Marker(
        markerId: MarkerId("user"),
        position: userLocation!,
        infoWindow: InfoWindow(title: "Your Location"),
      );

      mechanicMarker = Marker(
        markerId: MarkerId("mechanic"),
        position: mechanicLocation!,
        infoWindow: InfoWindow(title: "Mechanic Location"),
      );
    });

    // Polyline logic — basic straight line (replace with Google Directions API for real ETA and route)
    setState(() {
      polylines = {
        Polyline(
          polylineId: PolylineId("route"),
          color: Colors.blue,
          width: 4,
          points: [mechanicLocation!, userLocation!],
        )
      };
      eta = _calculateETA(mechanicLocation!, userLocation!).toStringAsFixed(1) + " mins";
    });
  }

  double _calculateETA(LatLng from, LatLng to) {
    final distance = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    ) / 1000; // km
    const speed = 30; // assume avg speed in km/h
    return (distance / speed) * 60; // in minutes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Request Tracking", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => _trackRequestStatus(),  // Refresh the status
          )
        ],
      ),
      body: status != 'pending'
          ? _buildStatusScreen()
          : Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: userLocation ?? LatLng(0, 0),
                zoom: 14,
              ),
              markers: {if (userMarker != null) userMarker!, if (mechanicMarker != null) mechanicMarker!},
              polylines: polylines,
              onMapCreated: (controller) {
                mapController = controller;
              },
            ),
          ),
          if (jobSnapshot != null)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('mechanics').doc(jobSnapshot!['mechanicId']).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                final data = snapshot.data!.data() as Map<String, dynamic>;
                return Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("🧑 Mechanic: ${data['name']}", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("📞 Phone: ${data['phone']}"),
                      Text("📍 Address: ${data['address']}"),
                      Text("🛠️ Services: ${(data['services'] as List).join(', ')}"),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => launchUrl(Uri.parse("tel:${data['phone']}")),
                            icon: Icon(Icons.call, color: Colors.white),
                            label: Text("Call"),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, backgroundColor: Colors.green, // button text color
                            ),
                          ),
                          SizedBox(width: 10),
                          Text("ETA: $eta"),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Status: $status", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          if (status == 'Request Sent')
            CircularProgressIndicator(),
          if (status == 'Finding Nearby Mechanics')
            Text("📡 Looking for nearby mechanics...", style: TextStyle(fontSize: 16)),
          if (status == 'Mechanic Assigned')
            Text("🔧 Mechanic is being assigned...", style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
