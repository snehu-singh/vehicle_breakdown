import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vehicle_breakdown/Mechanic/AcceptedJobScreen.dart';

class AvailableJobRequestsScreen extends StatefulWidget {
  @override
  _AvailableJobRequestsScreenState createState() =>
      _AvailableJobRequestsScreenState();
}

class _AvailableJobRequestsScreenState
    extends State<AvailableJobRequestsScreen> {
  Position? mechanicPosition;
  final mechanicId = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _getCurrentPosition();
  }

  Future<void> _getCurrentPosition() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      mechanicPosition = position;
    });

    print("📍 Mechanic Location: ${position.latitude}, ${position.longitude}");
  }

  double _calculateDistance(lat, lng) {
    if (mechanicPosition == null) return double.infinity;
    return Geolocator.distanceBetween(
      mechanicPosition!.latitude,
      mechanicPosition!.longitude,
      lat,
      lng,
    );
  }

  Future<void> acceptJob(String requestId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance
          .collection('job_requests')
          .doc(requestId)
          .update({
        'mechanicId': mechanicId,
        'status': 'pending', // job is now accepted
      });

      print("✅ Job $requestId accepted by $mechanicId");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AcceptedJobScreen(),
        ),
      );
    } catch (e) {
      print("❌ Error accepting job: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mechanicPosition == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Available Jobs")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('job_requests')
            .where('status', isEqualTo: 'unassigned')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          final jobs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            if (data['location'] == null ||
                data['location']['latitude'] == null ||
                data['location']['longitude'] == null ||
                data['sentTo'] == null) {
              print("⚠️ Skipping job ${doc.id} due to missing location/sentTo");
              return false;
            }

            final isInSentList = data['sentTo'].contains(mechanicId);
            final lat = data['location']['latitude'];
            final lng = data['location']['longitude'];
            final distance = _calculateDistance(lat, lng);

            print("🔎 Checking job ${doc.id} | Distance: ${distance / 1000} km");

            return isInSentList && distance <= 15000;
          }).toList();

          if (jobs.isEmpty)
            return Center(child: Text("No nearby job requests."));

          return ListView(
            children: jobs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final distance = (_calculateDistance(
                  data['location']['latitude'],
                  data['location']['longitude']) /
                  1000)
                  .toStringAsFixed(2);

              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['userName'] ?? 'No Name'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Issue: ${data['issue']}"),
                      Text("Distance: $distance km"),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => acceptJob(doc.id, data),
                    child: Text("Accept Job"),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
