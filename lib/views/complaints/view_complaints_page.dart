import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:irs_admin/core/constants.dart';
import 'package:irs_admin/core/input_validator.dart';
import 'package:irs_admin/core/utilities.dart';
import 'package:irs_admin/widgets/input_button.dart';
import 'package:irs_admin/widgets/input_field.dart';

class ViewComplaintsPage extends StatefulWidget {
  const ViewComplaintsPage({Key? key}) : super(key: key);

  @override
  _ViewComplaintsPageState createState() => _ViewComplaintsPageState();
}

class _ViewComplaintsPageState extends State<ViewComplaintsPage> {
  void deleteComplaint(String complaint_id) async {
    try {
      await FirebaseFirestore.instance
          .collection("complaints")
          .doc(complaint_id)
          .delete();
      print('Document successfully deleted');
      Utilities.showSnackBar("Complaint successfully deleted", Colors.green);
    } catch (e) {
      Utilities.showSnackBar("$e", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Complaints"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: MediaQuery.sizeOf(context).width * 0.80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Complaints",
                    style: subheading,
                  ),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AddComplaintDialog();
                        },
                      );
                    },
                    child: Text("Add"),
                  ),
                  StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('complaints')
                          .snapshots(),
                      builder: (context, snapshot) {
                        List<DataRow> scheduledMediations = [];

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
                        List<DataRow> complaintsRows = [];

                        final complaints = snapshot.data?.docs.toList();

                        for (var complaint in complaints!) {
                          String myDate = "Date Error";

                          if (complaint['issued_at'] != null) {
                            Timestamp t = complaint['issued_at'] as Timestamp;
                            DateTime date = t.toDate();
                            myDate =
                                DateFormat('dd/MM/yyyy,hh:mm').format(date);
                          }
                          final complaintRow = DataRow(cells: [
                            DataCell(Text(complaint.id)),
                            DataCell(Text(complaint['full_name'])),
                            DataCell(Text(complaint['contact_no'])),
                            DataCell(Text(complaint['email'])),
                            DataCell(Text(myDate)),
                            DataCell(Text(complaint['status'])),
                            DataCell(
                              FutureBuilder(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(complaint['issued_by'])
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
                                  Map<String, dynamic> userData = snapshot.data!
                                      .data() as Map<String, dynamic>;
                                  return Text(
                                    "${userData['first_name']} ${userData['last_name']}",
                                  );
                                },
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  TextButton(
                                      onPressed: () {
                                        context.go(
                                            '/complaints/details/${complaint.id}');
                                      },
                                      child: Icon(Icons.remove_red_eye)),
                                  TextButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: Text(
                                                  "Are you sure you want to delete this complaint?"),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                  child: Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    deleteComplaint(
                                                        complaint.id);
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: Text("Delete"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      child: Icon(Icons.delete)),
                                ],
                              ),
                            ),
                          ]);
                          complaintsRows.add(complaintRow);
                        }
                        return DataTable(columns: [
                          DataColumn(label: Text("Complaint ID")),
                          DataColumn(label: Text("Full Name")),
                          DataColumn(label: Text("Contact Number")),
                          DataColumn(label: Text("Email Address")),
                          DataColumn(label: Text("Issued at")),
                          DataColumn(label: Text("Status")),
                          DataColumn(label: Text("Issued by")),
                          DataColumn(label: Text("Action")),
                        ], rows: complaintsRows);
                      })
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AddComplaintDialog extends StatefulWidget {
  const AddComplaintDialog({Key? key}) : super(key: key);

  @override
  _AddComplaintDialogState createState() => _AddComplaintDialogState();
}

class _AddComplaintDialogState extends State<AddComplaintDialog> {
  final _complainantName = TextEditingController();
  final _complainantNo = TextEditingController();
  final _complainantEmail = TextEditingController();
  final _complainantAddress = TextEditingController();
  final _complaintDescription = TextEditingController();

  final _respondentName = TextEditingController();
  final _respondentNo = TextEditingController();
  final _respondentAddress = TextEditingController();

  List<Widget> media_photos = [];
  int imageCounts = 0;

  String selectFile = "";
  // XFile file;
  List<Uint8List> pickedImagesInBytes = [];

  final formKey = GlobalKey<FormState>();

  _selectFile(bool imageFrom) async {
    FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );

