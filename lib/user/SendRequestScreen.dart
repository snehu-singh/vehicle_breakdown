import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vehicle_breakdown/user/TrackingScreen.dart';

class SendRequestScreen extends StatefulWidget {
  @override
  _SendRequestScreenState createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  final TextEditingController _issueController = TextEditingController();
  bool _isSending = false;

  Map<String, bool> selectedServices = {
    'Puncture': false,
    'Garage': false,
    'Battery Jumpstart': false,
    'Towing': false,
    'Oil Change': false,
  };

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next step?
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      await Geolocator.openAppSettings();
    }

    // Permission is granted, continue with location updates
  }

  Future<void> _sendRequest() async {
    setState(() => _isSending = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      final snapshot = await FirebaseFirestore.instance
          .collection('mechanics')
          .where('isVerified', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .get();

      List<Map<String, dynamic>> eligibleMechanics = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final lat = data['latitude'];
        final lng = data['longitude'];

        if (lat == null || lng == null) continue;

        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          lat.toDouble(),
          lng.toDouble(),
        ) / 1000;

        if (distance <= 15) {
          eligibleMechanics.add({
            'id': doc.id,
            'distance': distance,
          });
        }
      }

      if (eligibleMechanics.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No mechanics available within 15 km.")));
        setState(() => _isSending = false);
        return;
      }

      await FirebaseFirestore.instance.collection('job_requests').add({
        'userId': user.uid,
        'userName': user.displayName ?? '',
        'userPhone': user.phoneNumber ?? '',
        'issue': _issueController.text.trim(),
        'services': selectedServices.entries.where((e) => e.value).map((e) => e.key).toList(),
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'status': 'unassigned',
        'mechanicId': null,
        'timestamp': FieldValue.serverTimestamp(),
        'sentTo': eligibleMechanics.map((m) => m['id']).toList(),
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Request sent to nearby mechanics.")));
      _issueController.clear();
      selectedServices.updateAll((key, value) => false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TrackingScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Send Service Request", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _issueController,
              decoration: InputDecoration(
                labelText: "Describe your issue",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description, color: Colors.deepPurple),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Select Services Needed:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
              ),
            ),
            Wrap(
              spacing: 10,
              children: selectedServices.keys.map((service) => FilterChip(
                label: Text(service, style: TextStyle(color: Colors.white)),
                selected: selectedServices[service]!,
                onSelected: (bool selected) {
                  setState(() {
                    selectedServices[service] = selected;
                  });
                },
                backgroundColor: Colors.deepPurple,
                selectedColor: Colors.green.shade800,
                checkmarkColor: Colors.white,
              )).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isSending ? null : _sendRequest,
              icon: Icon(Icons.send, color: Colors.white),
              label: Text(_isSending ? "Sending..." : "Send Request", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
