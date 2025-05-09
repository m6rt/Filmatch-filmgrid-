import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:filmgrid/services/auth_service.dart';

class Forgotpassword extends StatefulWidget {
  const Forgotpassword({super.key});

  @override
  State<Forgotpassword> createState() => _ForgotpasswordState();
}

class _ForgotpasswordState extends State<Forgotpassword> {
  final _email = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0XFFFFB22C),
        title: Text("Reset Password"),
        toolbarHeight: 40,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(135, 60, 0, 0),
            child: Image.asset("assets/images/logo.png"),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(120, 260, 0, 0),
            child: const Text(
              "please enter your email adress",
              style: TextStyle(fontSize: 13, fontFamily: "PlayfairDisplay"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 300, 0, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(350),
                border: Border.all(
                  color: Theme.of(context).colorScheme.secondary,
                  width: 1,
                ),
              ),
              height: 50,
              width: 350,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  cursorColor: Colors.white,
                  controller: _email,
                  decoration: InputDecoration(
                    hintText: "Email Adress",
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(120, 390, 0, 0),
            child: Container(
              width: 200,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(500),
                border: Border.all(),
                color: Color(0XFFFFB22C),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                child: TextButton(
                  onPressed: () {
                    AuthService().resetPassword(email: _email.text);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "An email for password reset has been sent to your email.",
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    "SEND",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontFamily: "PlayfairDisplay",
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
