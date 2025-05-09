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

  void register() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(child: CircularProgressIndicator());
      },  
    );
    if (_passwordControllerr.text == _confirmPasswordControllerr.text) {
      try {
        bool gecerliEmail = RegExp(
          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
        ).hasMatch(_emailControllerr.text);

        if (!gecerliEmail) {
          // Yükleniyor dialogunu kapat
          if (mounted) Navigator.pop(context);

          // E-posta doğrulama hatası göster
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Geçersiz email formatı')));
          return; // Fonksiyondan erken çık
        }
        await AuthService().signup(
          email: _emailControllerr.text,
          password: _passwordControllerr.text,
        );
      } catch (e) {
        if (mounted) Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kayıt başarısız: $e')));
      }
    } else {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Passwords should different.")));
    }
    if (mounted) Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Image.asset(
                "assets/images/topLogin.png",
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(135, 170, 0, 0),
            child: Image.asset("assets/images/logo.png"),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(35, 320, 0, 0),
            child: const Text(
              "Welcome,",
              style: TextStyle(fontFamily: 'Caveat Brush', fontSize: 70),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(35, 390, 0, 0),
            child: const Text(
              "Please Register",
              style: TextStyle(fontFamily: 'Caveat Brush', fontSize: 60),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(35, 500, 0, 0),
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
            padding: const EdgeInsets.fromLTRB(35, 560, 0, 0),
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
            padding: const EdgeInsets.fromLTRB(35, 620, 0, 0),
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
            padding: const EdgeInsets.fromLTRB(100, 670, 0, 0),
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Loginview()),
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text(
                "Already have account ? Login here",
                style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(125, 715, 0, 0),
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
                    register();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
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
            padding: const EdgeInsets.fromLTRB(0, 800, 240, 0),
            child: MySeparator(
              height: 1,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(170, 790, 100, 0),
            child: const Text(
              "or Register with",
              style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(250, 798, 0, 0),
            child: MySeparator(
              height: 1,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(177, 815, 0, 0),
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
    );
  }
}
