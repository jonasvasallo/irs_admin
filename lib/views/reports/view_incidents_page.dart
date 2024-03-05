import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:irs_admin/core/constants.dart';
import 'package:irs_admin/core/utilities.dart';
import 'package:irs_admin/widgets/input_button.dart';

class ViewIncidentsPage extends StatefulWidget {
  const ViewIncidentsPage({Key? key}) : super(key: key);

  @override
  _ViewIncidentsPageState createState() => _ViewIncidentsPageState();
}

class _ViewIncidentsPageState extends State<ViewIncidentsPage> {
  void deleteIncident(String incident_id) async {
    try {
      await FirebaseFirestore.instance
          .collection("incidents")
          .doc(incident_id)
          .delete();
      print('Document successfully deleted');
      Utilities.showSnackBar("Incident successfully deleted", Colors.green);
    } catch (e) {
      Utilities.showSnackBar("$e", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Incidents"),
      ),
      body: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            // Container(
            //   width: double.infinity,
            //   height: 400,
            //   color: Colors.grey,
            // ),
            // SizedBox(
            //   height: 32,
            // ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      "Incidents",
                      style: subheading,
                    ),
                    Text(
                      "View incidents reported by residents here",
                      style: regular_minor,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 120,
                        child: InputButton(
                            label: "Add Incident",
                            function: () {
                              context.go('/reports/add');
                            },
                            large: false),
                      ),
                    ),
                    StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('incidents')
                          .snapshots(),
                      builder: (context, snapshot) {
                        List<DataRow> incidentList = [];
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Text("Error: ${snapshot.error}");
                        }

                        if (!snapshot.hasData) {
                          return Text("No data available");
                        }

                        final incidents = snapshot.data?.docs.toList();

                        Future<String> getTagName(String incidentTagID) async {
                          final tagDocument = await FirebaseFirestore.instance
                              .collection('incident_tags')
                              .doc(incidentTagID)
                              .get();

                          // Check if the document exists and contains 'tag_name' field
                          if (tagDocument.exists &&
                              tagDocument.data() != null) {
                            return tagDocument['tag_name'];
                          } else {
                            return 'Unknown Tag'; // Default value or handle accordingly
                          }
                        }

                        Future<String> getPriority(String incidentTagID) async {
                          final tagDocument = await FirebaseFirestore.instance
                              .collection('incident_tags')
                              .doc(incidentTagID)
                              .get();

                          // Check if the document exists and contains 'tag_name' field
                          if (tagDocument.exists &&
                              tagDocument.data() != null) {
                            return tagDocument['priority'];
                          } else {
                            return 'Unknown'; // Default value or handle accordingly
                          }
                        }

                        for (var incident in incidents!) {
                          String myDate = "test";

                          if (incident['timestamp'] != null) {
                            Timestamp t = incident['timestamp'] as Timestamp;
                            DateTime date = t.toDate();
                            myDate =
                                DateFormat('dd/MM/yyyy,hh:mm').format(date);
                          }
                          final incidentRow = DataRow(
                            cells: [
                              DataCell(Text(incident.id)),
                              DataCell(Text(incident['title'])),
                              DataCell(Text(incident['location_address'])),
                              DataCell(Text(myDate)),
                              DataCell(FutureBuilder<String>(
                                future: getTagName(incident['incident_tag']),
                                builder: (context, tagSnapshot) {
                                  if (tagSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  }

                                  if (tagSnapshot.hasError) {
                                    return Text("Error: ${tagSnapshot.error}");
                                  }

                                  return Text(
                                      tagSnapshot.data ?? 'Unknown Tag');
                                },
                              )),
                              DataCell(
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        context.go(
                                            '/reports/details/${incident.id}');
                                      },
                                      child: Icon(Icons.remove_red_eye),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text(
                                                  "Are you sure you want to delete this post?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () async {
                                                    deleteIncident(incident.id);
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text("Delete"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Icon(Icons.delete),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          );

                          incidentList.add(incidentRow);
                        }

                        return DataTable(headingTextStyle: regular,dividerThickness: 2,dataRowMinHeight: 44,columnSpacing: 12,columns: [
                          DataColumn(label: Text("Incident ID")),
                          DataColumn(label: Text("Title")),
                          DataColumn(label: Text("Location Address")),
                          DataColumn(label: Text("Date Time")),
                          DataColumn(label: Text("Incident Tag")),
                          DataColumn(label: Text("Action")),
                        ], rows: incidentList);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
