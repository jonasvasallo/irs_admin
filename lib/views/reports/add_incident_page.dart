import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:irs_admin/core/constants.dart';
import 'package:irs_admin/core/input_validator.dart';
import 'package:irs_admin/core/utilities.dart';
import 'package:irs_admin/widgets/input_button.dart';
import 'package:irs_admin/widgets/input_field.dart';
import 'package:http/http.dart' as http;

class AddIncidentPage extends StatefulWidget {
  const AddIncidentPage({Key? key}) : super(key: key);

  @override
  _AddIncidentPageState createState() => _AddIncidentPageState();
}

class _AddIncidentPageState extends State<AddIncidentPage> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();

  String selectFile = "";
  // XFile file;
  late Uint8List selectedImageInBytes;

  late GoogleMapController mapController;

  final LatLng _center = const LatLng(14.967031, 120.9231);

  double latitude = 0;
  double longitude = 0;

  String coords = "Tapped Location: Untapped";
  String address_str = "";

  LatLng? _tappedLocation;
  LatLng? circleCenter;

  final formKey = GlobalKey<FormState>();

  String _dropdownValue = "";

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  _selectFile(bool imageFrom) async {
    FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (fileResult != null) {
      setState(() {
        selectFile = fileResult.files.first.name;
        selectedImageInBytes = fileResult.files.first.bytes!;
      });
    }
    print(selectFile);
  }

  Future<String> _uploadFile() async {
    try {
      UploadTask uploadTask;

      Reference ref = FirebaseStorage.instance
          .ref()
          .child('incident_attachments/$selectFile');

      final metadata = SettableMetadata(contentType: 'image/jpeg');

      uploadTask = ref.putData(selectedImageInBytes, metadata);
      await uploadTask.whenComplete(() => null);
      String imageUrl = await ref.getDownloadURL();
      return imageUrl;
    } catch (ex) {
      print('Error uploading image to Firestore: $ex');
      throw ex;
    }
  }

  void _onMapTap(LatLng tappedPoint) async {
    setState(() {
      _tappedLocation = tappedPoint;
      circleCenter = tappedPoint;
    });

    // Check if _tappedLocation is not null before using its properties
    if (_tappedLocation != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(_tappedLocation!),
      );

      latitude = _tappedLocation!.latitude;
      longitude = _tappedLocation!.longitude;

      setState(() {
        coords = "Tapped Location: ($latitude, $longitude)";
      });
      // Reverse geocode using the Google Maps Geocoding API
      final apiKey = 'AIzaSyB_na6Rzdg7vqM1flMuKNg9yPWqP2GUGZ4';
      final apiUrl =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${_tappedLocation!.latitude},${_tappedLocation!.longitude}&key=$apiKey';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'OK') {
          final results = decoded['results'] as List<dynamic>;
          if (results.isNotEmpty) {
            final address = results[0]['formatted_address'] as String;
            setState(() {
              address_str = address;
            });
          } else {
            print('No results found for reverse geocoding.');
          }
        } else {
          print(
              'Error status in reverse geocoding response: ${decoded['status']}');
        }
      } else {
        print('Failed to retrieve address: ${response.statusCode}');
      }
    } else {
      print('Tapped location is null.');
    }
  }

  void addIncident() async {
    String urlDownload = "";
    InputValidator.checkFormValidity(formKey, context);
    if (_titleController.text.isEmpty || _detailsController.text.isEmpty) {
      Utilities.showSnackBar("Missing Fields", Colors.red);
      return;
    }

    if (_dropdownValue.isEmpty) {
      Utilities.showSnackBar("Select an incident tag", Colors.red);
      return;
    }

    if (latitude == 0 || longitude == 0) {
      Utilities.showSnackBar("Select a location first", Colors.red);
      return;
    }

    try {
      if (!selectFile.isEmpty) {
        urlDownload = await _uploadFile();
      }

      CollectionReference incidentsCollection =
          FirebaseFirestore.instance.collection('incidents');

      await incidentsCollection.add({
        'title': _titleController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Verified',
        'responders': [],
        'reported_by': FirebaseAuth.instance.currentUser?.uid,
        'media_attachments':
            (!selectFile.isEmpty && !urlDownload.isEmpty) ? [urlDownload] : [],
        'location_address': address_str,
        'incident_tag': _dropdownValue,
        'details': _detailsController.text.trim(),
        'coordinates': {
          'latitude': latitude,
          'longitude': longitude,
        }
      });
      Utilities.showSnackBar("Successfully added incident", Colors.green);
      Navigator.of(context).pop();
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    }
  }

  Future<List<Map<String, dynamic>>> getIncidentTags() async {
    List<Map<String, dynamic>> incident_tags = [];

    try {
      QuerySnapshot tagsSnapshot =
          await FirebaseFirestore.instance.collection('incident_tags').get();

      if (tagsSnapshot.docs.isNotEmpty) {
        for (var tagDocument in tagsSnapshot.docs) {
          Map<String, dynamic> tagData =
              tagDocument.data() as Map<String, dynamic>;
          incident_tags.add({
            'tag_id': tagDocument.id,
            'tag_name': tagData['tag_name'],
            // Add more fields if needed
          });
        }
      } else {
        print('No tags found in the incident_tags collection.');
      }
    } catch (ex) {
      print('Error fetching incident tags: $ex');
    }

    return incident_tags;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add an Incident"),
        leading: TextButton(
          child: Icon(
            Icons.chevron_left,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: formKey,
              child: Flexible(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            "Add an Incident",
                            style: heading,
                          ),
                          InputField(
                            placeholder: "Incident Title",
                            inputType: "text",
                            controller: _titleController,
                            label: "Title",
                            validator: InputValidator.requiredValidator,
                          ),
                          InputField(
                            placeholder: "Incident Details Here...",
                            inputType: "text",
                            controller: _detailsController,
                            label: "Details",
                            validator: InputValidator.requiredValidator,
                          ),
                          
                          SizedBox(
                            height: 16,
                          ),
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: FutureBuilder(
                                  future: getIncidentTags(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      // Data is still loading
                                      return CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      // Error occurred while fetching data
                                      return Text('Error: ${snapshot.error}');
                                    } else if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      // No data available
                                      return Text('No incident tags found.');
                                    } else {
                                      // Data has been successfully fetched
                                      List<Map<String, dynamic>> incidentTags =
                                          snapshot.data!;

                                      return DropdownMenu(
                                        hintText: "Choose Incident Tag",
                                        width: 350,
                                        onSelected: (value) {
                                          _dropdownValue = value;
                                        },
                                        
                                        dropdownMenuEntries: incidentTags
                                            .map((Map<String, dynamic> tag) {
                                          return DropdownMenuEntry(
                                            
                                              value: tag['tag_id'],
                                              label: tag['tag_name']);
                                        }).toList(),
                                      );
                                    }
                                  },
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return IncidentTagDialog(
                                        onUpdate: () {
                                          setState(() {});
                                        },
                                      );
                                    },
                                  );
                                },
                                child: Text("Add New"),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 16,
                          ),
                          InputButton(
                              label: "Add Media Attachment",
                              function: () => _selectFile(true),
                              large: false),
                          (!selectFile.isEmpty)
                              ? SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: Image.memory(
                                    selectedImageInBytes,
                                    fit: BoxFit.contain,
                                  ),
                                )
                              : SizedBox(),
                          SizedBox(
                            height: 16,
                          ),
                          InputButton(
                              label: "Add Incident",
                              function: () {
                                addIncident();
                              },
                              large: false),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 32,
            ),
            Flexible(
              child: LocationContainer(),
            ),
          ],
        ),
      ),
    );
  }
}

