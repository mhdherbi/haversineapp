import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RiwayatPiketAdminPage extends StatefulWidget {
  @override
  _RiwayatPiketPageState createState() => _RiwayatPiketPageState();
}

class _RiwayatPiketPageState extends State<RiwayatPiketAdminPage> {
  int currentPage = 1;
  final int itemsPerPage = 10;
  List<Map<String, dynamic>> data = [];
  List<Map<String, dynamic>> userNames = [];
  String? selectedUser;

  @override
  void initState() {
    super.initState();
    fetchUserNames();
  }

  Future<void> fetchUserNames() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('users').get();
    final docs = querySnapshot.docs;

    setState(() {
      userNames = docs.map((doc) => {"id": doc.id, "name": doc['nama']}).toList();
      if (userNames.isNotEmpty) {
        selectedUser = userNames[0]['id'];
        fetchData(userNames[0]['id']);
      }
    });
  }

  Future<void> fetchData(String userId) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('history')
        .get();
    final docs = querySnapshot.docs;

    setState(() {
      data = docs.asMap().entries.map((entry) {
        final index = entry.key;
        final doc = entry.value;
        final docData = doc.data() as Map<String, dynamic>;
        return {
          "No": (index + 1).toString(), // Use index + 1 for sequential numbering
          "Tanggal": docData.containsKey('tanggal') && docData['tanggal'] is Timestamp 
                      ? DateFormat('yyyy-MM-dd').format(docData['tanggal'].toDate())
                      : '',
          "Waktu Masuk": docData.containsKey('jam_masuk') ? docData['jam_masuk'] : '',
          "Waktu Keluar": docData.containsKey('jam_keluar') ? docData['jam_keluar'] : '',
        };
      }).toList();
    });
  }

  List<Map<String, dynamic>> get currentData {
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    return data.sublist(start, end > data.length ? data.length : end);
  }

  void nextPage() {
    setState(() {
      if (currentPage * itemsPerPage < data.length) {
        currentPage++;
      }
    });
  }

  void previousPage() {
    setState(() {
      if (currentPage > 1) {
        currentPage--;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Riwayat Piket Pengurus'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedUser,
              onChanged: (String? newValue) {
                setState(() {
                  selectedUser = newValue;
                  if (newValue != null) {
                    fetchData(newValue);
                  }
                });
              },
              items: userNames.map<DropdownMenuItem<String>>((user) {
                return DropdownMenuItem<String>(
                  value: user['id'],
                  child: Text(user['name']),
                );
              }).toList(),
              hint: Text('Pilih Nama Pengurus'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('No')),
                      DataColumn(label: Text('Tanggal')),
                      DataColumn(label: Text('Waktu Masuk')),
                      DataColumn(label: Text('Waktu Keluar')),
                    ],
                    rows: currentData
                        .map((item) => DataRow(cells: [
                              DataCell(Text(item['No'])),
                              DataCell(Text(item['Tanggal'])),
                              DataCell(Text(item['Waktu Masuk'])),
                              DataCell(Text(item['Waktu Keluar'])),
                            ]))
                        .toList(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left),
                  onPressed: previousPage,
                ),
                Text(currentPage.toString()),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: nextPage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}