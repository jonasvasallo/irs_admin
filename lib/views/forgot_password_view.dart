import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:irs_admin/core/constants.dart';
import 'package:irs_admin/core/input_validator.dart';
import 'package:irs_admin/core/utilities.dart';
import 'package:irs_admin/widgets/input_button.dart';
import 'package:irs_admin/widgets/input_field.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({Key? key}) : super(key: key);

  @override
  _ForgotPasswordViewState createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _emailController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  void sendResetLink() async {
    Utilities.showLoadingIndicator(context);
    InputValidator.checkFormValidity(formKey, context);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      Navigator.of(context).pop();
      Utilities.showSnackBar(
          "Password Reset Link was successfully sent", Colors.green);
    } on FirebaseAuthException catch (ex) {
      Navigator.of(context).pop();
      Utilities.showSnackBar("${ex.message}", Colors.red);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 500,
          child: Form(
            key: formKey,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextButton(
                onPressed: () {
                  context.go('/login');
                },
                child: Text(
                  "Go back to login",
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                "Enter your email address and we will send you a password reset link. If you are registered in the system, you will receive the reset link.",
                style: regular_minor,
              ),
              InputField(
                placeholder: "Email Address",
                inputType: "email",
                controller: _emailController,
                label: "Email Address",
                validator: InputValidator.emailValidator,
              ),
              InputButton(
                  label: "Send Link",
                  function: () {
                    sendResetLink();
                  },
                  large: true),
            ]),
          ),
        ),
      ),
    );
  }
}
