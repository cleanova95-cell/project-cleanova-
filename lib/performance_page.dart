import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CleanerPerformancePage extends StatefulWidget {
  const CleanerPerformancePage({super.key});

  @override
  State<CleanerPerformancePage> createState() =>
      _CleanerPerformancePageState();
}

class _CleanerPerformancePageState
    extends State<CleanerPerformancePage> {

  Future<List<Map<String, dynamic>>> getCleanerPerformance() async {

    QuerySnapshot jobsSnapshot = await FirebaseFirestore.instance
        .collection('jobs')
        .where('status', isEqualTo: 'completed')
        .get();

    Map<String, Map<String, dynamic>> cleanerStats = {};

    for (var doc in jobsSnapshot.docs) {

      String cleanerId = doc['cleanerId'];
      String cleanerName = doc['cleanerName'];

      if (!cleanerStats.containsKey(cleanerId)) {
        cleanerStats[cleanerId] = {
          'name': cleanerName,
          'count': 0,
        };
      }

      cleanerStats[cleanerId]!['count']++;
    }

    List<Map<String, dynamic>> results =
    cleanerStats.values.toList();

    results.sort(
          (a, b) => b['count'].compareTo(a['count']),
    );

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cleaner Performance"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getCleanerPerformance(),
        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No completed jobs found"),
            );
          }

          final cleaners = snapshot.data!;

          return ListView.builder(
            itemCount: cleaners.length,
            itemBuilder: (context, index) {

              final cleaner = cleaners[index];

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      "${index + 1}",
                    ),
                  ),
                  title: Text(cleaner['name']),
                  subtitle: const Text(
                    "Completed Jobs",
                  ),
                  trailing: Text(
                    cleaner['count'].toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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