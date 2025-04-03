import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SeeUpdateProfileScreen extends StatefulWidget {
  @override
  _SeeUpdateProfileScreenState createState() => _SeeUpdateProfileScreenState();
}

class _SeeUpdateProfileScreenState extends State<SeeUpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;

  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController shopController = TextEditingController();
  TextEditingController ownerController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  List<String> services = [];
  bool isLoading = true;
  File? _licenseImage;
  String? licenseUrl;

  final allServices = ['Puncture', 'Garage', 'Towing', 'Battery Jumpstart'];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final uid = _auth.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('mechanics').doc(uid).get();
    final data = doc.data();

    if (data != null) {
      setState(() {
        nameController.text = data['name'] ?? '';
        phoneController.text = data['phone'] ?? '';
        shopController.text = data['shopName'] ?? '';
        ownerController.text = data['ownerDetails'] ?? '';
        addressController.text = data['address'] ?? '';
        services = List<String>.from(data['services'] ?? []);
        licenseUrl = data['licenseUrl'];
        isLoading = false;
      });
    }
  }

  Future<void> _pickLicenseImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _licenseImage = File(picked.path));
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    String? newLicenseUrl = licenseUrl;

    if (_licenseImage != null) {
      final ref = FirebaseStorage.instance.ref().child('licenses/${_auth.currentUser!.uid}.jpg');
      await ref.putFile(_licenseImage!);
      newLicenseUrl = await ref.getDownloadURL();
    }

    await FirebaseFirestore.instance.collection('mechanics').doc(_auth.currentUser!.uid).update({
      'name': nameController.text,
      'phone': phoneController.text,
      'shopName': shopController.text,
      'ownerDetails': ownerController.text,
      'address': addressController.text,
      'services': services,
      'licenseUrl': newLicenseUrl,
    });

    setState(() => isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('See & Update Profile', style: TextStyle(color: Colors.white)), // Explicitly set text color to white
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white, // Sets the color of the leading, actions, and title
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _updateProfile,
            tooltip: 'Update Profile',
          ),
        ],
      ),

      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: shopController,
                decoration: InputDecoration(
                  labelText: 'Shop Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: ownerController,
                decoration: InputDecoration(
                  labelText: 'Owner Details',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Services Offered", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Wrap(
                spacing: 10,
                children: allServices.map((service) => ChoiceChip(
                  label: Text(service),
                  selected: services.contains(service),
                  onSelected: (selected) {
                    setState(() {
                      selected ? services.add(service) : services.remove(service);
                    });
                  },
                )).toList(),
              ),
              SizedBox(height: 20),
              _licenseImageDisplay(),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickLicenseImage,
                icon: Icon(Icons.upload_file),
                label: Text("Upload New License"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _licenseImageDisplay() {
    return licenseUrl != null
        ? Column(
      children: [
        Image.network(licenseUrl!, height: 100),
        Text("Driving License"),
      ],
    )
        : Text("No license uploaded.");
  }
}
