import 'package:connectivity_plus/connectivity_plus.dart';
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

  Future<void> _errorMessage(BuildContext context, String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.black,
      ),
    );
  }

  Future<bool> _hasInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none) &&
        connectivityResult.length == 1) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.05,
              horizontal: screenWidth * 0.32,
            ),
            child: Image.asset("assets/images/logo.png"),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.24,
              horizontal: screenWidth * 0.26,
            ),
            child:  Text(
              "please enter your email adress",
              style: TextStyle(fontSize: screenWidth*0.03, fontFamily: "PlayfairDisplay"),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.3,
              horizontal: screenWidth * 0.1,
            ),
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
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.28,
              screenHeight * 0.38,
              0,
              0,
            ),
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
                  onPressed: () async {
                    if (!await _hasInternetConnection()) {
                      _errorMessage(
                        context,
                        "No internet connection. Please check your connection.",
                      );
                      return;
                    }
                    if (_email.text.isEmpty) {
                      _errorMessage(
                        context,
                        "Please enter your email address.",
                      );
                      return;
                    }
                    if (!RegExp(
                      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
                    ).hasMatch(_email.text)) {
                      _errorMessage(
                        context,
                        "Please enter a valid email address.",
                      );
                      return;
                    }
                    try {
                      await AuthService().resetPassword(email: _email.text);
                      Navigator.pop(context);
                      _errorMessage(
                        context,
                        "Password reset email sent. Please check your inbox.",
                      );
                    } on FirebaseAuthException catch (e) {
                      if (e.code == 'user-not-found') {
                        _errorMessage(
                          context,
                          "No user found with this email.",
                        );
                      } else if (e.code == 'invalid-email') {
                        _errorMessage(context, "Invalid email address.");
                      } else if (e.code == 'too-many-requests') {
                        _errorMessage(
                          context,
                          "Too many requests. Please try again later.",
                        );
                      }
                    } catch (e) {
                      _errorMessage(
                        context,
                        "An error occurred. Please try again.",
                      );
                      print(e);
                    }
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
