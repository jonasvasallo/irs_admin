import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:irs_admin/core/constants.dart';
import 'package:irs_admin/core/input_validator.dart';
import 'package:irs_admin/core/utilities.dart';
import 'package:irs_admin/widgets/input_button.dart';
import 'package:irs_admin/widgets/input_field.dart';

class IncidentDetailsPage extends StatefulWidget {
  final String incident_id;
  const IncidentDetailsPage({Key? key, required this.incident_id})
      : super(key: key);

  @override
  _IncidentDetailsPageState createState() => _IncidentDetailsPageState();
}

class _IncidentDetailsPageState extends State<IncidentDetailsPage> {
  final _messageController = TextEditingController();

  Future<void> verifyIncident() async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Ensure the user is authenticated before proceeding
      if (currentUserId.isEmpty) {
        print('User not authenticated.');
        return;
      }

      // Reference to the 'incident_tags' collection
      CollectionReference incidentCollection =
          FirebaseFirestore.instance.collection('incidents');

      // Update the document with the specified tagId
      await incidentCollection.doc(widget.incident_id).update({
        'status': "Verified",
        // Update more fields as needed
      });

      await incidentCollection
          .doc(widget.incident_id)
          .collection('live_status')
          .add({
        'status_content': "Incident status changed to Verified",
        'timestamp': FieldValue.serverTimestamp(),
        'updated_by': currentUserId,
        // Add more fields as needed
      });

      Utilities.showSnackBar("Incident verified", Colors.green);

