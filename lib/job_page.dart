import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cleanova/job_detail_page.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('cleanerId', isEqualTo: user?.uid)
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
            child: Column(
              children: [
                Container(
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
                      Icon(Icons.inbox_outlined, size: 70, color: Colors.green.shade200),
                      const SizedBox(height: 20),
                      const Text(
                        'No Jobs Assigned Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'You have no jobs at the moment.\nSit tight — new jobs will appear here once assigned!',
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
              ],
            ),
          );
        }

        var bookings = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            var booking = bookings[index];
            final data = booking.data() as Map<String, dynamic>;

            final service = data['service'] ?? '-';
            final address = data['address'] ?? '-';
            final status  = (data['status'] ?? 'Pending').toString();

            String bookingDate = '-';
            if (data['bookingDate'] != null) {
              final date = (data['bookingDate'] as Timestamp).toDate();
              bookingDate = '${date.day}/${date.month}/${date.year}';
            }

            Color statusBgColor;
            Color statusTextColor;
            switch (status) {
              case 'On The Way':
                statusBgColor = Colors.orange.shade100;
                statusTextColor = Colors.orange.shade800;
                break;
              case 'Arrived':
                statusBgColor = Colors.purple.shade100;
                statusTextColor = Colors.purple.shade800;
                break;
              case 'In Progress':
                statusBgColor = Colors.blue.shade100;
                statusTextColor = Colors.blue.shade800;
                break;
              case 'Completed':
                statusBgColor = Colors.indigo.shade100;
                statusTextColor = Colors.indigo;
                break;
              case 'Cancelled':
                statusBgColor = Colors.grey.shade300;
                statusTextColor = Colors.grey;
                break;
              default:
                statusBgColor = Colors.green.shade100;
                statusTextColor = Colors.green;
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => JobDetailPage(bookingId: booking.id),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            service,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusTextColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    infoRow(Icons.calendar_month, bookingDate),
                    const SizedBox(height: 10),
                    infoRow(Icons.location_on, address),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Tap to view details',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}