import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:irs_admin/core/constants.dart';
import 'package:irs_admin/core/utilities.dart';
import 'package:irs_admin/widgets/input_button.dart';

class ComplaintDetailsPage extends StatefulWidget {
  final String complaint_id;
  const ComplaintDetailsPage({Key? key, required this.complaint_id})
      : super(key: key);

  @override
  _ComplaintDetailsPageState createState() => _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends State<ComplaintDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Complaint Details"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: MediaQuery.sizeOf(context).width * 0.50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection('complaints')
                    .doc(widget.complaint_id)
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // If the Future is still running, show a loading indicator
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    // If there's an error, display it to the user
                    return Text('Error: ${snapshot.error}');
                  }
                  Map<String, dynamic> complaintData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  List<dynamic> respondentInfo =
                      complaintData['respondent_info'];
                  String myDate = "Date Error";

                  if (complaintData['issued_at'] != null) {
                    Timestamp t = complaintData['issued_at'] as Timestamp;
                    DateTime date = t.toDate();
                    myDate = DateFormat('dd/MM/yyyy hh:mm').format(date);
                  }
                  List<Widget> supportingDocs = [];
                  for (var document in complaintData['supporting_docs']) {
                    final docWidget = Container(
                      width: 300,
                      height: 200,
                      color: Colors.grey,
                      child: Image.network(
                        document,
                        fit: BoxFit.cover,
                      ),
                    );
                    supportingDocs.add(docWidget);
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Complaint ID",
                        style: regular,
                      ),
                      Text(
                        widget.complaint_id,
                        style: regular_minor,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Complainant Info",
                                style: subheading,
                              ),
                              Text(
                                complaintData['full_name'],
                                style: regular,
                              ),
                              Text(
                                complaintData['contact_no'],
                                style: regular,
                              ),
                              Text(
                                complaintData['email'] ?? 'N/A',
                                style: regular,
                              ),
                              Text(
                                complaintData['address'],
                                style: regular,
                              ),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Respondent Info",
                                style: subheading,
                              ),
                              Text(
                                respondentInfo[0].toString(),
                                style: regular,
                              ),
                              Text(
                                respondentInfo[1].toString() ?? 'Unknown',
                                style: regular,
                              ),
                              Text(
                                respondentInfo[2].toString() ?? 'Unknown',
                                style: regular,
                              ),
                            ],
                          ),
                        ],
                      ),
                      FutureBuilder(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(complaintData['issued_by'])
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            // If the Future is still running, show a loading indicator
                            return CircularProgressIndicator();
                          } else if (snapshot.hasError) {
                            // If there's an error, display it to the user
                            return Text('Error: ${snapshot.error}');
                          }
                          Map<String, dynamic> userData =
                      snapshot.data!.data() as Map<String, dynamic>;
                          return Text(
                            "Issued by: ${userData['first_name']} ${userData['last_name']}",
                            style: regular,
                          );
                        },
                      ),
                      Text(
                        myDate,
                        style: regular,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            complaintData['status'],
                            style: regular,
                          ),
                          TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return ComplaintStatusDialog(
                                      complaint_id: widget.complaint_id,
                                      onUpdate: () {
                                        setState(() {});
                                      },
                                    );
                                  },
                                );
                              },
                              child: Text("Change")),
                        ],
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      Text(
                        "Nature of Complaint",
                        style: subheading,
                      ),
                      Text(
                        complaintData['description'],
                        style: regular,
                      ),
                      SizedBox(
                        height: 16,
                      ),
                      Text(
                        "Supporting Documents",
                        style: subheading,
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: supportingDocs,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ComplaintStatusDialog extends StatefulWidget {
  final String complaint_id;
  final VoidCallback onUpdate;
  const ComplaintStatusDialog(
      {Key? key, required this.complaint_id, required this.onUpdate})
      : super(key: key);

  @override
  _ComplaintStatusDialogState createState() => _ComplaintStatusDialogState();
}

class _ComplaintStatusDialogState extends State<ComplaintStatusDialog> {
  String _dropdownValue = "Filed";
  void updateComplaintStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('complaints')
          .doc(widget.complaint_id)
          .update({'status': newStatus});

      print('Complaint status updated successfully.');
      Utilities.showSnackBar(
          "Complaint status updated successfully.", Colors.green);
      widget.onUpdate();
      Navigator.of(context, rootNavigator: true).pop();
    } catch (error) {
      print('Error updating complaint status: $error');
      Utilities.showSnackBar(
          'Error updating complaint status: $error', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Update complaint status"),
          DropdownMenu(
              width: 300,
              initialSelection: "Open",
              onSelected: (value) {
                setState(() {
                  _dropdownValue = value!;
                });
              },
              dropdownMenuEntries: [
                DropdownMenuEntry(value: "Open", label: "Open"),
                DropdownMenuEntry(value: "Pending", label: "Pending"),
                DropdownMenuEntry(value: "Closed", label: "Closed"),
              ]),
          SizedBox(
            width: 300,
            child: InputButton(
                label: "Update",
                function: () {
                  updateComplaintStatus(_dropdownValue);
                },
                large: true),
          ),
        ],
      ),
    );
  }
}