      print('Incident  status updated successfully');
    } catch (error) {
      print('Error updating Incident  status: $error');
      Utilities.showSnackBar("$error", Colors.red);
      throw error; // Propagate the error if needed
    }
  }

  Future<Map<String, dynamic>> fetchIncidentInfo() async {
    Map<String, dynamic> incidentDetails = {};

    try {
      DocumentSnapshot incidentSnapshot = await FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.incident_id)
          .get();

      if (incidentSnapshot.exists) {
        incidentDetails = incidentSnapshot.data() as Map<String, dynamic>;

        String reportedById = incidentDetails['reported_by'];
        if (reportedById != null) {
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(reportedById)
              .get();
          if (userSnapshot.exists) {
            // Include user details in the incidentDetails map
            incidentDetails['user_details'] = userSnapshot.data();
          } else {
            print("User does not exist");
          }

          String incident_tag_id = incidentDetails['incident_tag'];
          if (incident_tag_id != null) {
            DocumentSnapshot incidentTagSnapshot = await FirebaseFirestore
                .instance
                .collection('incident_tags')
                .doc(incident_tag_id)
                .get();

            if (incidentTagSnapshot.exists) {
              incidentDetails['incident_tags_details'] =
                  incidentTagSnapshot.data();
              print(incidentDetails['incident_tags_details']);
            } else {
              print("incident tag does not exist");
            }
          }
        } else {
          print("reported_by field is null");
        }
      } else {
        print("incident does not exist");
      }
    } catch (ex) {
      print("Error fetching incident details");
    }

    return incidentDetails;
  }

  Future<List<Map<String, dynamic>>> fetchRespondersDetails() async {
    List<Map<String, dynamic>> respondersDetails = [];

    try {
      // Fetch the incident document
      DocumentSnapshot incidentSnapshot = await FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.incident_id)
          .get();

      if (incidentSnapshot.exists) {
        // Extract the responders array from the incident document
        List<String>? responderUIDs =
            List<String>.from(incidentSnapshot['responders']);

        if (responderUIDs != null && responderUIDs.isNotEmpty) {
          // Fetch details for each responder
          for (String responderUID in responderUIDs) {
            DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(responderUID)
                .get();

            if (userSnapshot.exists) {
              // Add responder details to the list
              respondersDetails.add({
                'uID': responderUID,
                'profile_path': userSnapshot['profile_path'],
                'first_name': userSnapshot['first_name'],
                'last_name': userSnapshot['last_name'],
                'contact_no': userSnapshot['contact_no'],
                'user_type': userSnapshot['user_type'],
                // Add more fields as needed
              });
            } else {
              print('User with uID $responderUID not found');
            }
          }
        } else {
          print('No responders for the incident');
        }
      } else {
        print('Incident with ID ${widget.incident_id} not found');
      }
    } catch (error) {
      print('Error fetching responders details: $error');
      throw error; // Propagate the error if needed
    }

    return respondersDetails;
  }

  Future<void> removeUserFromResponders(
      String incidentId, String userId) async {
    try {
      // Reference to the specific incident document
      DocumentReference incidentDocRef =
          FirebaseFirestore.instance.collection('incidents').doc(incidentId);

      // Get the current responders array
      DocumentSnapshot incidentSnapshot = await incidentDocRef.get();
      List<String> currentResponders =
          List<String>.from(incidentSnapshot['responders'] ?? []);

      // Check if the user ID is in the responders array
      if (currentResponders.contains(userId)) {
        // Remove the user ID from the responders array
        currentResponders.remove(userId);

        // Update the incident document with the updated responders array
        await incidentDocRef.update({'responders': currentResponders});

        print(
            'User with ID $userId removed from responders for incident ID $incidentId');
      } else {
        print(
            'User with ID $userId is not in responders for incident ID $incidentId');
      }
    } catch (error) {
      print('Error removing user from responders: $error');
      throw error; // Propagate the error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Incident Details"),
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
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: FutureBuilder(
                    future: fetchIncidentInfo(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        Map<String, dynamic> incidentDetails = snapshot.data!;

                        String myDate = "test";

                        if (incidentDetails['timestamp'] != null) {
                          Timestamp t =
                              incidentDetails['timestamp'] as Timestamp;
                          DateTime date = t.toDate();
                          myDate = DateFormat('dd/MM/yyyy,hh:mm').format(date);
                        }

                        List<Widget> media_attachments = [];

                        print(incidentDetails['media_attachments']);
                        for (var media
                            in incidentDetails['media_attachments']) {
                          final mediaWidget = GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return Dialog(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context)
                                            .pop(); // Close the dialog on tap outside
                                      },
                                      child: SizedBox(
                                        width: 960,
                                        height: 540,
                                        child: Image.network(
                                          media,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: Container(
                                width: 350,
                                height: 150,
                                color: Colors.grey,
                                child: Image.network(
                                  media,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                          media_attachments.add(mediaWidget);
                        }

                        return SingleChildScrollView(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(children: media_attachments),
                                ),
                                SizedBox(
                                  height: 16,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            incidentDetails['title'],
                                            style: subheading,
                                          ),
                                          Text(
                                            myDate,
                                            style: regular,
                                          ),
                                          Text(
                                            incidentDetails['location_address'],
                                            style: regular_minor,
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                "${incidentDetails['incident_tags_details']['tag_name']}",
                                                style: regular,
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return IncidentTagDialog(
                                                        incident_id:
                                                            widget.incident_id,
                                                        onUpdate: () {
                                                          setState(() {});
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Text("Change"),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                incidentDetails['status'],
                                                style: regular,
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return IncidentStatusDialog(
                                                        incident_id:
                                                            widget.incident_id,
                                                        onUpdate: () {
                                                          setState(() {});
                                                        },
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Text("Change"),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 16,),
                                          Row(
                                            children: [
                                              Container(
                                                width: 64,
                                                height: 64,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(64),
                                                  color: Colors.grey,
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(64),
                                                  child: Image.network(
                                                    incidentDetails[
                                                            'user_details']
                                                        ['profile_path'],
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width:8,
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "${incidentDetails['user_details']['first_name']} ${incidentDetails['user_details']['last_name']}",
                                                    style: regular,
                                                  ),
                                                  Text(
                                                    incidentDetails[
                                                                'user_details']
                                                            ['user_type']
                                                        .toString()
                                                        .toUpperCase(),
                                                    style: regular_minor,
                                                  ),
                                                  Text(
                                                    "Verified User",
                                                    style: regular,
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        width: 450,
                                        height: 250,
                                        color: Colors.grey,
                                        child: GoogleMap(
                                            initialCameraPosition:
                                                CameraPosition(
                                                    target: LatLng(
                                                        incidentDetails[
                                                                'coordinates']
                                                            ['latitude'],
                                                        incidentDetails[
                                                                'coordinates']
                                                            ['longitude']),
                                                    zoom: 18),
                                            circles: Set.from([
                                              Circle(
                                                circleId:
                                                    CircleId("customCircle"),
                                                center: LatLng(
                                                    incidentDetails[
                                                            'coordinates']
                                                        ['latitude'],
                                                    incidentDetails[
                                                            'coordinates']
                                                        ['longitude']),
                                                radius: 10, // Radius in meters
                                                fillColor: Color.fromARGB(
                                                        255, 243, 33, 33)
                                                    .withOpacity(0.3),
                                                strokeColor:
                                                    const Color.fromARGB(
                                                        255, 243, 33, 33),
                                                strokeWidth: 2,
                                              ),
                                            ])),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 16,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child:
                                      (incidentDetails['status'] == 'Verifying')
                                          ? SizedBox(
                                              width: 200,
                                              child: InputButton(
                                                  label: "Verify Incident",
                                                  function: () {
                                                    verifyIncident();
                                                    setState(() {});
                                                  },
                                                  large: false))
                                          : SizedBox(),
                                ),
                                SizedBox(
                                  height: 16,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: SingleChildScrollView(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Details",
                                              style: subheading,
                                            ),
                                            Text(
                                              incidentDetails['details'],
                                              style: regular,
                                            ),
                                            SizedBox(
                                              height: 16,
                                            ),
                                            Align(
                                              alignment: Alignment.center,
                                              child: SizedBox(
                                                width: 500,
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      "Witnesses",
                                                      style: subheading,
                                                    ),
                                                    FutureBuilder(
                                                        future: FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                                'incidents')
                                                            .doc(widget
                                                                .incident_id)
                                                            .collection(
                                                                'witnesses')
                                                            .get(),
                                                        builder:
                                                            (context, snapshot) {
                                                          if (snapshot
                                                                  .connectionState ==
                                                              ConnectionState
                                                                  .done) {
                                                            if (!snapshot
                                                                .hasData) {
                                                              return Text(
                                                                  "No witnesses yet");
                                                            } else if (snapshot
                                                                .hasError) {
                                                              return Text(
                                                                  "Error ${snapshot.error}");
                                                            }
                                                                  
                                                            final witnesses =
                                                                snapshot
                                                                    .data?.docs
                                                                    .toList();
                                                            print(snapshot.data!);
                                                            List<Widget>
                                                                witnessWidgets =
                                                                [];
                                                                  
                                                            for (var witness
                                                                in witnesses!) {
                                                              final witnessWidet =
                                                                  Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        top: 4,
                                                                        bottom:
                                                                            4),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    FutureBuilder(
                                                                        future: FirebaseFirestore
                                                                            .instance
                                                                            .collection(
                                                                                'users')
                                                                            .doc(witness[
                                                                                'user_id'])
                                                                            .get(),
                                                                        builder:
                                                                            (context,
                                                                                snapshot) {
                                                                          if (snapshot.connectionState ==
                                                                              ConnectionState.done) {
                                                                            if (!snapshot
                                                                                .hasData) {
                                                                              return Text("No witnesses yet");
                                                                            } else if (snapshot
                                                                                .hasError) {
                                                                              return Text("Error ${snapshot.error}");
                                                                            }
                                                                            Map<String, dynamic>
                                                                                userDetails =
                                                                                snapshot.data!.data() as Map<String, dynamic>;
                                                                  
                                                                            return Row(
                                                                              children: [
                                                                                ClipRRect(
                                                                                  borderRadius: BorderRadius.circular(48),
                                                                                  child: Image.network(
                                                                                    userDetails['profile_path'],
                                                                                    width: 48,
                                                                                    height: 48,
                                                                                    fit: BoxFit.cover,
                                                                                  ),
                                                                                ),
                                                                                SizedBox(
                                                                                  width: 8,
                                                                                ),
                                                                                Column(
                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                  children: [
                                                                                    Text(
                                                                                      "${userDetails['first_name']} ${userDetails['last_name']}",
                                                                                      style: regular,
                                                                                    ),
                                                                                    Text(
                                                                                      userDetails['contact_no'],
                                                                                      style: regular_minor,
                                                                                    ),
                                                                                    Text(witness['details'], style: regular,),
                                                                                  ],
                                                                                ),
                                                                              ],
                                                                            );
                                                                          } else {
                                                                            return Center(
                                                                              child:
                                                                                  CircularProgressIndicator(),
                                                                            );
                                                                          }
                                                                        }),
                                                                    (!witness['media_attachment'].isEmpty) ? GestureDetector(
                                                                      onTap: () {
                                                                        showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (context) {
                                                                            return Center(
                                                                              child:
                                                                                  Column(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  SizedBox(
                                                                                    child: Image.network(
                                                                                      witness['media_attachment'],
                                                                                      fit: BoxFit.contain,
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            );
                                                                          },
                                                                        );
                                                                      },
                                                                      child: Icon(Icons.remove_red_eye),
                                                                    ) : SizedBox(),
                                                                  ],
                                                                ),
                                                              );
                                                              witnessWidgets.add(
                                                                  witnessWidet);
                                                            }
                                                            return Column(
                                                              children:
                                                                  witnessWidgets,
                                                            );
                                                          } else {
                                                            return Center(
                                                              child:
                                                                  CircularProgressIndicator(),
                                                            );
                                                          }
                                                        }),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 16,
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "Assigned Personnel",
                                                style: subheading,
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) {
                                                      return AddTanodDialog(
                                                          incident_id: widget
                                                              .incident_id,
                                                          onUpdate: () {
                                                            setState(() {});
                                                          });
                                                    },
                                                  );
                                                },
                                                child: Text("Add"),
                                              ),
                                            ],
                                          ),
                                          FutureBuilder(
                                            future: fetchRespondersDetails(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.done) {
                                                if (snapshot.hasError) {
                                                  return Text(
                                                      "Error ${snapshot.error}");
                                                }
                                                if (!snapshot.hasData ||
                                                    snapshot.data!.isEmpty) {
                                                  // No data available
                                                  return Text(
                                                      'No personnel assigned yet');
                                                }
                            
                                                List<Map<String, dynamic>>
                                                    respondersDetails =
                                                    snapshot.data!;
                                                List<Widget> respondersList =
                                                    [];
                                                for (var responder
                                                    in respondersDetails) {
                                                  final responderWidget =
                                                      AssignedTanodContainer(
                                                          user_id:
                                                              responder['uID'],
                                                          name:
                                                              "${responder['first_name']} ${responder['last_name']}",
                                                          user_type: responder[
                                                              'user_type'],
                                                          contact_no: responder[
                                                              'contact_no'],
                                                          onDelete: () {
                                                            removeUserFromResponders(
                                                                widget
                                                                    .incident_id,
                                                                responder[
                                                                    'uID']);
                                                            setState(() {});
                                                          },
                                                          profile_path: responder[
                                                              'profile_path']);
                                                  respondersList
                                                      .add(responderWidget);
                                                }
                            
                                                return Column(
                                                  children: respondersList,
                                                );
                                              } else {
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                );
                                              }
                                            },
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    }),
              ),
            ),
            SizedBox(
              width: 32,
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                      ),
                      child: LiveStatusContainer(
                        incident_id: widget.incident_id,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 32,
                  ),
                  Expanded(
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                      ),
                      child: ChatroomContainer(
                        incident_id: widget.incident_id,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class LiveStatusContainer extends StatefulWidget {
  final String incident_id;
  const LiveStatusContainer({Key? key, required this.incident_id})
      : super(key: key);

  @override
  _LiveStatusContainerState createState() => _LiveStatusContainerState();
}

class _LiveStatusContainerState extends State<LiveStatusContainer> {
  final _incidentStatusController = TextEditingController();
  Future<List<String>> fetchUserDefinedStatuses() async {
    List<String> userDefinedStatuses = [];

    try {
      QuerySnapshot statusesSnapshot = await FirebaseFirestore.instance
          .collection('user_defined_statuses')
          .get();

      if (statusesSnapshot.docs.isNotEmpty) {
        // Extract the status_content field from each document
        userDefinedStatuses = statusesSnapshot.docs.map((statusDocument) {
          return statusDocument['status_content'] as String;
        }).toList();
      } else {
        print('No user-defined statuses found in the collection.');
      }
    } catch (error) {
      print('Error fetching user-defined statuses: $error');
      throw error; // Propagate the error if needed
    }

    return userDefinedStatuses;
  }

  Future<void> addLiveStatusToIncident(
      String incidentId, String statusContent) async {
    if (statusContent.isEmpty) {
      Utilities.showSnackBar("Please enter status content first", Colors.red);
      return;
    }
    try {
      // Get the current user ID
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Ensure the user is authenticated before proceeding
      if (currentUserId.isEmpty) {
        print('User not authenticated.');
        return;
      }

      // Reference to the 'live_status' collection within the specific incident document
      CollectionReference liveStatusCollection = FirebaseFirestore.instance
          .collection('incidents')
          .doc(incidentId)
          .collection('live_status');

      // Add a new document with the specified fields
      await liveStatusCollection.add({
        'status_content': statusContent,
        'timestamp': FieldValue.serverTimestamp(),
        'updated_by': currentUserId,
        // Add more fields as needed
      });
      _incidentStatusController.text = "";
      print('Live status added successfully to incident ID $incidentId.');
      Utilities.showSnackBar("Successfully added status update", Colors.green);
    } catch (error) {
      print('Error adding live status: $error');
      throw error; // Propagate the error if needed
    }
  }

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        return userSnapshot.data() as Map<String, dynamic>;
      } else {
        print('User with ID $userId not found.');
        return {};
      }
    } catch (error) {
      print('Error fetching user details: $error');
      throw error;
    }
  }

  @override
  void dispose() {
    _incidentStatusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Incident Live Status",
                  style: subheading,
                ),
                FutureBuilder(
                  future: fetchUserDefinedStatuses(),
                  builder: (context, snapshot) {
                    List<Widget> statusButtons = [];
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        return Text("${snapshot.error}");
                      }
                      List<String> userDefinedStatuses = snapshot.data!;

                      userDefinedStatuses.forEach((element) {
                        final statusButton = Row(
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                _incidentStatusController.text = element;
                              },
                              child: Text(element),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                          ],
                        );
                        statusButtons.add(statusButton);
                      });
                      statusButtons.add(
                        OutlinedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AddStatusDialog(
                                  onAdd: () {
                                    setState(() {});
                                  },
                                );
                              },
                            );
                          },
                          child: Icon(Icons.add),
                        ),
                      );
                      return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: statusButtons,
                          ));
                    } else {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Flexible(
            flex: 2,
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('incidents')
                  .doc(widget.incident_id)
                  .collection('live_status')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text('No live status available.');
                }
                List<Widget> statusUpdates = [];
                List<QueryDocumentSnapshot> documents = snapshot.data!.docs;

                for (var status in documents) {
                  String myDate = "test";

                  if (status['timestamp'] != null) {
                    Timestamp t = status['timestamp'] as Timestamp;
                    DateTime date = t.toDate();
                    myDate = DateFormat('dd/MM/yyyy,hh:mm').format(date);
                  }
                  final statusWidget = Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 2,
                          child: Text(
                            myDate,
                            style: regular,
                          ),
                        ),
                        Flexible(
                            flex: 3, child: Text(status['status_content'])),
                        Flexible(
                          flex: 1,
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey,
                                  borderRadius: BorderRadius.circular(48),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(48),
                                  child: FutureBuilder<Map<String, dynamic>>(
                                    future:
                                        getUserDetails(status['updated_by']),
                                    builder: (context, userSnapshot) {
                                      if (userSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }

                                      if (userSnapshot.hasError) {
                                        return Text(
                                            'Error: ${userSnapshot.error}');
                                      }

                                      if (!userSnapshot.hasData ||
                                          userSnapshot.data!.isEmpty) {
                                        return Text(
                                            'User details not available.');
                                      }

                                      // User details are ready
                                      Map<String, dynamic> userDetails =
                                          userSnapshot.data!;

                                      return Image.network(
                                        userDetails['profile_path'],
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                  statusUpdates.add(statusWidget);
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Column(
                    children: statusUpdates,
                  ),
                );
              },
            ),
          ),
          Flexible(
            flex: 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: InputField(
                      placeholder: "Type incident status here...",
                      inputType: "text",
                      controller: _incidentStatusController,),
                ),
                SizedBox(
                  width: 8,
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: InputButton(
                      label: "UPDATE",
                      function: () {
                        addLiveStatusToIncident(widget.incident_id,
                            _incidentStatusController.text.trim());
                    
                        setState(() {
                          _incidentStatusController.text == "";
                        });
                      },
                      large: true,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class ChatroomContainer extends StatefulWidget {
  final String incident_id;
  const ChatroomContainer({Key? key, required this.incident_id})
      : super(key: key);

  @override
  _ChatroomContainerState createState() => _ChatroomContainerState();
}

class _ChatroomContainerState extends State<ChatroomContainer> {
  final _messageController = TextEditingController();

  void sendMessage() async {
    if (_messageController.text.isEmpty) {
      Utilities.showSnackBar("Please enter a message", Colors.red);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.incident_id)
          .collection('chatroom')
          .add({
        'content': _messageController.text.trim(),
        'sent_by': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'text',
      });
      setState(() {
        _messageController.text = "";
      });
    } catch (error) {
      print('Error adding message to chatroom: $error');
      throw error;
    }

    try {} catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 1,
            child: Text(
              "Incident Chatroom",
              style: subheading,
            ),
          ),
          Flexible(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('incidents')
                      .doc(widget.incident_id)
                      .collection('chatroom')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator(); // or another loading indicator
                    }

                    // If there are no documents, display a message
                    if (snapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No messages yet.'));
                    }

                    List<Widget> chatWidgets = [];
                    final messages = snapshot.data?.docs.toList();

                    for (var message in messages!) {
                      final Widget chatWidget;
                      if (message['sent_by'] ==
                          FirebaseAuth.instance.currentUser?.uid) {
                        chatWidget = Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.only(top: 4, bottom: 4),
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: accentColor),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  message['content'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        chatWidget = Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(48),
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(
                              width: 8,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Color(0xFFF3F4F4),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  message['content'],
                                  style: regular,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      chatWidgets.add(chatWidget);
                    }
                    return Column(
                      children: chatWidgets,
                    );
                  }),
            ),
          ),
          Flexible(
            flex: 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: TextFormField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type your message here...",
                      contentPadding: EdgeInsets.all(8),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFFEBEBEB),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(64),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: accentColor,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(64),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 8,
                ),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      sendMessage();
                    },
                    child: Text("SEND"),
                    style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(accentColor),
                      foregroundColor: MaterialStatePropertyAll(Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IncidentTagDialog extends StatefulWidget {
  final String incident_id;
  final VoidCallback onUpdate;
  const IncidentTagDialog(
      {Key? key, required this.incident_id, required this.onUpdate})
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

      // Check if the tag name already exists in the collection
      QuerySnapshot existingTagsSnapshot = await incidentTagsCollection
          .where('tag_name', isEqualTo: tagName)
          .get();

      if (existingTagsSnapshot.docs.isNotEmpty) {
        // Tag name already exists
        Utilities.showSnackBar("This tag already exists", Colors.red);
        return;
      } else {
        // Tag name does not exist, add a new incident tag
        DocumentReference newDocRef = await incidentTagsCollection.add({
          'tag_name': tagName,
          'priority': "Low",
          // Add more fields as needed
        });

        await updateIncidentTag(widget.incident_id, newDocRef.id);

        print('Incident tag added successfully');
        Utilities.showSnackBar("Tag added successfully", Colors.green);
      }
    } catch (error) {
      print('Error adding or updating incident tag: $error');
      throw error; // Propagate the error if needed
    }
  }

  Future<void> updateIncidentTag(String incident_id, String newTagName) async {
    try {
      // Reference to the 'incident_tags' collection
      CollectionReference incidentTagsCollection =
          FirebaseFirestore.instance.collection('incidents');

      // Update the document with the specified tagId
      await incidentTagsCollection.doc(incident_id).update({
        'incident_tag': newTagName,
        // Update more fields as needed
      });

      print('Incident tag updated successfully');
    } catch (error) {
      print('Error updating incident tag: $error');
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
              "Select an incident tag from the dropdown below",
              style: regular,
            ),
            FutureBuilder(
              future: getIncidentTags(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Data is still loading
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  // Error occurred while fetching data
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  // No data available
                  return Text('No incident tags found.');
                } else {
                  // Data has been successfully fetched
                  List<Map<String, dynamic>> incidentTags = snapshot.data!;

                  return DropdownMenu(
                    onSelected: (value) {
                      _dropdownValue = value;
                    },
                    dropdownMenuEntries:
                        incidentTags.map((Map<String, dynamic> tag) {
                      return DropdownMenuEntry(
                          value: tag['tag_id'], label: tag['tag_name']);
                    }).toList(),
                  );
                }
              },
            ),
            Text(
              "or add a new incident tag",
              style: regular_minor,
            ),
            InputField(
                placeholder: "Incident Tag Name",
                inputType: "text",
                controller: _incidentTagController),
            InputButton(
                label: "DONE",
                function: () async {
                  if (_dropdownValue.isEmpty &&
                      _incidentTagController.text.isEmpty) {
                    Utilities.showSnackBar("Missing fields", Colors.red);
                    return;
                  }

                  if (!_dropdownValue.isEmpty &&
                      _incidentTagController.text.isEmpty) {
                    print(_dropdownValue);
                    await updateIncidentTag(widget.incident_id, _dropdownValue);
                    widget.onUpdate();
                    Utilities.showSnackBar(
                        "Successfully updated tag", Colors.green);
                    Navigator.of(context).pop();
                  } else if (_dropdownValue.isEmpty &&
                      !_incidentTagController.text.isEmpty) {
                    await addIncidentTag(
                        _incidentTagController.text.trim(), "Low");
                    widget.onUpdate();
                    Navigator.of(context).pop();
                  } else {
                    Utilities.showSnackBar(
                        "Both fields must not be populated", Colors.red);
                  }
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

class IncidentStatusDialog extends StatefulWidget {
  final String incident_id;
  final VoidCallback onUpdate;
  const IncidentStatusDialog(
      {Key? key, required this.incident_id, required this.onUpdate})
      : super(key: key);

  @override
  _IncidentStatusDialogState createState() => _IncidentStatusDialogState();
}

class _IncidentStatusDialogState extends State<IncidentStatusDialog> {
  String _dropdownValue = "Verifying";
  Future<void> updateIncidentStatus(
      String incident_id, String new_status) async {
    try {
      String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      // Ensure the user is authenticated before proceeding
      if (currentUserId.isEmpty) {
        print('User not authenticated.');
        return;
      }

      // Reference to the 'incident_tags' collection
      CollectionReference incidentCollection =
          FirebaseFirestore.instance.collection('incidents');

      // Update the document with the specified tagId
      await incidentCollection.doc(incident_id).update({
        'status': new_status,
        // Update more fields as needed
      });

      await incidentCollection.doc(incident_id).collection('live_status').add({
        'status_content': "Incident status changed to $new_status",
        'timestamp': FieldValue.serverTimestamp(),
        'updated_by': currentUserId,
        // Add more fields as needed
      });

      print('Incident  status updated successfully');
    } catch (error) {
      print('Error updating Incident  status: $error');
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
            DropdownMenu(
              initialSelection: _dropdownValue,
              onSelected: (value) {
                _dropdownValue = value!;
              },
              dropdownMenuEntries: [
                DropdownMenuEntry(value: "Verifying", label: "Verifying"),
                DropdownMenuEntry(value: "Addressing", label: "Addressing"),
                DropdownMenuEntry(value: "Closed", label: "Closed"),
              ],
            ),
            InputButton(
                label: "UPDATE",
                function: () {
                  if (_dropdownValue.isEmpty) {
                    Utilities.showSnackBar(
                        "You must select a status first", Colors.red);
                    return;
                  }

                  updateIncidentStatus(widget.incident_id, _dropdownValue);
                  Utilities.showSnackBar(
                      "Successfully updated incident status", Colors.green);
                  widget.onUpdate();
                  Navigator.of(context).pop();
                },
                large: false),
          ],
        ),
      ),
    );
  }
}

