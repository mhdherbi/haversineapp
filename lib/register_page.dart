import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _register() async {
    try {
      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;
      
      // Generate QR code
      final qrValidationResult = QrValidator.validate(
        data: uid,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      
      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          color: const Color(0xFF000000),
          gapless: true,
        );

        // Save QR code image to temporary directory
        Directory tempDir = await getTemporaryDirectory();
        String tempPath = '${tempDir.path}/$uid.png';
        final picData = await painter.toImageData(300);
        await File(tempPath).writeAsBytes(picData!.buffer.asUint8List());

        // Upload QR code image to Firebase Storage
        File qrFile = File(tempPath);
        TaskSnapshot uploadTask = await _storage.ref('qr_codes/$uid.png').putFile(qrFile);
        String downloadURL = await uploadTask.ref.getDownloadURL();

        // Save user information to Firestore
        await _firestore.collection('users').doc(uid).set({
          'email': _emailController.text.trim(),
          'nama': _nameController.text.trim(),
          'role': 'pengurus', // or 'admin' based on your logic
          'status_piket': false,
          'jarak': '',
          'id_user_path': downloadURL,
        });

        // Save session information with SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userEmail', _emailController.text.trim());
        await prefs.setString('userName', _nameController.text.trim());
        await prefs.setString('userRole', 'pengurus'); // or 'admin' based on your logic

        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registrasi berhasil!')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to generate QR code');
      }
    } catch (e) {
      // Handle registration errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registrasi gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3399FF), Color(0xFF66CCFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: TabButton(text: 'sign in', isActive: false),
                          ),
                          SizedBox(width: 10),
                          TabButton(text: 'sign up', isActive: true),
                        ],
                      ),
                      SizedBox(height: 20),
                      InputField(
                        icon: Icons.person,
                        hintText: 'Nama Lengkap',
                        isPassword: false,
                        controller: _nameController,
                      ),
                      SizedBox(height: 15),
                      InputField(
                        icon: Icons.email,
                        hintText: 'Email Address',
                        isPassword: false,
                        controller: _emailController,
                      ),
                      SizedBox(height: 15),
                      InputField(
                        icon: Icons.lock,
                        hintText: 'Password',
                        isPassword: true,
                        controller: _passwordController,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          minimumSize: Size(double.infinity, 0),
                        ),
                        onPressed: _register,
                        child: Text('DAFTAR'),
                      ),
                    ],
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

class TabButton extends StatelessWidget {
  final String text;
  final bool isActive;

  TabButton({required this.text, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? Colors.grey[300] : Colors.transparent,
          borderRadius: BorderRadius.circular(20.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 10.0),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}

class InputField extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final bool isPassword;
  final TextEditingController controller;

  InputField({required this.icon, required this.hintText, required this.isPassword, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Icon(icon, size: 20),
          ),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
