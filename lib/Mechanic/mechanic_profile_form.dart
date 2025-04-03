import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class MechanicProfileForm extends StatefulWidget {
  @override
  _MechanicProfileFormState createState() => _MechanicProfileFormState();
}

class _MechanicProfileFormState extends State<MechanicProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _shopOwnerController = TextEditingController();
  File? _licenseFile;
  List<String> _services = [];
  List<String> _serviceOptions = ["Puncture", "Garage", "Battery Jumpstart", "Oil Change"];

  bool isUploading = false;
  bool isSubmitted = false;

  Future<void> _pickLicenseFile() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _licenseFile = File(picked.path);
      });
    }
  }

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate() && _licenseFile != null && _services.isNotEmpty) {
      setState(() => isUploading = true);

      final uid = FirebaseAuth.instance.currentUser!.uid;

      String licenseUrl = await FirebaseStorage.instance
          .ref('mechanics/licenses/$uid.jpg')
          .putFile(_licenseFile!)
          .then((task) => task.ref.getDownloadURL());

      await FirebaseFirestore.instance.collection('mechanics').doc(uid).set({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'shopOwner': _shopOwnerController.text,
        'address': _shopAddressController.text,
        'services': _services,
        'licenseUrl': licenseUrl,
        'isVerified': false,
      });

      setState(() {
        isUploading = false;
        isSubmitted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Complete Your Profile")),
      body: isUploading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("Mechanic Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Full Name"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
                validator: (val) => val!.length < 10 ? "Enter valid phone" : null,
              ),
              TextFormField(
                controller: _shopOwnerController,
                decoration: InputDecoration(labelText: "Shop Owner Details (Optional)"),
              ),
              TextFormField(
                controller: _shopAddressController,
                decoration: InputDecoration(labelText: "Shop Address"),
                validator: (val) => val!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Select Services Offered:", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ..._serviceOptions.map((service) => CheckboxListTile(
                value: _services.contains(service),
                title: Text(service),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _services.add(service);
                    } else {
                      _services.remove(service);
                    }
                  });
                },
              )),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _pickLicenseFile,
                icon: Icon(Icons.upload_file),
                label: Text(_licenseFile == null ? "Upload Driving License" : "License Selected"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitProfile,
                child: Text("Submit Profile"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
