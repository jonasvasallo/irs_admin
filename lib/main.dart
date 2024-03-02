import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:irs_admin/core/app_router.dart';
import 'package:irs_admin/core/constants.dart';
import 'package:irs_admin/core/utilities.dart';
import 'package:irs_admin/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
          apiKey: "AIzaSyCU7lz9ijnL5SAak3_AUNW_WrytTq50LNE",
          projectId: "irs-capstone",
          messagingSenderId: "718420727642",
          appId: "1:718420727642:web:de65ae805b76a207b24563"),
    );
  }

  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: AppRouter.router,
      scaffoldMessengerKey: Utilities.messengerKey,
      debugShowCheckedModeBanner: false,
      title: "IRS Admin",
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: false,
          titleTextStyle: heading,
        ),
      ),
    );
  }
}