class IncidentTagDialog extends StatefulWidget {
  final VoidCallback onUpdate;
  const IncidentTagDialog(
      {Key? key, required this.onUpdate})
      : super(key: key);

  @override
  _IncidentTagDialogState createState() => _IncidentTagDialogState();
}

class _IncidentTagDialogState extends State<IncidentTagDialog> {
  final _incidentTagController = TextEditingController();

  String _dropdownValue = "";

  Future<List<Map<String, dynamic>>> getIncidentTags() async {
    List<Map<String, dynamic>> incident_tags = [];

    try {
      QuerySnapshot tagsSnapshot =
          await FirebaseFirestore.instance.collection('incident_tags').get();

      if (tagsSnapshot.docs.isNotEmpty) {
        for (var tagDocument in tagsSnapshot.docs) {
          Map<String, dynamic> tagData =
              tagDocument.data() as Map<String, dynamic>;
          incident_tags.add({
            'tag_id': tagDocument.id,
            'tag_name': tagData['tag_name'],
            // Add more fields if needed
          });
        }
      } else {
        print('No tags found in the incident_tags collection.');
      }
    } catch (ex) {
      print('Error fetching incident tags: $ex');
    }

    return incident_tags;
  }

  Future<void> addIncidentTag(String tagName, String description) async {
    try {
      // Reference to the 'incident_tags' collection
      CollectionReference incidentTagsCollection =
          FirebaseFirestore.instance.collection('incident_tags');

      // Add a new document with auto-generated ID
      DocumentReference newDocRef = await incidentTagsCollection.add({
        'tag_name': tagName,
        'priority': "Low",
        // Add more fields as needed
      });

      print('Incident tag added successfully');
    } catch (error) {
      print('Error adding incident tag: $error');
      throw error; // Propagate the error if needed
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Add New Incident Tag",
              style: regular_minor,
            ),
            InputField(
                placeholder: "Incident Tag Name",
                inputType: "text",
                controller: _incidentTagController),
            InputButton(
                label: "DONE",
                function: () async {
                  if (_incidentTagController.text.isEmpty) {
                    Utilities.showSnackBar("Missing fields", Colors.red);
                    return;
                  }

                  await addIncidentTag(
                        _incidentTagController.text.trim(), "Low");
                    widget.onUpdate();
                    Utilities.showSnackBar(
                        "Successfully added tag", Colors.green);
                    Navigator.of(context).pop();

                },
                large: false),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(), child: Text("Cancel"))
      ],
    );
  }
}


