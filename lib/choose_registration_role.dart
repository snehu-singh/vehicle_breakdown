import 'package:flutter/material.dart';
import 'package:vehicle_breakdown/Mechanic/register_service_provider.dart';
import 'package:vehicle_breakdown/user/register_vehicle_owner.dart';

class ChooseRegistrationRole extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Account Type"),
        backgroundColor: Colors.deepPurple, // Consistent color theme
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Register As", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            SizedBox(height: 40),

            // Vehicle Owner Button
            ElevatedButton.icon(
              icon: Icon(Icons.directions_car, color: Colors.white),
              label: Text("Vehicle Owner", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // Button background color
                minimumSize: Size(double.infinity, 50), // Full width button with fixed height
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterVehicleOwnerScreen()),
                );
              },
            ),
            SizedBox(height: 20),

            // Service Provider Button
            ElevatedButton.icon(
              icon: Icon(Icons.build, color: Colors.white),
              label: Text("Service Provider", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple, // Button background color
                minimumSize: Size(double.infinity, 50), // Full width button with fixed height
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Rounded corners
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RegisterServiceProviderScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
