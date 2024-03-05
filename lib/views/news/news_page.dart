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

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  final _headingController = TextEditingController();
  final _bodyController = TextEditingController();

  List<Widget> media_photos = [];

  final formKey = GlobalKey<FormState>();

  int imageCounts = 0;

  String selectFile = "";
  // XFile file;
  List<Uint8List> pickedImagesInBytes = [];

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
        UploadTask uploadTask;

        Reference ref = FirebaseStorage.instance
            .ref()
            .child('news_attachments/${itemName}_$i');

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

  void postNews() async {
    InputValidator.checkFormValidity(formKey, context);

    try {
      List<String> imageUrls = [];
      if (pickedImagesInBytes.length > 0) {
        imageUrls = await _uploadMultipleFiles("${FirebaseAuth.instance.currentUser?.uid}${_headingController.text}_news_media");
      }
      CollectionReference newsCollection =
          FirebaseFirestore.instance.collection('news');

      await newsCollection.add({
        'heading': _headingController.text.trim(),
        'body': _bodyController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'media_attachments': imageUrls,
        'posted_by': FirebaseAuth.instance.currentUser?.uid,
      });
      Utilities.showSnackBar("Successfully posted", Colors.green);
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

  void deleteNews(String news_id) async{
    try {
    await FirebaseFirestore.instance
        .collection("news")
        .doc(news_id)
        .delete();
    print('Document successfully deleted');
    Utilities.showSnackBar("Post successfully deleted", Colors.green);
  } catch (e) {
    Utilities.showSnackBar("$e", Colors.red);
  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Local News and Announcements"),
      ),
      body: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Form(
                  key: formKey,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    width: MediaQuery.of(context).size.width * 0.50,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Add New Post",
                            style: heading,
                          ),
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
                                  large: false,),
                            ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: media_photos,
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
                                label: "Post",
                                function: () {
                                  postNews();
                                },
                                large: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  width: MediaQuery.of(context).size.width * 0.50,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('news')
                            .snapshots(),
                        builder: (context, snapshot) {
                          List<Widget> newsList = [];
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
            
                          final news = snapshot.data?.docs.toList();
            
                          if (news != null) {
                            for (var post in news) {
                              String myDate = "test";
            
                              if (post['timestamp'] != null) {
                                Timestamp t = post['timestamp'] as Timestamp;
                                DateTime date = t.toDate();
                                myDate =
                                    DateFormat('dd/MM/yyyy hh:mm').format(date);
                              }
                              final newsWidget = Container(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 8, bottom: 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              height: 48,
                                              width: 48,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  (post['media_attachments']
                                                              .length <
                                                          1)
                                                      ? "https://t4.ftcdn.net/jpg/04/73/25/49/360_F_473254957_bxG9yf4ly7OBO5I0O5KABlN930GwaMQz.jpg"
                                                      : post['media_attachments']
                                                          [0],
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 8,
                                            ),
                                            Flexible(
                                              flex: 2,
                                              child: SizedBox(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      post['heading'],
                                                      style: subheading,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      post['body'],
                                                      style: regular_minor,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        flex: 1,
                                        child: Text(
                                          myDate,
                                          style: regular_minor,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              context
                                                  .go('/news/update/${post.id}');
                                            },
                                            child: Icon(
                                              Icons.edit,
                                              color: Colors.amber,
                                            ),
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
                                                      TextButton(onPressed: () async{
                                                        deleteNews(post.id);
                                                        Navigator.of(context).pop();
                                                      }, child: Text("Delete"),),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            child: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              );
                              newsList.add(newsWidget);
                            }
                          }
            
                          return Column(
                            children: newsList,
                          );
                        }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
