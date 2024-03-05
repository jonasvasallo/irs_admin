import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:irs_admin/core/constants.dart';
import 'package:irs_admin/core/utilities.dart';
import 'package:irs_admin/widgets/input_button.dart';

class SosDetailsPage extends StatefulWidget {
  final String id;
  const SosDetailsPage({Key? key, required this.id}) : super(key: key);

  @override
  _SosDetailsPageState createState() => _SosDetailsPageState();
}

class _SosDetailsPageState extends State<SosDetailsPage> {
  Future<List<Map<String, dynamic>>> fetchRespondersDetails() async {
    List<Map<String, dynamic>> respondersDetails = [];

    try {
      // Fetch the incident document
      DocumentSnapshot incidentSnapshot = await FirebaseFirestore.instance
          .collection('sos')
          .doc(widget.id)
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
        print('Incident with ID ${widget.id} not found');
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
          FirebaseFirestore.instance.collection('sos').doc(incidentId);

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
        title: Text("Emergency SOS Details"),
        leading: TextButton(
          child: Icon(
            Icons.chevron_left,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(32),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          width: MediaQuery.of(context).size.width * 0.70,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('sos')
                          .doc(widget.id)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          // Data is still loading
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          // Error occurred while fetching data
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData) {
                          // No data available
                          return Text('No sos detail found.');
                        }
                        Map<String, dynamic> sosDetails =
                            snapshot.data!.data() as Map<String, dynamic>;

                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 400,
                              color: Colors.grey,
                              child: GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                      target: LatLng(
                                          sosDetails['location']['latitude'],
                                          sosDetails['location']['longitude']),
                                      zoom: 18),
                                  circles: Set.from([
                                    Circle(
                                      circleId: CircleId("customCircle"),
                                      center: LatLng(
                                          sosDetails['location']['latitude'],
                                          sosDetails['location']['longitude']),
                                      radius: 5, // Radius in meters
                                      fillColor:
                                          Color.fromARGB(255, 255, 0, 0),
                                      strokeColor: Color.fromARGB(255, 156, 0, 0),
                                      strokeWidth: 2,
                                    ),
                                  ])),
                            ),
                            SizedBox(
                              height: 24,
                            ),
                            FutureBuilder(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(sosDetails['user_id'])
                                  .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  // Data is still loading
                                  return CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  // Error occurred while fetching data
                                  return Text('Error: ${snapshot.error}');
                                } else if (!snapshot.hasData) {
                                  // No data available
                                  return Text('No user detail found.');
                                }
                                Map<String, dynamic> userDetails =
                                    snapshot.data!.data()
                                        as Map<String, dynamic>;
                                return Row(
                                  children: [
                                    SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: ClipRRect(
                                        child: Image.network(
                                          userDetails['profile_path'],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 8,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${userDetails['first_name']} ${userDetails['last_name']}",
                                          style: regular,
                                        ),
                                        Text(
                                          userDetails['gender'],
                                          style: regular,
                                        ),
                                        Text(
                                          userDetails['contact_no'],
                                          style: regular_minor,
                                        ),
                                      ],
                                    )
                                  ],
                                );
                              },
                            ),
                            Row(
                              children: [
                                Text(sosDetails['status']),
                                TextButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return IncidentStatusDialog(
                                          incident_id: widget.id,
                                          onUpdate: () {
                                            setState(() {});
                                            context.go('/sos');
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: Text("Change"),
                                ),
                              ],
                            ),
                            Column(
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
                                                incident_id: widget.id,
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
                                        return Text("Error ${snapshot.error}");
                                      }
                                      if (!snapshot.hasData ||
                                          snapshot.data!.isEmpty) {
                                        // No data available
                                        return Text(
                                            'No personnel assigned yet');
                                      }

                                      List<Map<String, dynamic>>
                                          respondersDetails = snapshot.data!;
                                      List<Widget> respondersList = [];
                                      for (var responder in respondersDetails) {
                                        final responderWidget =
                                            AssignedTanodContainer(
                                                user_id: responder['uID'],
                                                name:
                                                    "${responder['first_name']} ${responder['last_name']}",
                                                user_type:
                                                    responder['user_type'],
                                                contact_no:
                                                    responder['contact_no'],
                                                onDelete: () {
                                                  removeUserFromResponders(
                                                      widget.id,
                                                      responder['uID']);
                                                  setState(() {});
                                                },
                                                profile_path:
                                                    responder['profile_path']);
                                        respondersList.add(responderWidget);
                                      }

                                      return Column(
                                        children: respondersList,
                                      );
                                    } else {
                                      return Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                  },
                                )
                              ],
                            )
                          ],
                        );
                      }),
                ),
                SizedBox(
                  width: 16,
                ),
                Expanded(
                  child: ChatroomContainer(incident_id: widget.id),
                ),
              ],
            ),
          ),
        ),
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
          .collection('sos')
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
              "Emergency Chatroom",
              style: subheading,
            ),
          ),
          Flexible(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('sos')
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
                        chatWidget = Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
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
            .collection('sos')
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
          FirebaseFirestore.instance.collection('sos').doc(incidentId);

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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.red,
              ),
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
  String _dropdownValue = "Active";
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
          FirebaseFirestore.instance.collection('sos');

      // Update the document with the specified tagId
      await incidentCollection.doc(incident_id).update({
        'status': new_status,
        // Update more fields as needed
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
                DropdownMenuEntry(value: "Active", label: "Active"),
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
                      "Successfully updated SOS status", Colors.green);
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
