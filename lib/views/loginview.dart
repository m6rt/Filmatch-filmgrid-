import 'package:filmgrid/main.dart';
import 'package:filmgrid/services/auth_service.dart';
import 'package:filmgrid/views/forgotpassword.dart';
import 'package:filmgrid/views/registerview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:filmgrid/services/auth_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Loginview extends StatefulWidget {
  const Loginview({super.key});
  @override
  State<Loginview> createState() => _LoginviewState();
}

class _LoginviewState extends State<Loginview> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void errorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Error",
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'PlayfairDisplay',
              fontSize: 16,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
              ),
              child: const Text(
                "OK",
                style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  void closeLoadingScreen() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void handleError(String message) {
    closeLoadingScreen();
    errorMessage(message);
  }

  void login(String email, String password) async {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
    try {
      await AuthService().signin(email: email, password: password);
      closeLoadingScreen();
    } on FirebaseAuthException catch (e) {
      closeLoadingScreen();
      if (e.code == 'invalid-email') {
        handleError("Invalid Email");
      } else if (e.code == 'user-disabled') {
        handleError("User Disabled");
      } else if (e.code == 'too-many-requests') {
        handleError("Too Many Requests");
      } else if (e.code == 'wrong-password') {
        handleError("Wrong Password");
      } else if (e.code == 'network-request-failed') {
        handleError("Network Request Failed");
      } else if (e.code == 'operation-not-allowed') {
        handleError("Operation Not Allowed");
      } else if (email.isEmpty || password.isEmpty) {
        handleError("Please fill in all fields");
        return;
      } else if (!await hasInternetConnection()) {
        handleError("No internet connection. Please check your network.");
        return;
      } else {
        handleError("An unknown error occurred");
      }
    } catch (e) {
      closeLoadingScreen();
      handleError("An error occurred: $e");
    } finally {
      closeLoadingScreen();
    }
  }

  Future<bool> hasInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: screenHeight),
            child: Stack(
              children: [
                if (screenWidth < 600)
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.20,
                    child: Image.asset(
                      "assets/images/topLogin.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.15,
                    horizontal: screenWidth * 0.3,
                  ),
                  child: Image.asset("assets/images/logo.png"),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.32,
                    horizontal: screenWidth * 0.09,
                  ),
                  child: const Text(
                    "Welcome,",
                    style: TextStyle(fontFamily: 'Caveat Brush', fontSize: 65),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.39,
                    horizontal: screenWidth * 0.09,
                  ),
                  child: const Text(
                    "Please Login",
                    style: TextStyle(fontFamily: 'Caveat Brush', fontSize: 65),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.50,
                    horizontal: screenWidth * 0.07,
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
                    height: screenHeight * 0.05,
                    width: screenWidth * 1,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: TextField(
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        cursorColor: Colors.white,
                        controller: _emailController,
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
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.57,
                    horizontal: screenWidth * 0.07,
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
                    height: screenHeight * 0.05,
                    width: screenWidth * 1,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: TextField(
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        cursorColor: Colors.white,
                        obscureText: true,
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                        ),
                        keyboardType: TextInputType.visiblePassword,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.07,
                    screenHeight * 0.63,
                    0,
                    0,
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Forgotpassword(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text(
                      "Forgot Password ",
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.57,
                    screenHeight * 0.63,
                    0,
                    0,
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterView(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text(
                      "Don't have an account ",
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.71,
                    horizontal: screenWidth * 0.3,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(350),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 1,
                      ),
                      color: Theme.of(context).primaryColor,
                    ),
                    width: 170,
                    height: 60,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ), // düzelt
                      child: TextButton(
                        onPressed: () async {
                          login(
                            _emailController.text,
                            _passwordController.text,
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.6,
                    screenHeight * 0.82,
                    0,
                    0,
                  ), //0.6 0.84
                  child: MySeparator(
                    height: 1,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.4,
                    screenHeight * 0.81,
                    0,
                    0,
                  ), //0.4 0.83
                  child: const Text(
                    "or Sign in With",
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 10,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0,
                    screenHeight * 0.82,
                    screenWidth * 0.6,
                    0,
                  ), // 0.84 0.6
                  child: MySeparator(
                    height: 1,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.42,
                    screenHeight * 0.87,
                    0,
                    0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.secondary,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(350),
                      color: Theme.of(context).primaryColor,
                    ),
                    height: 70,
                    width: 70,
                    child: TextButton(
                      onPressed: () {
                        AuthService().signInWithGoogle();
                      },
                      child: Image.asset('assets/images/googleIcon.png'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
