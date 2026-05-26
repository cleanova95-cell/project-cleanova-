import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanova/job_detail_page.dart';

class CleanerHistoryPage extends StatelessWidget {
  const CleanerHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 60,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Job History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('cleanerId', isEqualTo: user?.uid)
            .where('status', isEqualTo: 'Completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.history_outlined,
                        size: 70, color: Colors.green.shade200),
                    const SizedBox(height: 20),
                    const Text(
                      'No Completed Jobs Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Your completed jobs will appear here once admin verifies your work.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          // ── Stats ─────────────────────────────────────────────
          final int totalCompleted = docs.length;
          final now = DateTime.now();
          final int thisMonthCount = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['bookingDate'] == null) return false;
            final date = (data['bookingDate'] as Timestamp).toDate();
            return date.month == now.month && date.year == now.year;
          }).length;

          // ── Group by month ────────────────────────────────────
          final Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            String monthKey = 'Unknown';
            if (data['bookingDate'] != null) {
              final date = (data['bookingDate'] as Timestamp).toDate();
              monthKey = _monthYearLabel(date);
            }
            grouped.putIfAbsent(monthKey, () => []).add(doc);
          }

          // Sort months newest first
          final sortedMonths = grouped.keys.toList()
            ..sort((a, b) {
              if (a == 'Unknown') return 1;
              if (b == 'Unknown') return -1;
              return _parseMonthYear(b).compareTo(_parseMonthYear(a));
            });

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [

              // ── Stat cards ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      Icons.check_circle_outline,
                      totalCompleted.toString(),
                      'Total Completed',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _statCard(
                      Icons.calendar_month,
                      thisMonthCount.toString(),
                      'This Month',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Grouped job cards ───────────────────────────
              ...sortedMonths.map((month) {
                final jobs = grouped[month]!;

                // Sort jobs within month newest first
                jobs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aDate = aData['bookingDate'] != null
                      ? (aData['bookingDate'] as Timestamp).toDate()
                      : DateTime(2000);
                  final bDate = bData['bookingDate'] != null
                      ? (bData['bookingDate'] as Timestamp).toDate()
                      : DateTime(2000);
                  return bDate.compareTo(aDate);
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month label
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        month,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),

                    ...jobs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final service   = data['service']  ?? '-';
                      final address   = data['address']  ?? '-';
                      final size      = data['size']     ?? '-';
                      final proofUrl  = data['proofImageUrl'] as String?;

                      String bookingDate = '-';
                      if (data['bookingDate'] != null) {
                        final date =
                        (data['bookingDate'] as Timestamp).toDate();
                        bookingDate =
                        '${date.day}/${date.month}/${date.year}  ${_formatTime(date)}';
                      }

                      String updatedAt = '-';
                      if (data['updated_at'] != null) {
                        final date =
                        (data['updated_at'] as Timestamp).toDate();
                        updatedAt =
                        '${date.day}/${date.month}/${date.year}';
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  JobDetailPage(bookingId: doc.id),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 8),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // Service name + badge
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      service,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade100,
                                      borderRadius:
                                      BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Completed',
                                      style: TextStyle(
                                        color: Colors.indigo.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),
                              Text(
                                'ID: ${doc.id}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),

                              const SizedBox(height: 12),

                              _infoRow(Icons.calendar_month, bookingDate),
                              const SizedBox(height: 8),
                              _infoRow(Icons.location_on, address),
                              const SizedBox(height: 8),
                              _infoRow(Icons.home_work, size),

                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 10),
                                child: Divider(height: 1, thickness: 0.5),
                              ),

                              // Footer
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Updated $updatedAt',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                  if (proofUrl != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.photo_outlined,
                                              size: 13,
                                              color:
                                              Colors.green.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Proof submitted',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Tap to view details',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade400),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 8),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }


  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.green, size: 32),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _monthYearLabel(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  DateTime _parseMonthYear(String label) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final parts = label.split(' ');
    if (parts.length < 2) return DateTime(2000);
    final month = months.indexOf(parts[0]) + 1;
    final year  = int.tryParse(parts[1]) ?? 2000;
    return DateTime(year, month);
  }
}