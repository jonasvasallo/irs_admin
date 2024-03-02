import "package:flutter/material.dart";

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:irs_admin/core/utilities.dart';

class DatabaseModel {
  static Future<Map<String, dynamic>> getDetails(
      String documentID, String collection) async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection(collection)
          .doc(documentID)
          .get();

      if (docSnapshot.exists) {
        // Document exists, now convert it to a map
        Map<String, dynamic> docDetails =
            docSnapshot.data() as Map<String, dynamic>;

        // Print or use the map as needed
        print('$collection Details: $docDetails');

        return docDetails;
      } else {
        // Document doesn't exist
        print('Doc not found');
        return {};
      }
    } catch (e) {
      print('Error retrieving doc details: $e');
      return {};
    }
  }

  static Future<void> updateDocDetails(String docID,
      Map<String, dynamic> updatedDetails, String collection) async {
    updatedDetails.removeWhere((key, value) => value == null || value == '');
    try {
      // Get the reference to the user document
      DocumentReference userRef =
          FirebaseFirestore.instance.collection(collection).doc(docID);

      // Update the document with the new details
      await userRef.update(updatedDetails);

      Utilities.showSnackBar("Updated Successfully", Colors.green);

      print('Doc details updated successfully');
    } catch (e) {
      print('Error updating Doc details: $e');
      Utilities.showSnackBar("Error updated Doc details: $e", Colors.red);
    }
  }

  static Future<void> addDocumentToCollection(
      String collection, Map<String, dynamic> docData) async {
    try {
      // Get a reference to the Firestore collection
      CollectionReference collectionReference =
          FirebaseFirestore.instance.collection(collection);

      // Add the document to the collection
      await collectionReference.add(docData);

      print('Document added successfully');
      Utilities.showSnackBar("Document added successfully", Colors.green);
    } catch (e) {
      print('Error adding document: $e');
      Utilities.showSnackBar("Error adding document: $e", Colors.red);
    }
  }

  static Future<void> deleteDocumentFromCollection(
      String docID, String collection) async {
    try {
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(docID)
          .delete();
      Utilities.showSnackBar("Successfully deleted document", Colors.green);
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    }
  }
}