class LocationContainer extends StatefulWidget {
  const LocationContainer({ Key? key }) : super(key: key);

  @override
  _LocationContainerState createState() => _LocationContainerState();
}

class _LocationContainerState extends State<LocationContainer> {
    

     late GoogleMapController mapController;

  final LatLng _center = const LatLng(14.967031, 120.9231);

  double latitude = 0;
  double longitude = 0;

String coords = "Tapped Location: Untapped";
  String address_str = "";

  LatLng? _tappedLocation;
  LatLng? circleCenter;

    void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _onMapTap(LatLng tappedPoint) async {
    setState(() {
      _tappedLocation = tappedPoint;
      circleCenter = tappedPoint;
    });

    // Check if _tappedLocation is not null before using its properties
    if (_tappedLocation != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(_tappedLocation!),
      );

      latitude = _tappedLocation!.latitude;
      longitude = _tappedLocation!.longitude;

      setState(() {
        coords = "Tapped Location: ($latitude, $longitude)";
      });
      // Reverse geocode using the Google Maps Geocoding API
      final apiKey = 'AIzaSyB_na6Rzdg7vqM1flMuKNg9yPWqP2GUGZ4';
      final apiUrl =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${_tappedLocation!.latitude},${_tappedLocation!.longitude}&key=$apiKey';

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'OK') {
          final results = decoded['results'] as List<dynamic>;
          if (results.isNotEmpty) {
            final address = results[0]['formatted_address'] as String;
            setState(() {
              address_str = address;
            });
          } else {
            print('No results found for reverse geocoding.');
          }
        } else {
          print(
              'Error status in reverse geocoding response: ${decoded['status']}');
        }
      } else {
        print('Failed to retrieve address: ${response.statusCode}');
      }
    } else {
      print('Tapped location is null.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                            "Incident Location",
                            style: subheading,
                          ),
                          Container(
                            width: double.infinity,
                            height: 250,
                            color: Colors.grey,
                            child: GoogleMap(
                              onMapCreated: _onMapCreated,
                              initialCameraPosition: CameraPosition(
                                target: _center,
                                zoom: 15,
                              ),
                              onTap: _onMapTap,
                              circles: Set.from([
                                if (circleCenter != null)
                                  Circle(
                                    circleId: CircleId("customCircle"),
                                    center: circleCenter!,
                                    radius: 10, // Radius in meters
                                    fillColor: Color.fromARGB(255, 243, 33, 33)
                                        .withOpacity(0.3),
                                    strokeColor:
                                        const Color.fromARGB(255, 243, 33, 33),
                                    strokeWidth: 2,
                                  ),
                              ]),
                            ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            coords,
                            style: regular,
                          ),
                          Text(
                            address_str,
                            style: regular,
                          ),
                    ],
                  ),
                ),
              );
  }
}
