import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_admin/core/constants.dart';
import 'package:irs_admin/core/input_validator.dart';
import 'package:irs_admin/core/utilities.dart';
import 'package:irs_admin/widgets/input_field.dart';
import 'package:irs_admin/models/DatabaseModel.dart';

class UsersView extends StatefulWidget {
  const UsersView({Key? key}) : super(key: key);

  @override
  _UsersViewState createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Users"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: false,
                    indicatorColor: Colors.blue,
                    unselectedLabelColor: minorText,
                    labelColor: Colors.blue,
                    tabs: [
                      Tab(
                        text: "User",
                      ),
                      Tab(
                        text: "Resident",
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .snapshots(),
                            builder: (context, snapshot) {
                              List<DataRow> userList = [];
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
                              final users = snapshot.data?.docs.toList();

                              for (var user in users!) {
                                final userRow = DataRow(
                                  cells: [
                                    DataCell(Text(user.id)),
                                    DataCell(Text(user['user_type']
                                        .toString()
                                        .toUpperCase())),
                                    DataCell(SizedBox(width: 24, height: 24, child: Image.network(user['profile_path'], fit: BoxFit.cover,),),),
                                    DataCell(Text(
                                        "${user['first_name']} ${user['middle_name']} ${user['last_name']}")),
                                    DataCell(Text(user['gender'])),
                                    DataCell(Text(user['birthday'])),
                                    DataCell(Text(user['verified'].toString())),
                                    DataCell(
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              context.go(
                                                  '/users/update/${user.id}');
                                            },
                                            child: Icon(
                                              Icons.edit,
                                              color: Colors.green,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text("Delete User"),
                                                    content: Text(
                                                        "Are you sure you want to delete this user? This action cannot be reverted."),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: Text("Cancel"),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {},
                                                        child: Text("Yes"),
                                                      ),
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
                                      ),
                                    ),
                                  ],
                                );

                                userList.add(userRow);
                              }

                              return SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          FilledButton.icon(
                                            onPressed: () {},
                                            icon: Icon(Icons.search),
                                            label: Text("Search"),
                                          ),
                                          OutlinedButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AddUserAlert();
                                                },
                                              );
                                            },
                                            child: Text("Add User"),
                                          ),
                                        ],
                                      ),
                                      DataTable(
                                        sortColumnIndex: 4,
                                        sortAscending: true,
                                        columns: [
                                          DataColumn(
                                            label: Text("UID"),
                                          ),
                                          DataColumn(
                                            label: Text("User Type"),
                                          ),
                                          DataColumn(label: Text("Profile"),),
                                          DataColumn(
                                            label: Text("Full Name"),
                                          ),
                                          DataColumn(
                                            label: Text("Sex"),
                                          ),
                                          DataColumn(
                                            label: Text("Birth Date"),
                                          ),
                                          DataColumn(
                                            label: Text("Verified"),
                                          ),
                                          DataColumn(
                                            label: Text("Action"),
                                          ),
                                        ],
                                        rows: userList,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        StreamBuilder(
                          stream: FirebaseFirestore.instance
                              .collection('residents')
                              .snapshots(),
                          builder: (context, snapshot) {
                            List<DataRow> residentList = [];
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
                            final users = snapshot.data?.docs.toList();

                            for (var user in users!) {
                              final userRow = DataRow(
                                cells: [
                                  DataCell(Text(user.id)),
                                  DataCell(Text(
                                      "${user['first_name']} ${user['middle_name']} ${user['last_name']}")),
                                  DataCell(Text(user['gender'])),
                                  DataCell(Text(user['birthday'])),
                                  DataCell(Text(user['contact_no'])),
                                  DataCell(Text(
                                      "${user['address_house']} ${user['address_street']}, Tambubong, San Rafael, Bulacan")),
                                  DataCell(
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return UpdateResidentAlert(
                                                    resident_id: user.id);
                                              },
                                            );
                                          },
                                          child: Icon(
                                            Icons.edit,
                                            color: Colors.green,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AlertDialog(
                                                  title: Text("Delete User"),
                                                  content: Text(
                                                      "Are you sure you want to delete this resident? This action cannot be reverted."),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text("Cancel"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        DatabaseModel
                                                            .deleteDocumentFromCollection(
                                                          user.id,
                                                          "residents",
                                                        );
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text("Yes"),
                                                    ),
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
                                    ),
                                  ),
                                ],
                              );

                              residentList.add(userRow);
                            }
                            return SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: () {},
                                          icon: Icon(Icons.search),
                                          label: Text("Search"),
                                        ),
                                        OutlinedButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) {
                                                return AddResidentAlert();
                                              },
                                            );
                                          },
                                          child: Text("Add User"),
                                        ),
                                      ],
                                    ),
                                    DataTable(
                                      sortColumnIndex: 4,
                                      sortAscending: true,
                                      columns: [
                                        DataColumn(
                                          label: Text("Resident ID"),
                                        ),
                                        DataColumn(
                                          label: Text("Full Name"),
                                        ),
                                        DataColumn(
                                          label: Text("Sex"),
                                        ),
                                        DataColumn(
                                          label: Text("Birth Date"),
                                        ),
                                        DataColumn(
                                          label: Text("Phone Number"),
                                        ),
                                        DataColumn(
                                          label: Text("Address"),
                                        ),
                                        DataColumn(
                                          label: Text("Action"),
                                        ),
                                      ],
                                      rows: residentList,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Center(
                        //   child: OutlinedButton(
                        //     onPressed: () {
                        //       showDialog(
                        //         context: context,
                        //         builder: (context) {
                        //           return AddResidentAlert();
                        //         },
                        //       );
                        //     },
                        //     child: Text("Add User"),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AddResidentAlert extends StatefulWidget {
  const AddResidentAlert({Key? key}) : super(key: key);

  @override
  _AddResidentAlert createState() => _AddResidentAlert();
}

List<String> sex_options = ["Male", "Female"];

class _AddResidentAlert extends State<AddResidentAlert> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _genderController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _addressHouseController = TextEditingController();
  final _addressStreetController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _emailAddressController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  String currentOption = sex_options[0];

  bool verified = false;

  Future<void> addResident() async {
    final isValid = formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    try {
      // Get a reference to the Firestore collection
      CollectionReference collectionReference =
          FirebaseFirestore.instance.collection("residents");

      // Add the document to the collection
      await collectionReference.add({
        'first_name': _firstNameController.text.trim(),
        'middle_name': _middleNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'gender': currentOption,
        'birthday': _birthdayController.text.trim(),
        'address_house': _addressHouseController.text.trim(),
        'address_street': _addressStreetController.text.trim(),
        'contact_no': _contactNoController.text.trim(),
      });

      print('Document added successfully');
      // Utilities.showSnackBar("Document added successfully", Colors.green);
    } catch (e) {
      print('Error adding document: $e');
      // Utilities.showSnackBar("Error adding document: $e", Colors.red);
    }

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _genderController.dispose();
    _birthdayController.dispose();
    _addressHouseController.dispose();
    _addressStreetController.dispose();
    _contactNoController.dispose();
    _emailAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 800,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InputField(
                        placeholder: "First Name",
                        inputType: "text",
                        controller: _firstNameController,
                        label: "First Name",
                        validator: InputValidator.requiredValidator,
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: InputField(
                        placeholder: "Middle Name",
                        inputType: "text",
                        controller: _middleNameController,
                        label: "Middle Name",
                      ),
                    ),
                  ],
                ),
                InputField(
                  placeholder: "Last Name",
                  inputType: "text",
                  controller: _lastNameController,
                  label: "Last Name",
                  validator: InputValidator.requiredValidator,
                ),
                Row(
                  children: [
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sex",
                          style: regular,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.all(4),
                          title: const Text("Male"),
                          leading: Radio(
                            value: sex_options[0],
                            groupValue: currentOption,
                            onChanged: (value) {
                              setState(() {
                                currentOption = value.toString();
                              });
                            },
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.all(4),
                          title: const Text("Female"),
                          leading: Radio(
                            value: sex_options[1],
                            groupValue: currentOption,
                            onChanged: (value) {
                              setState(() {
                                currentOption = value.toString();
                              });
                            },
                          ),
                        )
                      ],
                    )),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: InputField(
                        placeholder: "Birthday",
                        inputType: "date",
                        controller: _birthdayController,
                        label: "Birthday",
                        validator: InputValidator.dateValidator,
                      ),
                    ),
                  ],
                ),
                InputField(
                  placeholder: "+63 9XX-XXX-XXXX",
                  inputType: "text",
                  controller: _contactNoController,
                  label: "Phone Number",
                  validator: InputValidator.phoneValidator,
                ),
                Row(
                  children: [
                    Expanded(
                      child: InputField(
                        placeholder: "House No.",
                        inputType: "text",
                        controller: _addressHouseController,
                        label: "House No.",
                        validator: InputValidator.requiredValidator,
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: InputField(
                        placeholder: "Street",
                        inputType: "text",
                        controller: _addressStreetController,
                        label: "Street",
                        validator: InputValidator.requiredValidator,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            addResident();
          },
          child: Text("Add Resident"),
        ),
      ],
    );
  }
}

