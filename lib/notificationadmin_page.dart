import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationAdminPage extends StatefulWidget {
  @override
  _NotificationAdminPageState createState() => _NotificationAdminPageState();
}

class _NotificationAdminPageState extends State<NotificationAdminPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('jarak', isGreaterThan: 50)
          .get();

      setState(() {
        notifications = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'name': data['nama'] ?? 'Unknown',
            'distance': data['jarak'] ?? 0,
            'timestamp': DateTime.now(),
          };
        }).toList();

        if (notifications.isEmpty) {
          errorMessage = 'Tidak ada notifikasi saat ini.';
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading notifications: $e';
      });
      print(errorMessage);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifikasi'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        color: Colors.blue[100],
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : notifications.isEmpty
                    ? Center(child: Text('Tidak ada notifikasi saat ini.'))
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          final formattedTime = DateFormat('HH:mm - dd/MM/yyyy').format(notification['timestamp']);

                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formattedTime,
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  SizedBox(height: 8.0),
                                  Text(
                                    'Perhatian !!!',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Jarak ${notification['name']} terlalu jauh dari sekretariat',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Jarak saat ini: ${notification['distance'].toStringAsFixed(2)} meter',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    'Harap diingatkan untuk kembali ke sekretariat',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadNotifications,
        child: Icon(Icons.refresh),
        tooltip: 'Refresh Notifications',
      ),
    );
  }
}