class AddTanodDialog extends StatefulWidget {
  final String incident_id;
  final VoidCallback onUpdate;
  const AddTanodDialog(
      {Key? key, required this.incident_id, required this.onUpdate})
      : super(key: key);

  @override
  _AddTanodDialogState createState() => _AddTanodDialogState();
}

class _AddTanodDialogState extends State<AddTanodDialog> {
  Future<List<Map<String, dynamic>>> fetchTanods() async {
    List<Map<String, dynamic>> tanods = [];

    try {
      // Fetch all users with 'tanod' user_type
      QuerySnapshot tanodsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('user_type', isEqualTo: 'tanod')
          .get();

      if (tanodsSnapshot.docs.isNotEmpty) {
        // Fetch all user IDs from the responders array in incidents
        Set<String> respondersUserIds = Set<String>();

        // QuerySnapshot incidentsSnapshot =
        //     await FirebaseFirestore.instance.collection('incidents').get();
        // for (var incidentDocument in incidentsSnapshot.docs) {
        //   List<String> responders =
        //       List<String>.from(incidentDocument['responders'] ?? []);
        //   respondersUserIds.addAll(responders);
        // }

        DocumentSnapshot incidentSnapshot = await FirebaseFirestore.instance
            .collection('incidents')
            .doc(widget.incident_id)
            .get();

        if (incidentSnapshot.exists) {
          List<String> responders =
              List<String>.from(incidentSnapshot['responders'] ?? []);
          tanods = tanodsSnapshot.docs
              .where((tanodDocument) => !responders.contains(tanodDocument.id))
              .map((tanodDocument) {
            return {
              'uID': tanodDocument.id,
              'profile_path': tanodDocument['profile_path'],
              'first_name': tanodDocument['first_name'],
              'last_name': tanodDocument['last_name'],
              'contact_no': tanodDocument['contact_no'],
              // Add more fields as needed
            };
          }).toList();
        } else {
          print('Incident document does not exist.');
        }

        // Filter tanods based on user IDs found in the responders array
      } else {
        print('No tanods found in the users collection.');
      }
    } catch (error) {
      print('Error fetching tanods: $error');
      throw error; // Propagate the error if needed
    }

    return tanods;
  }

