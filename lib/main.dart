import 'dart:ui';

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
      options: DefaultFirebaseOptions.currentPlatform
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
      scrollBehavior: MyCustomScrollBehavior(),
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
class MyCustomScrollBehavior extends MaterialScrollBehavior {
 // Override behavior methods and getters like dragDevices
 @override
 Set<PointerDeviceKind> get dragDevices => {
   PointerDeviceKind.touch,
   PointerDeviceKind.mouse,
   // etc.
 };
}
