import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CleanerStats {
  int completed;
  int pending;
  int cancelled;

  CleanerStats({
    this.completed = 0,
    this.pending = 0,
    this.cancelled = 0,
  });
}

class CleanerPerformancePage extends StatefulWidget {
  const CleanerPerformancePage({super.key});

  @override
  State<CleanerPerformancePage> createState() =>
      _CleanerPerformancePageState();
}

class _CleanerPerformancePageState
    extends State<CleanerPerformancePage> {
  String searchQuery = '';

  Stream<Map<String, CleanerStats>> getCleanerStatsStream() {
    return FirebaseFirestore.instance
        .collection('bookings')
        .snapshots()
        .map((snapshot) {
      final result = <String, CleanerStats>{};

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final cleanerName = data['cleanerName'] ?? 'Unassigned';
        final status = data['status']?.toString() ?? '';

        if (cleanerName == 'Unassigned') continue;

        result.putIfAbsent(cleanerName, () => CleanerStats());

        if (status == 'Completed') {
          result[cleanerName]!.completed++;
        } else if (status == 'Pending') {
          result[cleanerName]!.pending++;
        } else if (status == 'Cancelled') {
          result[cleanerName]!.cancelled++;
        }
      }

      return result;
    });
  }

  // ✅ PURE FLUTTER BAR CHART (NO PACKAGES)
  Widget buildSimpleBarChart(CleanerStats stats) {
    final max = [
      stats.completed,
      stats.pending,
      stats.cancelled
    ].reduce((a, b) => a > b ? a : b);

    double normalize(int value) {
      if (max == 0) return 0;
      return value / max;
    }

    Widget bar(String label, int value, Color color) {
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 100,
              width: 18,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: normalize(value),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        bar("Done", stats.completed, Colors.green),
        const SizedBox(width: 10),
        bar("Pending", stats.pending, Colors.orange),
        const SizedBox(width: 10),
        bar("Cancel", stats.cancelled, Colors.red),
      ],
    );
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
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: StreamBuilder<Map<String, CleanerStats>>(
        stream: getCleanerStatsStream(),
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
              child: Text("No booking data found"),
            );
          }

          final data = snapshot.data!;

          final filteredEntries = data.entries.where((entry) {
            return entry.key
                .toLowerCase()
                .contains(searchQuery);
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SEARCH
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search cleaner...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),

                const SizedBox(height: 20),

                const Text(
                  "Cleaner Performance",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                // CLEANER CARDS
                ...filteredEntries.map((entry) {
                  final stats = entry.value;

                  return Container(
                    margin:
                    const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        // ✅ BAR CHART (REPLACES CARDS)
                        buildSimpleBarChart(stats),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              "✓ ${stats.completed}",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "⏳ ${stats.pending}",
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "✕ ${stats.cancelled}",
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}