  Future<void> addUserToResponders(String incidentId, String userId) async {
    try {
      // Reference to the specific incident document
      DocumentReference incidentDocRef =
          FirebaseFirestore.instance.collection('incidents').doc(incidentId);

      // Get the current responders array
      DocumentSnapshot incidentSnapshot = await incidentDocRef.get();
      List<String> currentResponders =
          List<String>.from(incidentSnapshot['responders'] ?? []);

      // Check if the user is not already in the responders array
      if (!currentResponders.contains(userId)) {
        // Add the user ID to the responders array
        currentResponders.add(userId);

        // Update the incident document with the new responders array
        await incidentDocRef.update({'responders': currentResponders});

        print(
            'User with ID $userId added to responders for incident ID $incidentId');
      } else {
        print(
            'User with ID $userId is already in responders for incident ID $incidentId');
      }
    } catch (error) {
      print('Error adding user to responders: $error');
      throw error; // Propagate the error if needed
    }
  }

  String _dropdownValue = "test";
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Assign Tanod"),
      content: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Select a tanod from the dropdown menu",
              style: regular,
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchTanods(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Data is still loading
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  // Error occurred while fetching data
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  // No data available
                  return Text('No tanods available');
                } else {
                  // Data has been successfully fetched
                  List<Map<String, dynamic>> respondersDetails = snapshot.data!;

                  return DropdownMenu<String>(
                    // You can use a different type based on your data structure
                    onSelected: (String? newValue) {
                      _dropdownValue = newValue!;
                    },
                    dropdownMenuEntries:
                        respondersDetails.map((Map<String, dynamic> responder) {
                      return DropdownMenuEntry<String>(
                        value:
                            responder['uID'] as String, // Use uID as the value
                        label:
                            '${responder['first_name']} ${responder['last_name']}',
                      );
                    }).toList(),
                  );
                }
              },
            ),
            InputButton(
                label: "DONE",
                function: () {
                  if (_dropdownValue.isEmpty || _dropdownValue == "test") {
                    Utilities.showSnackBar(
                        "Please select a user first", Colors.red);
                    return;
                  } else {
                    addUserToResponders(widget.incident_id, _dropdownValue);
                    Utilities.showSnackBar(
                        "Successfully assigned tanod to this incident",
                        Colors.green);
                    widget.onUpdate();
                    Navigator.of(context).pop();
                  }
                },
                large: false),
            Text(
              "Or add a new tanod",
              style: regular_minor,
            ),
            TextButton(
              onPressed: () {
                context.go('/users');
                Navigator.of(context).pop();
              },
              child: Text("Add New Tanod"),
            ),
          ],
        ),
      ),
    );
  }
}