class UpdateResidentAlert extends StatefulWidget {
  final String resident_id;
  const UpdateResidentAlert({Key? key, required this.resident_id})
      : super(key: key);

  @override
  _UpdateResidentAlert createState() => _UpdateResidentAlert();
}

class _UpdateResidentAlert extends State<UpdateResidentAlert> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _genderController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _addressHouseController = TextEditingController();
  final _addressStreetController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _emailAddressController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  String currentOption = sex_options[0];

  bool verified = false;

  Map<String, dynamic> residentDetails = {};

  Future<void> addResident() async {
    final isValid = formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    try {
      // Get a reference to the Firestore collection
      DocumentReference documentReference = FirebaseFirestore.instance
          .collection("residents")
          .doc(widget.resident_id);

      // Add the document to the collection
      await documentReference.update({
        'first_name': _firstNameController.text.trim(),
        'middle_name': _middleNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'gender': currentOption,
        'birthday': _birthdayController.text.trim(),
        'address_house': _addressHouseController.text.trim(),
        'address_street': _addressStreetController.text.trim(),
        'contact_no': _contactNoController.text.trim(),
      });

      print('Document updated successfully');
      // Utilities.showSnackBar("Document added successfully", Colors.green);
    } catch (e) {
      print('Error updating document: $e');
      // Utilities.showSnackBar("Error adding document: $e", Colors.red);
    }

    Navigator.of(context).pop();
  }

  void fetchDetails() async {
    residentDetails =
        await DatabaseModel.getDetails(widget.resident_id, "residents");

    setState(() {
      _firstNameController.text = residentDetails['first_name'];
      _middleNameController.text = residentDetails['middle_name'];
      _lastNameController.text = residentDetails['last_name'];
      currentOption = residentDetails['gender'];
      _birthdayController.text = residentDetails['birthday'];
      _addressHouseController.text = residentDetails['address_house'];
      _addressStreetController.text = residentDetails['address_street'];
      _contactNoController.text = residentDetails['contact_no'];
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchDetails();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _genderController.dispose();
    _birthdayController.dispose();
    _addressHouseController.dispose();
    _addressStreetController.dispose();
    _contactNoController.dispose();
    _emailAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 800,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InputField(
                        placeholder: "First Name",
                        inputType: "text",
                        controller: _firstNameController,
                        label: "First Name",
                        validator: InputValidator.requiredValidator,
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: InputField(
                        placeholder: "Middle Name",
                        inputType: "text",
                        controller: _middleNameController,
                        label: "Middle Name",
                      ),
                    ),
                  ],
                ),
                InputField(
                  placeholder: "Last Name",
                  inputType: "text",
                  controller: _lastNameController,
                  label: "Last Name",
                  validator: InputValidator.requiredValidator,
                ),
                Row(
                  children: [
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sex",
                          style: regular,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.all(4),
                          title: const Text("Male"),
                          leading: Radio(
                            value: sex_options[0],
                            groupValue: currentOption,
                            onChanged: (value) {
                              setState(() {
                                currentOption = value.toString();
                              });
                            },
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.all(4),
                          title: const Text("Female"),
                          leading: Radio(
                            value: sex_options[1],
                            groupValue: currentOption,
                            onChanged: (value) {
                              setState(() {
                                currentOption = value.toString();
                              });
                            },
                          ),
                        )
                      ],
                    )),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: InputField(
                        placeholder: "Birthday",
                        inputType: "date",
                        controller: _birthdayController,
                        label: "Birthday",
                        validator: InputValidator.dateValidator,
                      ),
                    ),
                  ],
                ),
                InputField(
                  placeholder: "+63 9XX-XXX-XXXX",
                  inputType: "text",
                  controller: _contactNoController,
                  label: "Phone Number",
                  validator: InputValidator.phoneValidator,
                ),
                Row(
                  children: [
                    Expanded(
                      child: InputField(
                        placeholder: "House No.",
                        inputType: "text",
                        controller: _addressHouseController,
                        label: "House No.",
                        validator: InputValidator.requiredValidator,
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: InputField(
                        placeholder: "Street",
                        inputType: "text",
                        controller: _addressStreetController,
                        label: "Street",
                        validator: InputValidator.requiredValidator,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            addResident();
          },
          child: Text("Add Resident"),
        ),
      ],
    );
  }
}

