import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CleanerPerformancePage extends StatelessWidget {
  const CleanerPerformancePage({super.key});

  Future<Map<String, int>> getCompletedJobsPerCleaner() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: 'Completed')
        .get();

    Map<String, int> result = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final cleanerName = data['cleanerName'] ?? 'Unassigned';

      if (cleanerName != 'Unassigned') {
        result[cleanerName] = (result[cleanerName] ?? 0) + 1;
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      appBar: AppBar(
        title: const Text(
          "Cleaner Performance",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF43A047),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: getCompletedJobsPerCleaner(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;

          if (data.isEmpty) {
            return const Center(
              child: Text(
                "No completed jobs yet",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: data.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${entry.value} jobs",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}