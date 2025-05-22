import 'package:filmgrid/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailVerification extends StatefulWidget {
  const EmailVerification({super.key});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
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

  Future<void> _sendEmailVerification() async {
    try {
      await AuthService().verifyEmail;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'to-many-request') {
        _errorMessage(context, 'Please wait to try again');
      }
      _errorMessage(context, 'Error sending verification email');
    } catch (e) {
      _errorMessage(context, 'Error sending verification email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0XFFFFB22C),
        title: Text("Email Verification"),
        toolbarHeight: 40,
        leading: IconButton(
          onPressed: () {
            AuthService().logout();
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
              horizontal: screenWidth * 0.2,
            ),
            child: Text(
              "Your email not verified yet.",
              style: TextStyle(fontFamily: 'Caveat Brush', fontSize: screenWidth*0.06),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.30,
              horizontal: screenWidth * 0.19,
            ),
            child: const Text(
              "In order to use Filmatch you need verify your email\nPlease check spam!",
              style: TextStyle(fontSize: 11, fontFamily: "PlayfairDisplay"),
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
                    await _sendEmailVerification();
                  },
                  child: const Text(
                    "VERIFY",
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
