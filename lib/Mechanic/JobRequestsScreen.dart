import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class JobRequestsScreen extends StatefulWidget {
  @override
  _JobRequestsScreenState createState() => _JobRequestsScreenState();
}

class _JobRequestsScreenState extends State<JobRequestsScreen> {
  final String mechanicId = FirebaseAuth.instance.currentUser!.uid;

  Future<void> markJobComplete(String requestId) async {
    await FirebaseFirestore.instance
        .collection('job_requests')
        .doc(requestId)
        .update({'status': 'completed'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Job Requests"),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('job_requests')
            .where('mechanicId', isEqualTo: mechanicId)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          if (snapshot.data!.docs.isEmpty) return Center(child: Text("No job requests found.", style: TextStyle(fontSize: 16)));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(data['userName'] ?? 'No Name', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text("Issue: ${data['issue']}\nPhone: ${data['userPhone']}", style: TextStyle(color: Colors.black87)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.call, color: Colors.blue),
                        onPressed: () async {
                          final url = Uri.parse('tel:${data['userPhone']}');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => markJobComplete(doc.id),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Optionally add tap action
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
