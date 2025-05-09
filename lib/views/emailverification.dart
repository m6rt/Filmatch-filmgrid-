import 'package:filmgrid/services/auth_service.dart';
import 'package:flutter/material.dart';

class EmailVerification extends StatefulWidget {
  const EmailVerification({super.key});

  @override
  State<EmailVerification> createState() => _EmailVerificationState();
}

class _EmailVerificationState extends State<EmailVerification> {
  @override
  Widget build(BuildContext context) {
    
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
            padding: const EdgeInsets.fromLTRB(130, 170, 0, 0),
            child: Image.asset("assets/images/logo.png"),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(60, 350, 0, 0),
            child: const Text(
              "Your email not verified yet.",
              style: TextStyle(fontFamily: 'Caveat Brush', fontSize: 32),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 420, 0, 0),
            child: const Text(
              "In order to use Filmatch you need verify your email\nPlease check spam!",
              style: TextStyle(fontSize: 11, fontFamily: "PlayfairDisplay"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(120, 500, 0, 0),
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
                  onPressed: AuthService().verifyEmail,
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
