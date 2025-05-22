import 'package:filmgrid/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:filmgrid/views/login_view.dart';
import 'package:filmgrid/views/register_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class Homeview extends StatefulWidget {
  const Homeview({super.key});

  @override
  State<Homeview> createState() => _HomeviewState();
}

class _HomeviewState extends State<Homeview> {
  File? tempProfilePicture;
  String username = '';
  final ImagePicker picker = ImagePicker();
  final firebase_storage.FirebaseStorage storage =
      firebase_storage.FirebaseStorage.instance;
  final user = AuthService().currentUser;

  @override
  void dispose() {
    super.dispose();
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Kullanıcı dışarı tıklayarak kapatamasın
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<void> _checkUsername() async {

    try {
      // Kullanıcının UID'sine göre Firestore'dan belgeyi al
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user?.uid) // UID'ye göre belgeyi al
              .get();

      // Belge yoksa veya 'username' alanı eksikse, kullanıcı adı diyalogunu göster
      if (!doc.exists || doc.data()?['username'] == null) {
        _showUsernameDialog();
      }
    } catch (e) {
      // Hata durumunda konsola yazdır
      print("Kullanıcı adı kontrol hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bir hata oluştu, lütfen tekrar deneyin.")),
      );
    }
  }

  Future<bool> _isUsernameTaken(String username) async {
    // Kullanıcı adını küçük harfe çevirerek kontrol et olup olmadıgını kontrol et
    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username.toLowerCase())
            .get();

    print("isUsername işlemi tamam");
    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> _saveUserCredits(String username, profilePhoto, uid) async {
    try {
      firebase_storage.Reference ref = storage
          .ref()
          .child('profile_pictures')
          .child(
            '${AuthService().currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
      firebase_storage.UploadTask uploadTask = ref.putFile(tempProfilePicture!);
      await uploadTask;
      String profileImageURL = await ref.getDownloadURL();
      try {
        FirebaseFirestore.instance.collection('users').doc(uid).set({
          'profilePictureURL': profileImageURL,
          'username': username.toLowerCase(),
          'dateTime': DateTime.now(),
        });
        Navigator.pop(context);
        Navigator.pop(context);
        print("profil picture url kaydetme tamam");
      } catch (e) {
        Navigator.pop(context);
        print("profilurl kısmı hatalı $e");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Bir hata oluştu")));
        Navigator.pop(context);
        _showUsernameDialog();
        return;
      }
      print("profile picture tamam");
    } catch (e) {
      Navigator.pop(context);
      print("saveprofilephoto fonksiyonu hatalı: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Bir hata oluştu")));
      Navigator.pop(context);
      _showUsernameDialog();
      return;
    }
  }

  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUsername();
    });
  }

  Future<void> _showUsernameDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Kullanıcı dışarı tıklayarak kapatamasın
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Profil Bilgilerinizi Girin',
                style: TextStyle(fontFamily: "PlayfairDisplay"),
              ),
              content: SizedBox(
                height: 200,
                width: 200,

                child: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(30, 15, 30, 0),
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.transparent,

                              border: Border.all(),
                              shape: BoxShape.circle,
                            ),

                            child: GestureDetector(
                              onTap: () async {
                                try {
                                  final XFile? pickedFile = await picker
                                      .pickImage(
                                        source: ImageSource.gallery,
                                        imageQuality: 50,
                                        maxWidth: 800,
                                        maxHeight: 800,
                                      );
                                  if (pickedFile != null) {
                                    setState(() {
                                      tempProfilePicture = File(
                                        pickedFile.path,
                                      );
                                    });
                                  }
                                } catch (e) {
                                  print("$e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Bir hata oluştu")),
                                  );
                                  return;
                                }
                              },
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    tempProfilePicture != null
                                        ? FileImage(tempProfilePicture!)
                                        : null,
                                child:
                                    tempProfilePicture == null
                                        ? Icon(Icons.add_a_photo)
                                        : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      TextField(
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        cursorColor: Colors.black,

                        decoration: InputDecoration(
                          labelText: "username",
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 12,
                          ),
                          border: InputBorder.none,
                        ),
                        keyboardType: TextInputType.name,
                        onChanged: (value) {
                          username = value;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Kaydet',
                    style: TextStyle(
                      fontFamily: "PlayfairDisplay",
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () async {
                    print(
                      "Şu anki kullanıcı UID: ${AuthService().currentUser?.uid}",
                    );
                    if (AuthService().currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lütfen giriş yapın!')),
                      );
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterView()),
                      );
                    }
                    if (username.isNotEmpty) {
                      if (await _isUsernameTaken(username.toLowerCase()) ==
                          false) {
                        if (tempProfilePicture != null) {
                          _showLoadingDialog();
                          _saveUserCredits(
                            username,
                            tempProfilePicture,
                            AuthService().currentUser!.uid,
                          );
                        } else {
                          //profile fotografı elsesi
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Lütfen bir profil fotografı seçiniz",
                              ),
                            ),
                          );
                        }
                      } else {
                        // kullanıcı adı kullanılıyor elsesi
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Kullanıcı ismi zaten kullanılıyor"),
                          ),
                        );
                        print("kullanıcı hatası alıyon 3311313");
                      }
                    } else {
                      //Kullanıcı adı boş elsesesi
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Lütfen bir kullanıcı adı girin'),
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

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
