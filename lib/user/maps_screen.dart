import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsScreen extends StatefulWidget {
  @override
  _MapsScreenState createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchLocationAndMarkers();
  }

  Future<void> _fetchLocationAndMarkers() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    _currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    await _loadMechanicMarkers();
    setState(() {});
  }

  Future<void> _loadMechanicMarkers() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('mechanics').get();

    Set<Marker> newMarkers = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name'] ?? '';
      final lat = double.tryParse(data['latitude'].toString()) ?? 0.0;
      final lng = double.tryParse(data['longitude'].toString()) ?? 0.0;
      final phone = data['phone'] ?? '';

      final distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lng,
      );
      final distanceInKm = (distanceInMeters / 1000).toStringAsFixed(2);

      final marker = Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(lat, lng),
        onTap: () {
          _showMechanicBottomSheet(context, name, phone, double.parse(distanceInKm));
        },
      );

      newMarkers.add(marker);
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  void _showMechanicBottomSheet(BuildContext context, String name, String phone, double distanceKm) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.build_circle, size: 30),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(phone, style: TextStyle(fontSize: 16)),
                  ),
                  IconButton(
                    icon: Icon(Icons.call, color: Colors.green),
                    onPressed: () {
                      final url = Uri.parse("tel:$phone");
                      launchUrl(url);
                    },
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.directions_walk, size: 24),
                  SizedBox(width: 10),
                  Text('$distanceKm km away', style: TextStyle(fontSize: 16)),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showMechanicDialog(String name, String phone, String distance) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: Text('Distance: $distance km\nPhone: $phone'),
        actions: [
          TextButton(
            onPressed: () => launchUrl(Uri.parse('tel:$phone')),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.call, color: Colors.green),
                SizedBox(width: 8),
                Text('Call'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nearby Mechanics")),
      body: _currentPosition == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          zoom: 14,
        ),
        myLocationEnabled: true,
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
      ),
    );
  }
}
