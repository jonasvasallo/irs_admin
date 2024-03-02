import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ResidentModel {
  static Future<Map<String, dynamic>> getUserDetails(String residentID) async {
    try {
      DocumentSnapshot residentSnapshot = await FirebaseFirestore.instance
          .collection('residents')
          .doc(residentID)
          .get();

      if (residentSnapshot.exists) {
        // Document exists, now convert it to a map
        Map<String, dynamic> residentDetails =
            residentSnapshot.data() as Map<String, dynamic>;

        // Print or use the map as needed
        print('resident Details: $residentDetails');

        return residentDetails;
      } else {
        // Document doesn't exist
        print('resident not found');
        return {};
      }
    } catch (e) {
      print('Error retrieving resident details: $e');
      return {};
    }
  }
}
