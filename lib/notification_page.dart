import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(_auth.currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final distance = userData?['jarak'] as num?;

          if (distance == null || distance <= 50) {
            notifications.clear();
            return Center(child: Text('Tidak ada notifikasi'));
          }

          // Add a new notification if the distance is greater than 50
          if (notifications.isEmpty || notifications.last['distance'] != distance) {
            notifications.insert(0, {
              'timestamp': DateTime.now(),
              'distance': distance,
            });
          }

          return Container(
            color: Colors.blue[100],
            padding: EdgeInsets.all(16.0),
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(notifications[index]['timestamp'], notifications[index]['distance']);
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: '',
          ),
        ],
        currentIndex: 2,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          // Handle navigation to different pages
        },
      ),
    );
  }

  Widget _buildNotificationCard(DateTime timestamp, num distance) {
    final timeFormatter = DateFormat('HH:mm', 'id_ID');
    final dateFormatter = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');

    final time = timeFormatter.format(timestamp);
    final date = dateFormatter.format(timestamp);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: TextStyle(fontSize: 12)),
            Text(date, style: TextStyle(fontSize: 12)),
            SizedBox(height: 8.0),
            Text(
              'Perhatian !!!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Jarak anda terlalu jauh dari sekretariat',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              'Harap kembali disekitar sekretariat',
              style: TextStyle(fontSize: 14),
            ),
            Text(
              'Jarak saat ini: ${distance.toStringAsFixed(2)} meter',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}