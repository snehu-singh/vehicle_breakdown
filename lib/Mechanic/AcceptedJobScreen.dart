import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AcceptedJobScreen extends StatefulWidget {
  @override
  _AcceptedJobScreenState createState() => _AcceptedJobScreenState();
}

class _AcceptedJobScreenState extends State<AcceptedJobScreen> {
  final String mechanicId = FirebaseAuth.instance.currentUser!.uid;

  Future<Map<String, dynamic>?> fetchAcceptedJob() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('job_requests')
        .where('mechanicId', isEqualTo: mechanicId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return {
        'id': snapshot.docs.first.id,
        'data': snapshot.docs.first.data(),
      };
    } else {
      return null;
    }
  }

  Future<void> markJobComplete(String requestId) async {
    await FirebaseFirestore.instance
        .collection('job_requests')
        .doc(requestId)
        .update({'status': 'completed'});
    Navigator.pop(context); // Go back after marking complete
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Accepted Job")),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: fetchAcceptedJob(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data == null)
            return Center(child: Text("No accepted job found."));

          final jobId = snapshot.data!['id'];
          final job = snapshot.data!['data'];
          final userName = job['userName'] ?? 'Unknown';
          final issue = job['issue'] ?? 'N/A';
          final phone = job['userPhone'] ?? '';
          final lat = job['location']['latitude'];
          final lng = job['location']['longitude'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Customer: $userName", style: TextStyle(fontSize: 18)),
                SizedBox(height: 10),
                Text("Issue: $issue"),
                SizedBox(height: 10),
                Text("Phone: $phone"),
                SizedBox(height: 10),
                Text("Location: $lat, $lng"),
                SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.call),
                      label: Text("Call"),
                      onPressed: () async {
                        final url = Uri.parse("tel:$phone");
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                    ),
                    SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: Icon(Icons.navigation),
                      label: Text("Navigate"),
                      onPressed: () {
                        final url = Uri.parse("google.navigation:q=$lat,$lng");
                        launchUrl(url);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Center(
                  child: ElevatedButton(
                    onPressed: () => markJobComplete(jobId),
                    child: Text("Mark Job as Complete"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
