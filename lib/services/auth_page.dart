import 'package:filmgrid/views/email_verification.dart';
import 'package:filmgrid/views/home_view.dart';
import 'package:filmgrid/views/login_view.dart';
import 'package:filmgrid/views/logout.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: 
      StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if(snapshot.hasError) {
            return const Center(child: Text("hata olustu 313131"),);
          }
          if (snapshot.hasData) {
            final user = snapshot.data;
            if (user == null) {
              return Loginview();
            } 
            //else if (!user.emailVerified) {
             // return EmailVerification();
            //} 
            else {
              return Homeview();
            }
          }else{return Loginview();}
        },
      ),
    );
  }
}
