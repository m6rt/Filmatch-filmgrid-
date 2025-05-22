import 'package:filmgrid/firebase_options.dart';
import 'package:filmgrid/services/auth_page.dart';
import 'package:filmgrid/views/email_verification.dart';
import 'package:filmgrid/views/forgot_password.dart';
import 'package:filmgrid/views/home_view.dart';
import 'package:filmgrid/views/login_view.dart';
import 'package:filmgrid/views/logout.dart';
import 'package:filmgrid/views/register_view.dart';
import 'package:filmgrid/views/swipe_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';

class MySeparator extends StatelessWidget {
  const MySeparator({Key? key, this.height = 1, this.color = Colors.black})
    : super(key: key);
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 10.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  //runApp(DevicePreview(enabled: !kReleaseMode, builder: (context) => MyApp()));
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        fontFamily: "Caveat Brush",
        primaryColor: Color(0XFFF7F7F7),
        colorScheme: ColorScheme.light(
          primary: Color(0xFFF7F7F7),
          secondary: Colors.black,
        ),
      ),
      home: const SwipeView(),
    );
  }
}
