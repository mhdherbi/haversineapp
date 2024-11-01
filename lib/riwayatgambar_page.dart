import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class RiwayatGambarPage extends StatefulWidget {
  @override
  _RiwayatGambarPageState createState() => _RiwayatGambarPageState();
}

class _RiwayatGambarPageState extends State<RiwayatGambarPage> {
  Future<List<Map<String, dynamic>>> _getImageData() async {
    final ListResult result = await FirebaseStorage.instance
        .ref('data') // Adjust the path to match your Firebase Storage path
        .listAll();

    final List<Map<String, dynamic>> imageData = await Future.wait(
      result.items.map((Reference ref) async {
        final String url = await ref.getDownloadURL();
        final FullMetadata metadata = await ref.getMetadata();
        return {
          'url': url,
          'timestamp': metadata.timeCreated,
        };
      }).toList(),
    );

    return imageData;
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown';
    return DateFormat('HH:mm, dd-MM-yyyy').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Gambar'),
        backgroundColor: Colors.blue,
      ),
      body: Container(
        color: Colors.blue,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _getImageData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error fetching images'));
            }
            final imageData = snapshot.data ?? [];
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                itemCount: imageData.length,
                itemBuilder: (context, index) {
                  final data = imageData[index];
                  return Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CachedNetworkImage(
                            imageUrl: data['url'],
                            placeholder: (context, url) =>
                                CircularProgressIndicator(),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Text(
                            _formatTimestamp(data['timestamp']),
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}