    if (fileResult != null) {
      setState(() {
        selectFile = fileResult.files.first.name;
        fileResult.files.forEach((element) {
          setState(() {
            pickedImagesInBytes.add(element.bytes!);
            media_photos.add(
              Padding(
                padding: const EdgeInsets.only(right: 8, left: 8),
                child: Container(
                  width: 300,
                  height: 150,
                  color: Colors.black,
                  child: Image.memory(element.bytes!),
                ),
              ),
            );
            imageCounts++;
          });
        });
      });
    }
    print(selectFile);
  }

  Future<List<String>> _uploadMultipleFiles(String itemName) async {
    List<String> imageUrls = [];
    String imageUrl = "";
    try {
      for (var i = 0; i < imageCounts; i++) {
        print("iteration $i");
        UploadTask uploadTask;

        Reference ref = FirebaseStorage.instance
            .ref()
            .child('complaints_documents')
            .child('/${itemName}_$i');

        final metadata = SettableMetadata(contentType: 'image/jpeg');

        uploadTask = ref.putData(pickedImagesInBytes[i], metadata);
        await uploadTask.whenComplete(() => null);
        imageUrl = await ref.getDownloadURL();
        print(imageUrl);
        imageUrls.add(imageUrl);
      }

      return imageUrls;
    } catch (ex) {
      print('Error uploading image to Firestore: $ex');
      throw ex;
    }
  }

  void addComplaint() async {
    final isValid = formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    try {
      List<String> imageUrls = [];
      if (pickedImagesInBytes.length > 0) {
        imageUrls = await _uploadMultipleFiles("${_complainantName.text}_${FirebaseAuth.instance.currentUser?.uid}");
        print(imageUrls);
      }
      CollectionReference complaintsCollection =
          FirebaseFirestore.instance.collection('complaints');

      await complaintsCollection.add({
        'full_name' : _complainantName.text.trim(),
        'contact_no' : _complainantNo.text.trim(),
        'email' : _complainantEmail.text.trim(),
        'address' : _complainantAddress.text.trim(),
        'respondent_info' : [_respondentName.text.trim(), _respondentNo.text.trim(), _respondentAddress.text.trim(),],
        'description' : _complaintDescription.text.trim(),
        'supporting_docs' : imageUrls,
        'issued_at' : FieldValue.serverTimestamp(),
        'issued_by' : FirebaseAuth.instance.currentUser?.uid,
        'status' : "Open",
      });
      Utilities.showSnackBar("Successfully posted", Colors.green);
      Navigator.of(context).pop();
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    }
  }

  @override
  void dispose() {
    _complainantAddress.dispose();
    _complainantEmail.dispose();
    _complainantName.dispose();
    _complainantNo.dispose();
    _complaintDescription.dispose();
    _respondentAddress.dispose();
    _respondentName.dispose();
    _respondentNo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Complaint"),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InputField(
                        placeholder: "Complainant Name",
                        inputType: "text",
                        controller: _complainantName,
                        label: "Complainant Name",
                        validator: InputValidator.requiredValidator,
                      ),
                      InputField(
                        placeholder: "Complainant Contact No.",
                        inputType: "phone",
                        controller: _complainantNo,
                        label: "Complainant Contact No.",
                        validator: InputValidator.phoneValidator,
                      ),
                      InputField(
                        placeholder: "Complainant Email Address",
                        inputType: "email",
                        controller: _complainantEmail,
                        label: "Complainant Email Address",
                      ),
                      InputField(
                        placeholder: "Complainant Address",
                        inputType: "text",
                        controller: _complainantAddress,
                        label: "Complainant Address",
                        validator: InputValidator.requiredValidator,
                      )
                    ],
                  ),
                ),
                SizedBox(width: 8,),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      InputField(
                        placeholder: "Respondent Name",
                        inputType: "text",
                        controller: _respondentName,
                        label: "Complainant Name",
                        validator: InputValidator.requiredValidator,
                      ),
                      InputField(
                          placeholder: "Respondent Contact No.",
                          inputType: "phone",
                          controller: _respondentNo,
                          label: "Complainant Contact No."),
                      InputField(
                        placeholder: "Respondent Address",
                        inputType: "text",
                        controller: _respondentAddress,
                        label: "Respondent Address",
                        validator: InputValidator.requiredValidator,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            InputField(
              placeholder: "Nature of the Complaint",
              inputType: "message",
              controller: _complaintDescription,
              label: "Description",
              validator: InputValidator.requiredValidator,
            ),
            TextButton(
              onPressed: () {
                _selectFile(true);
              },
              child: Text("Add Supporting Documents"),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: media_photos,
              ),
            ),
            InputButton(label: "Add Complaint", function: (){
              addComplaint();
            }, large: true),
          ],
        ),
      ),
    );
  }
}
