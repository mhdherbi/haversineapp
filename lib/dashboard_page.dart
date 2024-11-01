import 'package:flutter/material.dart';
import 'package:haversineapp/riwayat_page.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_page.dart'; // Import halaman notifikasi
import 'login_page.dart'; // Import halaman login
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:location/location.dart';
import 'dart:math';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Location _location = Location();
  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isTracking = false;
  bool _wasPiketActive = false; // Variable to track previous status

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _fetchUserData();
      _monitorPiketStatus();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      setState(() {
        _userData = userDoc.data() as Map<String, dynamic>;
        _wasPiketActive = _userData!['status_piket'] ?? false;
      });

      if (_userData != null && _userData!['status_piket'] == true) {
        _startTracking();
      } else {
        _resetDistance();
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  double _calculateHaversine(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371000; // Radius of the Earth in meters
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1); // Corrected calculation
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) {
    return deg * (pi / 180);
  }

  Future<void> _updateDistanceToUser() async {
    try {
      DocumentSnapshot comparisonUserDoc = await _firestore.collection('users').doc('XCpjtI1vuUhd1w0AKeMgrcTDcuZ2').get();
      if (comparisonUserDoc.exists) {
        GeoPoint comparisonGeoPoint = comparisonUserDoc['location'];
        GeoPoint currentGeoPoint = _userData!['location'];
        double distance = _calculateHaversine(
          currentGeoPoint.latitude,
          currentGeoPoint.longitude,
          comparisonGeoPoint.latitude,
          comparisonGeoPoint.longitude,
        );
        distance = double.parse(distance.toStringAsFixed(2)); // Ambil 2 angka di belakang koma
        await _firestore.collection('users').doc(_currentUser!.uid).set({
          'jarak': distance,
        }, SetOptions(merge: true));
        setState(() {
          _userData!['jarak'] = distance;
        });
      }
    } catch (e) {
      print('Error updating distance: $e');
    }
  }

  Future<void> _resetDistance() async {
    try {
      await _firestore.collection('users').doc(_currentUser!.uid).set({
        'jarak': 0,
      }, SetOptions(merge: true));
      setState(() {
        _userData!['jarak'] = 0;
      });
    } catch (e) {
      print('Error resetting distance: $e');
    }
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
    });

    _location.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null && _isTracking) {
        _firestore.collection('users').doc(_currentUser!.uid).set({
          'location': GeoPoint(currentLocation.latitude!, currentLocation.longitude!)
        }, SetOptions(merge: true)).then((_) {
          print('Location updated successfully');
          if (_userData!['status_piket'] == true) {
            _updateDistanceToUser(); // Update distance after location update
          }
        }).catchError((error) {
          print('Failed to update location: $error');
        });
      }
    });

    // Listen to changes in the user's location field in Firestore
    _firestore.collection('users').doc(_currentUser!.uid).snapshots().listen((userDoc) {
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
        });
        if (_userData!['status_piket'] == true) {
          _updateDistanceToUser(); // Update distance when location changes in Firestore
        } else {
          _resetDistance();
        }
      }
    });
  }

  void _monitorPiketStatus() {
    // Listen to changes in the user's status_piket field in Firestore
    _firestore.collection('users').doc(_currentUser!.uid).snapshots().listen((userDoc) {
      if (userDoc.exists) {
        setState(() {
          bool currentPiketStatus = userDoc['status_piket'];
          if (currentPiketStatus && !_wasPiketActive) {
            // Create a new document in the history sub-collection with the current timestamp
            _firestore.collection('users').doc(_currentUser!.uid).collection('history').add({
              'tanggal': Timestamp.now(),
              'jam_masuk': DateFormat('HH:mm').format(DateTime.now()),
            });
            _startTracking();
          } else if (!currentPiketStatus && _wasPiketActive) {
            _resetDistance();
          }
          _wasPiketActive = currentPiketStatus;
        });
      }
    });
  }

  void _stopTracking() {
    setState(() {
      _isTracking = false;
    });
    _location.onLocationChanged.drain();
  }

  @override
  void dispose() {
    _stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00A2E8), // Set background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _userData == null
              ? Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selamat Bertugas,',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _userData!['nama'],
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          // Tampilkan waktu saat ini
                          Text(
                            DateFormat("HH:mm, EEEE - dd MMMM yyyy").format(DateTime.now()),
                            style: TextStyle(fontSize: 14),
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF007BFF),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              ),
                              onPressed: () {
                                _showQRDialog(context, _userData!['id_user_path']);
                              },
                              child: Text(
                                'QR Saya',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Container(
                      padding: EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jarak Saya:',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            '${_userData!['jarak']} Meter',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    // Container(
                    //   padding: EdgeInsets.all(16.0),
                    //   decoration: BoxDecoration(
                    //     color: Colors.white,
                    //     borderRadius: BorderRadius.circular(10),
                    //   ),
                    //   child: Row(
                    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //     children: [
                    //       Text(
                    //         'Durasi Piket:',
                    //         style: TextStyle(fontSize: 16),
                    //       ),
                    //       Text(
                    //         '${_userData!['durasi']} Jam Xx Menit',
                    //         style: TextStyle(fontSize: 16),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white, // White button background
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: Colors.black), // Black border
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                        ),
                        onPressed: () {
                          _showFinishShiftDialog(context);
                        },
                        child: Text(
                          'Selesaikan Piket',
                          style: TextStyle(color: Colors.black), // Black text
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.assignment),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RiwayatPiketPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationPage()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQRDialog(BuildContext context, String qrImagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('QR Code Anda'),
              SizedBox(height: 10),
              Image.network(qrImagePath),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Tutup'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Logout'),
          content: Text('Apakah kamu yakin akan logout?'),
          actions: <Widget>[
            TextButton(
              child: Text('Tidak'),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
            ),
            TextButton(
              child: Text('Ya'),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                _logout(context); // Panggil fungsi logout
              },
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) async {
    _stopTracking(); // Hentikan pelacakan lokasi
    // Hapus session login user
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Navigasi ke halaman login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _showFinishShiftDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Selesaikan Piket'),
          content: Text('Apakah kamu yakin akan menyelesaikan piket?'),
          actions: <Widget>[
            TextButton(
              child: Text('Tidak'),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
            ),
            TextButton(
              child: Text('Ya'),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                _finishShiftAction(); // Panggil metode untuk menyelesaikan piket
              },
            ),
          ],
        );
      },
    );
  }

  void _finishShiftAction() async {
    try {
      // Update field 'status_piket' to false in Firestore
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'status_piket': false,
      });

      // Update the last entry in the history sub-collection with the current time for jam_keluar
      QuerySnapshot historySnapshot = await _firestore
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('history')
          .orderBy('tanggal', descending: true)
          .limit(1)
          .get();

      if (historySnapshot.docs.isNotEmpty) {
        DocumentSnapshot lastEntry = historySnapshot.docs.first;
        await lastEntry.reference.update({
          'jam_keluar': DateFormat('HH:mm').format(DateTime.now()),
        });
      }

      // Reset distance
      await _resetDistance();

      // Stop tracking
      _stopTracking();

      print("Piket selesai, status_piket diubah menjadi false.");
    } catch (e) {
      print('Error updating status_piket or jam_keluar: $e');
    }
  }
}