class AddUserAlert extends StatefulWidget {
  const AddUserAlert({Key? key}) : super(key: key);

  @override
  _AddUserAlertState createState() => _AddUserAlertState();
}

class _AddUserAlertState extends State<AddUserAlert> {
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _genderController = TextEditingController();
  final _birthdayController = TextEditingController();
  final _addressHouseController = TextEditingController();
  final _addressStreetController = TextEditingController();
  final _contactNoController = TextEditingController();
  final _emailAddressController = TextEditingController();
  final _passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  String currentOption = sex_options[0];

  bool verified = false;

  String _dropdownValue = "resident";

  Future<void> addUser() async {
    final isValid = formKey.currentState!.validate();
    if (!isValid) {
      return;
    }

    try {
      // Get a reference to the Firestore collection
      CollectionReference collectionReference =
          FirebaseFirestore.instance.collection("users");

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailAddressController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String userId = userCredential.user?.uid ?? '';

      // Add the document to the collection
      await collectionReference.doc(userId).set({
        'first_name': _firstNameController.text.trim(),
        'middle_name': _middleNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'gender': currentOption,
        'birthday': _birthdayController.text.trim(),
        'address_house': _addressHouseController.text.trim(),
        'address_street': _addressStreetController.text.trim(),
        'contact_no': _contactNoController.text.trim(),
        'email': _emailAddressController.text.trim(),
        'lastLogin': FieldValue.serverTimestamp(),
        'deactivation': false,
        'profile_path': "https://i.stack.imgur.com/l60Hf.png",
        'sms_verified': false,
        'verified': true,
        'user_type': _dropdownValue,
      });

      print('Document added successfully');
      Utilities.showSnackBar("User added successfully.", Colors.green);
    } catch (e) {
      print('Error adding document: $e');
      Utilities.showSnackBar("Error adding document: $e", Colors.red);
    }

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _genderController.dispose();
    _birthdayController.dispose();
    _addressHouseController.dispose();
    _addressStreetController.dispose();
    _contactNoController.dispose();
    _emailAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: SizedBox(
            width: 800,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InputField(
                        placeholder: "First Name",
                        inputType: "text",
                        controller: _firstNameController,
                        label: "First Name",
                        validator: InputValidator.requiredValidator,
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: InputField(
                        placeholder: "Middle Name",
                        inputType: "text",
                        controller: _middleNameController,
                        label: "Middle Name",
                      ),
                    ),
                  ],
                ),
                InputField(
                  placeholder: "Last Name",
                  inputType: "text",
                  controller: _lastNameController,
                  label: "Last Name",
                  validator: InputValidator.requiredValidator,
                ),
                Row(
                  children: [
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sex",
                          style: regular,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.all(4),
                          title: const Text("Male"),
                          leading: Radio(
                            value: sex_options[0],
                            groupValue: currentOption,
                            onChanged: (value) {
                              setState(() {
                                currentOption = value.toString();
                              });
                            },
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.all(4),
                          title: const Text("Female"),
                          leading: Radio(
                            value: sex_options[1],
                            groupValue: currentOption,
                            onChanged: (value) {
                              setState(() {
                                currentOption = value.toString();
                              });
                            },
                          ),
                        )
                      ],
                    )),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: InputField(
                        placeholder: "Birthday",
                        inputType: "date",
                        controller: _birthdayController,
                        label: "Birthday",
                        validator: InputValidator.dateValidator,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: InputField(
                        placeholder: "House No.",
                        inputType: "text",
                        controller: _addressHouseController,
                        label: "House No.",
                        validator: InputValidator.requiredValidator,
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Expanded(
                      child: InputField(
                        placeholder: "Street",
                        inputType: "text",
                        controller: _addressStreetController,
                        label: "Street",
                        validator: InputValidator.requiredValidator,
                      ),
                    ),
                  ],
                ),
                InputField(
                  placeholder: "+63 9XX-XXX-XXXX",
                  inputType: "phone",
                  controller: _contactNoController,
                  label: "Phone Number",
                  validator: InputValidator.phoneValidator,
                ),
                InputField(
                  placeholder: "Email Address",
                  inputType: "email",
                  controller: _emailAddressController,
                  label: "Email Address",
                  validator: InputValidator.emailValidator,
                ),
                InputField(
                  placeholder: "Password",
                  inputType: "password",
                  controller: _passwordController,
                  label: "Password",
                  validator: InputValidator.passwordValidator,
                ),
                DropdownMenu(
                  width: 500,
                  onSelected: (value) {
                    setState(() {
                      if (value is String) {
                        _dropdownValue = value;
                      }
                    });
                  },
                  dropdownMenuEntries: <DropdownMenuEntry<String>>[
                    DropdownMenuEntry(
                      value: "resident",
                      label: "Resident",
                    ),
                    DropdownMenuEntry(
                      value: "tanod",
                      label: "Tanod",
                    ),
                  ],
                  initialSelection: _dropdownValue,
                  menuStyle: MenuStyle(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            addUser();
          },
          child: Text("Add User"),
        ),
      ],
    );
  }
}
