import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobsPage extends StatelessWidget {
  const JobsPage({super.key});

  @override
  Widget build(BuildContext context) {

    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),

      body: StreamBuilder(
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
            return const Center(
              child: Text(
                'No Assigned Jobs Yet',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
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
              final email = data['email'] ?? '-';
              final address = data['address'] ?? '-';
              final size = data['size'] ?? '-';
              final price = data['price'] ?? 0;
              final status = (data['status'] ?? 'Pending').toString();

              bool isCancelled = status == 'Cancelled';
              bool isCompleted = status == 'Completed';

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
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
                              fontSize: 22,
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
                            color: isCancelled
                                ? Colors.grey.shade300
                                : isCompleted
                                ? Colors.blue.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isCancelled
                                  ? Colors.grey
                                  : isCompleted
                                  ? Colors.blue
                                  : Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      ],
                    ),

                    const SizedBox(height: 18),

                    infoRow(Icons.person, email),
                    const SizedBox(height: 12),
                    infoRow(Icons.location_on, address),
                    const SizedBox(height: 12),
                    infoRow(Icons.home_work, size),
                    const SizedBox(height: 12),
                    infoRow(Icons.attach_money, 'RM $price'),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 55,

                      child: ElevatedButton(
                        onPressed: isCancelled || isCompleted
                            ? null
                            : () async {

                          final doc = await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(booking.id)
                              .get();

                          final data = doc.data();

                          if (data?['cleanerId'] != user?.uid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Not your job'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (data?['status'] != 'Assigned') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Job not ready'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(booking.id)
                              .update({
                            'status': 'Completed',
                            'updated_at': Timestamp.now(),
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Job Marked As Completed'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },

                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCancelled || isCompleted
                              ? Colors.grey
                              : Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),

                        child: Text(
                          isCancelled
                              ? 'Job Cancelled'
                              : isCompleted
                              ? 'Job Completed'
                              : 'Mark As Completed',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.green, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 15),
          ),
        ),
      ],
    );
  }
}