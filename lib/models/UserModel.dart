import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:irs_admin/core/utilities.dart';

class UserModel {
  static Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        // Document exists, now convert it to a map
        Map<String, dynamic> userDetails =
            userSnapshot.data() as Map<String, dynamic>;

        // Print or use the map as needed
        print('User Details: $userDetails');

        return userDetails;
      } else {
        // Document doesn't exist
        print('User not found');
        return {};
      }
    } catch (e) {
      print('Error retrieving user details: $e');
      return {};
    }
  }

  static Future<void> updateUserDetails(
      String userId, Map<String, dynamic> updatedDetails) async {
    updatedDetails.removeWhere((key, value) => value == null || value == '');
    try {
      // Get the reference to the user document
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // Update the document with the new details
      await userRef.update(updatedDetails);

      Utilities.showSnackBar("Updated Successfully", Colors.green);

      print('User details updated successfully');
    } catch (e) {
      print('Error updating user details: $e');
      Utilities.showSnackBar("Error updated user details: $e", Colors.red);
    }
  }
}
