import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cleanova/performance_page.dart';

class CleanerPerformancePage extends StatelessWidget {
  const CleanerPerformancePage({super.key});

  Future<List<Map<String, dynamic>>> fetchCleanerStats() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: 'Completed')
        .get();

    Map<String, Map<String, dynamic>> stats = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final cleanerId = data['cleanerId'] ?? 'unknown';
      final cleanerName = data['cleanerName'] ?? 'Unknown';

      if (!stats.containsKey(cleanerId)) {
        stats[cleanerId] = {
          'name': cleanerName,
          'count': 0,
        };
      }

      stats[cleanerId]!['count'] =
          (stats[cleanerId]!['count'] as int) + 1;
    }

    return stats.entries
        .map((e) => {
      'cleanerId': e.key,
      'name': e.value['name'],
      'count': e.value['count'],
    })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cleaner Performance"),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: FutureBuilder(
        future: fetchCleanerStats(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data as List;

          if (data.isEmpty) {
            return const Center(
              child: Text("No completed jobs yet"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final cleaner = data[index];

              return Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.cleaning_services,
                    color: Color(0xFF2E7D32),
                  ),
                  title: Text(cleaner['name']),
                  subtitle: Text("ID: ${cleaner['cleanerId']}"),
                  trailing: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${cleaner['count']} jobs",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}