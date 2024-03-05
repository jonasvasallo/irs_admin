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

class UpdateNewsPage extends StatefulWidget {
  final String news_id;
  const UpdateNewsPage({Key? key, required this.news_id}) : super(key: key);

  @override
  _UpdateNewsPageState createState() => _UpdateNewsPageState();
}

class _UpdateNewsPageState extends State<UpdateNewsPage> {
  final _headingController = TextEditingController();
  final _bodyController = TextEditingController();
  List<Widget> media_photos = [];

  final formKey = GlobalKey<FormState>();

  int imageCounts = 0;

  String selectFile = "";
  // XFile file;
  List<Uint8List> pickedImagesInBytes = [];

  Future<Map<String, dynamic>> fetchNewsDetails() async {
    Map<String, dynamic> newsDetails = {};

    try {
      DocumentSnapshot newsSnapshot = await FirebaseFirestore.instance
          .collection('news')
          .doc(widget.news_id)
          .get();

      if (newsSnapshot.exists) {
        newsDetails = newsSnapshot.data() as Map<String, dynamic>;

        String posted_by = newsDetails['posted_by'];
        if (posted_by != null) {
          DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(posted_by)
              .get();
          if (userSnapshot.exists) {
            // Include user details in the incidentDetails map
            newsDetails['user_details'] = userSnapshot.data();
          } else {
            print("User does not exist");
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

    return newsDetails;
  }

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

  Future<List<String>> _uploadMultipleFiles() async {
    List<String> imageUrls = [];
    String imageUrl = "";
    try {
      for (var i = 0; i < imageCounts; i++) {
        UploadTask uploadTask;

        Reference ref = FirebaseStorage.instance
            .ref()
            .child('news_attachments/$selectFile');

        final metadata = SettableMetadata(contentType: 'image/jpeg');

        uploadTask = ref.putData(pickedImagesInBytes[i], metadata);
        await uploadTask.whenComplete(() => null);
        imageUrl = await ref.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      return imageUrls;
    } catch (ex) {
      print('Error uploading image to Firestore: $ex');
      throw ex;
    }
  }

  void updatePost() async {
    InputValidator.checkFormValidity(formKey, context);

    try {
      List<String> imageUrls = [];
      if (pickedImagesInBytes.length > 0) {
        imageUrls = await _uploadMultipleFiles();
      }
      DocumentReference newsCollection =
          FirebaseFirestore.instance.collection('news').doc(widget.news_id);

      await newsCollection.update({
        'heading': _headingController.text.trim(),
        'body': _bodyController.text.trim(),
        'media_attachments': FieldValue.arrayUnion(imageUrls),
      });

      Utilities.showSnackBar("Successfully updated post", Colors.green);
      setState(() {
        _headingController.text = "";
        _bodyController.text = "";
        selectFile = "";
        imageCounts = 0;
        media_photos.clear();
        pickedImagesInBytes.clear();
      });
    } catch (ex) {
      Utilities.showSnackBar("$ex", Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Announcement / News"),
        leading: TextButton(
          child: Icon(
            Icons.chevron_left,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(32),
        child: Align(
          alignment: Alignment.topCenter,
          child: Form(
            key: formKey,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              width: MediaQuery.of(context).size.width * 0.50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: FutureBuilder(
                    future: fetchNewsDetails(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        Map<String, dynamic> newsDetails = snapshot.data!;

                        String myDate = "test";

                        if (newsDetails['timestamp'] != null) {
                          Timestamp t = newsDetails['timestamp'] as Timestamp;
                          DateTime date = t.toDate();
                          myDate = DateFormat('dd/MM/yyyy,hh:mm').format(date);
                        }

                        List<Widget> photos = [];

                        for (var photo in newsDetails['media_attachments']) {
                          final imageWidget = Padding(
                            padding: const EdgeInsets.only(right: 8, left: 8),
                            child:
                                Stack(alignment: Alignment.topRight, children: [
                              Container(
                                width: 300,
                                height: 150,
                                color: Colors.black,
                                child: Image.network(
                                  photo,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  print("Delete this photo");
                                  await FirebaseFirestore.instance
                                      .collection('news')
                                      .doc(widget.news_id)
                                      .update({
                                    'media_attachments':
                                        FieldValue.arrayRemove([photo]),
                                  });
                                  
                                  setState(() {
                                  });
                                  print(media_photos);
                                },
                                child: Icon(
                                  Icons.delete,
                                  color: Color.fromARGB(255, 151, 10, 0),
                                  size: 36,
                                ),
                              ),
                            ]),
                          );
                          photos.add(imageWidget);
                        }

                        _headingController.text = newsDetails['heading'];
                        _bodyController.text = newsDetails['body'];

                        return Column(
                          children: [
                            InputField(
                              placeholder: "Heading",
                              inputType: "text",
                              controller: _headingController,
                              label: "Heading",
                              validator: InputValidator.requiredValidator,
                            ),
                            InputField(
                              placeholder: "Body",
                              inputType: "message",
                              controller: _bodyController,
                              label: "Body",
                              validator: InputValidator.requiredValidator,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SizedBox(
                                width: 200,
                                child: InputButton(
                                  function: () {
                                    _selectFile(true);
                                  },
                                  label: "Attach Photo",
                                  large: false,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: media_photos,
                              ),
                            ),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: photos,
                              ),
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: 250,
                                child: InputButton(
                                  label: "Update Post",
                                  function: () {
                                    updatePost();
                                  },
                                  large: true,
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