class AssignedTanodContainer extends StatefulWidget {
  final String user_id;
  final String profile_path;
  final String name;
  final String user_type;
  final String contact_no;
  final VoidCallback onDelete;
  const AssignedTanodContainer(
      {Key? key,
      required this.user_id,
      required this.name,
      required this.user_type,
      required this.contact_no,
      required this.onDelete,
      required this.profile_path})
      : super(key: key);

  @override
  _AssignedTanodContainerState createState() => _AssignedTanodContainerState();
}

class _AssignedTanodContainerState extends State<AssignedTanodContainer> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(48),
                  color: Colors.grey,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(48),
                  child: Image.network(
                    widget.profile_path,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(
                width: 8,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: regular,
                  ),
                  Text(
                    widget.user_type.toUpperCase(),
                    style: regular_minor,
                  ),
                ],
              ),
            ],
          ),
          Text(widget.contact_no),
          GestureDetector(
            onTap: () {
              widget.onDelete();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.red,),
              child: Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddStatusDialog extends StatefulWidget {
  final VoidCallback onAdd;
  const AddStatusDialog({Key? key, required this.onAdd}) : super(key: key);

  @override
  _AddStatusDialogState createState() => _AddStatusDialogState();
}

class _AddStatusDialogState extends State<AddStatusDialog> {
  final _statusController = TextEditingController();

  void addStatus() async {
    if (_statusController.text.isEmpty) {
      Utilities.showSnackBar("You must enter a status", Colors.red);
      return;
    }
    try {
      // Reference to the 'user_defined_statuses' collection
      CollectionReference statusesCollection =
          FirebaseFirestore.instance.collection('user_defined_statuses');

      QuerySnapshot existingStatusSnapshot = await statusesCollection
          .where('status_content', isEqualTo: _statusController.text.trim())
          .get();

      if (existingStatusSnapshot.docs.isNotEmpty) {
        // Status content already exists, show a snackbar
        Utilities.showSnackBar("Tag is already existing", Colors.red);
        return;
      } else {
        // Status content does not exist, add a new user-defined status
        await statusesCollection.add({
          'status_content': _statusController.text.trim(),
          // Add more fields as needed
        });

        print('User-defined status added successfully.');
        Utilities.showSnackBar(
            "User-defined status added successfully", Colors.green);
      }
    } catch (error) {
      print('Error adding user-defined status: $error');
      throw error; // Propagate the error if needed
    }
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Status"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InputField(
            placeholder: "Status Text",
            inputType: "text",
            controller: _statusController,
          ),
          InputButton(
              label: "Add Status",
              function: () {
                addStatus();

                widget.onAdd();
                Navigator.of(context).pop();
              },
              large: false),
        ],
      ),
    );
  }
}
