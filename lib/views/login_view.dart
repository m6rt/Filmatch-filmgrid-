import 'package:filmgrid/main.dart';
import 'package:filmgrid/services/auth_service.dart';
import 'package:filmgrid/views/forgot_password.dart';
import 'package:filmgrid/views/register_view.dart';
import 'package:filmgrid/theme/app_theme.dart';
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

  Future<void> _errorMessage(BuildContext context, String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor: AppTheme.darkGrey, // Koyu gri SnackBar
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

  void _closeLoadingScreen() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    print("[DEBUG] Dismissing loading indicator.");
  }

  Future<void> _handleError(String message) async {
    print(
      "[DEBUG] _handleLoginError START - message: $message, mounted: $mounted",
    );
    _closeLoadingScreen();

    if (!mounted) {
      print(
        "[DEBUG] _handleLoginError - mounted is true, calling _errorMessage",
      );
      return;
    }
    await _errorMessage(context, message);
  }

  Future<bool> _validateInputs(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      await _handleError("Lütfen tüm alanları doldurun.");
      return false;
    }
    if (!await _hasInternetConnection()) {
      await _handleError(
        "İnternet bağlantısı yok. Lütfen ağınızı kontrol edin.",
      );
      return false;
    }
    return true;
  }

  void _login(String email, String password) async {
    if (!await _validateInputs(email, password)) {
      return;
    }
    print("[DEBUG] Showing loading indicator.");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },
    );
    try {
      await AuthService().signin(email: email, password: password);
      print("[DEBUG] Signin successful.");
      _closeLoadingScreen();
    } on FirebaseAuthException catch (e) {
      print("[DEBUG] FirebaseAuthException caught: ${e.code}");
      if (e.code == 'invalid-email') {
        await _handleError("Invalid Email");
      } else if (e.code == 'user-not-found') {
        await _handleError("User Not Found");
      } else if (e.code == 'user-disabled') {
        await _handleError("User Disabled");
      } else if (e.code == 'too-many-requests') {
        await _handleError("Too Many Requests");
      } else if (e.code == 'wrong-password') {
        await _handleError("Wrong Password");
      } else if (e.code == 'network-request-failed') {
        await _handleError("Network Request Failed");
      } else if (e.code == 'operation-not-allowed') {
        await _handleError("Operation Not Allowed");
      } else if (e.code == "invalid-credential") {
        await _handleError("Invalid Credential");
        return;
      } else {
        await _handleError("An unknown error occurred");
        print("Unknown error: $e");
      }
    } catch (e) {
      await _handleError("An error occurred: $e");
      print("catch error $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.white, // Beyaz arka plan
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
                      color: Theme.of(context).colorScheme.secondary,
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
                  child: Text(
                    "Welcome,",
                    style: TextStyle(
                      fontFamily: 'Caveat Brush',
                      fontSize: 65,
                      color: AppTheme.black, // Siyah yazı
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.39,
                    horizontal: screenWidth * 0.09,
                  ),
                  child: Text(
                    "Please Login",
                    style: TextStyle(
                      fontFamily: 'Caveat Brush',
                      fontSize: 65,
                      color: AppTheme.black, // Siyah yazı
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.50,
                    horizontal: screenWidth * 0.07,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white, // Beyaz arka plan
                      borderRadius: BorderRadius.circular(350),
                      border: Border.all(
                        color: AppTheme.darkGrey, // Koyu gri kenarlık
                        width: 1,
                      ),
                    ),
                    height: screenHeight * 0.05,
                    width: screenWidth * 1,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: TextField(
                        style: TextStyle(
                          color: AppTheme.black, // Siyah yazı
                        ),
                        cursorColor: AppTheme.primaryRed, // Kırmızı cursor
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: "Email Adress",
                          hintStyle: TextStyle(
                            color: AppTheme.secondaryGrey, // Gri hint
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
                      color: AppTheme.white, // Beyaz arka plan
                      borderRadius: BorderRadius.circular(350),
                      border: Border.all(
                        color: AppTheme.darkGrey, // Koyu gri kenarlık
                        width: 1,
                      ),
                    ),
                    height: screenHeight * 0.05,
                    width: screenWidth * 1,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: TextField(
                        style: TextStyle(
                          color: AppTheme.black, // Siyah yazı
                        ),
                        cursorColor: AppTheme.primaryRed, // Kırmızı cursor
                        obscureText: true,
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: TextStyle(
                            color: AppTheme.secondaryGrey, // Gri hint
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
                      foregroundColor: AppTheme.black, // Siyah yazı
                      backgroundColor: AppTheme.white, // Beyaz arka plan
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
                      foregroundColor: AppTheme.black, // Siyah yazı
                      backgroundColor: AppTheme.white, // Beyaz arka plan
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
                        color: AppTheme.primaryRed, // Kırmızı kenarlık
                        width: 2,
                      ),
                      color: AppTheme.white, // Beyaz arka plan
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
                          _login(
                            _emailController.text,
                            _passwordController.text,
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.black, // Siyah yazı
                          backgroundColor: AppTheme.white, // Beyaz arka plan
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
                    color: AppTheme.darkGrey, // Koyu gri çizgi
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.4,
                    screenHeight * 0.81,
                    0,
                    0,
                  ), //0.4 0.83
                  child: Text(
                    "or Sign in With",
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 10,
                      color: AppTheme.black, // Siyah yazı
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
                    color: AppTheme.darkGrey, // Koyu gri çizgi
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
                        color: AppTheme.primaryRed, // Kırmızı kenarlık
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(350),
                      color: AppTheme.white, // Beyaz arka plan
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
