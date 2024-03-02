import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_admin/core/constants.dart';
import 'package:irs_admin/core/input_validator.dart';
import 'package:irs_admin/core/utilities.dart';
import 'package:irs_admin/widgets/input_button.dart';
import 'package:irs_admin/widgets/input_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  void signIn() async {
    print("working?");
    try {
      Utilities.showLoadingIndicator(context);
      InputValidator.checkFormValidity(formKey, context);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      FirebaseAuth.instance.userChanges().listen((User? user) async {
        if (user == null) {
          print("User is currently signed out");
        } else {
          print("User is signed in");
          DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get();

          if (documentSnapshot.exists) {
            Map<String, dynamic> userDetails =
                documentSnapshot.data() as Map<String, dynamic>;

            if (userDetails['user_type'] == "admin") {
              context.go("/dashboard");
            } else {
              Utilities.showSnackBar(
                  "You are not allowed to use this system", Colors.red);
              FirebaseAuth.instance.signOut();
            }
          } else {
            Utilities.showSnackBar(
                "User does not have details attached to it", Colors.red);
          }
        }
      });
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (ex) {
      Navigator.of(context).pop();
      Utilities.showSnackBar("${ex.message}", Colors.red);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: formKey,
        child: Center(
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(150),
                    child: Image.network(
                      "https://scontent.fmnl8-1.fna.fbcdn.net/v/t1.6435-9/36347143_115056176069864_1083116285908221952_n.jpg?_nc_cat=107&ccb=1-7&_nc_sid=be3454&_nc_eui2=AeHrCWnJOJQez0Io7WSUv8qolKwTUflGxR-UrBNR-UbFH_P7hdCfbZevBSBsCLOco4Y8DGT3ESTcPEAJt6tDlpu_&_nc_ohc=aFSsZiv8LmYAX8QVhW7&_nc_ht=scontent.fmnl8-1.fna&oh=00_AfDCR9nPeTNUMW1tVTIuollmxIMny96KWplKoMRYPVMiiA&oe=66083300",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Text(
                  "IRS Admin Login",
                  style: heading,
                ),
                InputField(
                  placeholder: "Email Address",
                  inputType: "email",
                  controller: _emailController,
                  validator: InputValidator.emailValidator,
                ),
                InputField(
                  placeholder: "Password",
                  inputType: "password",
                  controller: _passwordController,
                  validator: InputValidator.requiredValidator,
                ),
                InputButton(
                  label: "Login",
                  function: () {
                    signIn();
                  },
                  large: true,
                ),
                TextButton(
                    onPressed: () {
                      print("working");
                      context.go('/forgot-password');
                    },
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
