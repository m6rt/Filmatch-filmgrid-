import 'package:filmgrid/services/auth_service.dart';
import 'package:flutter/material.dart';

class Logout extends StatelessWidget {
  const Logout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: IconButton(
          onPressed: AuthService().logout,
          icon: Icon(Icons.logout),
        ),
      ),
    );
  }
}
