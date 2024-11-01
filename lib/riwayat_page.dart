import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import intl package
import 'dashboard_page.dart'; // Import your existing DashboardPage

class RiwayatPiketPage extends StatefulWidget {
  @override
  _RiwayatPiketPageState createState() => _RiwayatPiketPageState();
}

class _RiwayatPiketPageState extends State<RiwayatPiketPage> {
  int currentPage = 1;
  int selectedIndex = 0;
  final int itemsPerPage = 10;
  List<Map<String, dynamic>> historyData = [];
  Map<String, dynamic>? _userData;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get(); // Replace 'currentUserId' with actual method to get the current user ID
      setState(() {
        _userData = userDoc.data() as Map<String, dynamic>?;
        _currentUserId = userDoc.id; // Get the user ID from the document
        print(_userData);
      });

      if (_userData != null) {
        fetchHistoryData();
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  void fetchHistoryData() async {
    if (_currentUserId != null) { // Check if currentUserId is available
      CollectionReference historyRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('history');

      QuerySnapshot querySnapshot = await historyRef.get();
      setState(() {
        historyData = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    } else {
      print('User ID is not available.');
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    return DateFormat('dd-MM-yy').format(timestamp.toDate());
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
    }
  }

  void _nextPage() {
    if ((currentPage * itemsPerPage) < historyData.length) {
      setState(() {
        currentPage++;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DashboardPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the paginated subset of historyData
    List<Map<String, dynamic>> paginatedData = historyData
        .skip((currentPage - 1) * itemsPerPage)
        .take(itemsPerPage)
        .toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.lightBlueAccent],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 20),
              child: Text(
                'Riwayat Piket',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('No')),
                        DataColumn(label: Text('Tanggal')),
                        DataColumn(label: Text('Jam Masuk')),
                        DataColumn(label: Text('Jam Keluar')),
                      ],
                      rows: List<DataRow>.generate(
                        paginatedData.length,
                        (index) {
                          var item = paginatedData[index];
                          return DataRow(cells: [
                            DataCell(Text('${index + 1 + (currentPage - 1) * itemsPerPage}')),
                            DataCell(Text(item['tanggal'] != null ? formatTimestamp(item['tanggal']) : '')),
                            DataCell(Text(item['jam_masuk'] ?? '')),
                            DataCell(Text(item['jam_keluar'] ?? '')),
                          ]);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_left, color: Colors.white),
                    onPressed: _previousPage,
                  ),
                  Text(
                    '$currentPage',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_right, color: Colors.white),
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.assignment,
              color: selectedIndex == 0 ? Colors.blue : Colors.black,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: selectedIndex == 1 ? Colors.blue : Colors.black,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.notifications,
              color: selectedIndex == 2 ? Colors.blue : Colors.black,
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.logout,
              color: selectedIndex == 3 ? Colors.blue : Colors.black,
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}
