import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:irs_admin/core/constants.dart';

class ViewSosPage extends StatefulWidget {
  const ViewSosPage({Key? key}) : super(key: key);

  @override
  _ViewSosPageState createState() => _ViewSosPageState();
}

class _ViewSosPageState extends State<ViewSosPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emergencies"),
      ),
      body: Padding(
        padding: EdgeInsets.all(32),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  "Emergencies",
                  style: subheading,
                ),
                Text(
                  "Emergency SOS will be sent here.",
                  style: regular_minor,
                ),
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('sos')
                      .where('status', isEqualTo: 'Active')
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
                      return Center(child: Text('No emergencies yet.'));
                    }
                    List<DataRow> emergencyRows = [];
                    final emergencies = snapshot.data?.docs.toList();

                    for (var emergency in emergencies!) {
                      Future<String> getName(String user_id) async {
                          final tagDocument = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user_id)
                              .get();

                          // Check if the document exists and contains 'tag_name' field
                          if (tagDocument.exists &&
                              tagDocument.data() != null) {
                            return "${tagDocument['first_name']} ${tagDocument['last_name']}";
                          } else {
                            return 'Unknown Tag'; // Default value or handle accordingly
                          }
                        }
                        Future<String> getContact(String user_id) async {
                          final tagDocument = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user_id)
                              .get();

                          // Check if the document exists and contains 'tag_name' field
                          if (tagDocument.exists &&
                              tagDocument.data() != null) {
                            return "${tagDocument['contact_no']}";
                          } else {
                            return 'Unknown Tag'; // Default value or handle accordingly
                          }
                        }
                      String myDate = "test";

                          if (emergency['timestamp'] != null) {
                            Timestamp t = emergency['timestamp'] as Timestamp;
                            DateTime date = t.toDate();
                            myDate =
                                DateFormat('MM/dd/yyyy hh:mm').format(date);
                          }
                      final emergencyWidget = DataRow(cells: [
                        DataCell(Text(emergency.id)),
                        DataCell(
                          FutureBuilder(
                            future: getName(emergency['user_id']),
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

                              

                              return Text(snapshot.data ?? 'Unknown Tag');
                            },
                          ),
                        ),
                        DataCell(
                          FutureBuilder(
                            future: getContact(emergency['user_id']),
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

                              return Text(snapshot.data ?? '');
                            },
                          ),
                        ),
                        DataCell(Text(myDate)),
                        DataCell(TextButton(onPressed: (){
                          context.go('/sos/details/${emergency.id}');
                        }, child: Icon(Icons.remove_red_eye),)),
                      ]);
                      emergencyRows.add(emergencyWidget);
                    }

                    return DataTable(columns: [
                      DataColumn(label: Text("SOS ID")),
                      DataColumn(label: Text("Full Name")),
                      DataColumn(label: Text("Contact Number")),
                      DataColumn(label: Text("Placed At")),
                      DataColumn(label: Text("Action")),
                    ], rows: emergencyRows);
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
