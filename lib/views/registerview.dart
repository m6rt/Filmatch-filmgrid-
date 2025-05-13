import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:filmgrid/main.dart';
import 'package:filmgrid/services/auth_page.dart';
import 'package:filmgrid/services/auth_service.dart';
import 'package:filmgrid/views/homeview.dart';
import 'package:filmgrid/views/loginview.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController _emailControllerr = TextEditingController();
  final TextEditingController _passwordControllerr = TextEditingController();
  final TextEditingController _confirmPasswordControllerr =
      TextEditingController();

  void closeLoadingDialog() {
    if (mounted) Navigator.pop(context);
  }

  Future<bool> hasInternetConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void errorMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.amber,
          title: Center(
            child: Text(message, style: TextStyle(color: Colors.black)),
          ),
        );
      },
    );
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void register(String email, String password, String confirmPassword) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
    if (!await hasInternetConnection()) {
      errorMessage("No internet connection");
      return;
    }
    if (password != confirmPassword) {
      errorMessage("Passwords do not match");
      closeLoadingDialog();
      return;
    } else if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      closeLoadingDialog();
      errorMessage("Please fill in all fields");
      return; // Fonksiyondan erken çık
    } else if (!isValidEmail(email)) {
      errorMessage("Invalid email format");
      closeLoadingDialog();
      return;
    }
    try {
      await AuthService().signup(email: email, password: password);
      closeLoadingDialog();
      Fluttertoast.showToast(
        msg: "Registration successful",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    } on FirebaseAuthException catch (e) {
      closeLoadingDialog();
      if (e.code == 'email-already-in-use') {
        errorMessage("Email already in use");
      } else if (e.code == 'weak-password') {
        errorMessage("Password is too weak");
      } else {
        errorMessage("An unexpected error occurred");
      }
    } catch (e) {
      closeLoadingDialog();
      errorMessage("An unexpected error occurred");
    }
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
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.2,
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
                    horizontal: screenWidth * 0.08,
                  ),
                  child: const Text(
                    "Welcome,",
                    style: TextStyle(fontFamily: 'Caveat Brush', fontSize: 60),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.39,
                    horizontal: screenWidth * 0.08,
                  ),
                  child: const Text(
                    "Please Register",
                    style: TextStyle(fontFamily: 'Caveat Brush', fontSize: 55),
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
                        cursorColor: Colors.black,
                        controller: _emailControllerr,
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
                        cursorColor: Colors.black,
                        obscureText: true,
                        controller: _passwordControllerr,
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.64,
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
                        cursorColor: Colors.black,
                        obscureText: true,
                        controller: _confirmPasswordControllerr,
                        decoration: InputDecoration(
                          hintText: "Confirm Password",
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
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.69,
                    horizontal: screenWidth * 0.29,
                  ),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Loginview(),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.secondary,
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text(
                      "Already have account ? Login here",
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.74,
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
                          register(
                            _emailControllerr.text,
                            _passwordControllerr.text,
                            _confirmPasswordControllerr.text,
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.secondary,
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text(
                          "Register",
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
                    screenHeight * 0.84,
                    0,
                    0,
                  ),
                  child: MySeparator(
                    height: 1,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.41,
                    screenHeight * 0.83,
                    0,
                    0,
                  ),
                  child: const Text(
                    "or Register with",
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 10,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0,
                    screenHeight * 0.84,
                    screenWidth * 0.6,
                    0,
                  ),
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
                      onPressed: () {},
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
