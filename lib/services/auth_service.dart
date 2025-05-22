import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  User? get currentUser => FirebaseAuth.instance.currentUser;
  Future<void> signup({required String email, required String password}) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      print('AuthService signup error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('AuthService signup generic error: $e');
      rethrow;
    }
  }

  Future<void> signin({required String email, required String password}) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print('AuthService signin error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('AuthService signin generic error: $e');
      rethrow; // İstisnayı yeniden fırlat}
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
      if (gUser == null) {
        return null;
      }
      final GoogleSignInAuthentication gAuth = await gUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      print(
        'AuthService signInWithGoogle (FirebaseAuth) error: ${e.code} - ${e.message}',
      );
      rethrow;
    } on Exception catch (e) {
      // GoogleSignIn().signIn() PlatformException gibi hatalar fırlatabilir
      print('AuthService signInWithGoogle (GoogleSignIn or other) error: $e');
      rethrow;
    }
  }

  Future<void> verifyEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    try {
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      print('AuthService verifyEmail error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('AuthService verifyEmail generic error: $e');
      rethrow;
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('AuthService resetPassword error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('AuthService resetPassword generic error: $e');
      rethrow;
    }
  }
}
