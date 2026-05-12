import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDetailsPage extends StatelessWidget {

  final QueryDocumentSnapshot booking;

  const BookingDetailsPage({
    super.key,
    required this.booking,
  });

  Future<void> cancelBooking(
      BuildContext context,
      ) async {

    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(booking.id)
        .update({

      'status': 'Cancelled',
      'updated_at': Timestamp.now(),

    });

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(
        content: Text(
          'Booking Cancelled Successfully',
        ),
        backgroundColor: Colors.red,
      ),

    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    DateTime date =
    booking['bookingDate'].toDate();

    bool isPending =
        booking['status'] == 'Pending';

    bool isCancelled =
        booking['status'] == 'Cancelled';

    Color statusColor;

    if (booking['status'] == 'Pending') {

      statusColor = Colors.orange;

    } else if (booking['status'] ==
        'Cancelled') {

      statusColor = Colors.red;

    } else if (booking['status'] ==
        'Assigned') {

      statusColor = Colors.blue;

    } else {

      statusColor = Colors.green;
    }

    return Scaffold(

      backgroundColor: const Color(0xFFF1FFF3),

      appBar: AppBar(

        elevation: 0,

        iconTheme: const IconThemeData(
          color: Colors.white,
        ),

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF43A047),
                Color(0xFF66BB6A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        title: const Text(
          'Booking Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            Container(

              width: double.infinity,

              padding: const EdgeInsets.all(25),

              decoration: BoxDecoration(

                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF43A047),
                    Color(0xFF66BB6A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),

                borderRadius:
                BorderRadius.circular(30),
              ),

              child: Column(

                children: [

                  const Icon(
                    Icons.cleaning_services,
                    color: Colors.white,
                    size: 70,
                  ),

                  const SizedBox(height: 20),

                  Text(
                    booking['service'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Container(

                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),

                    decoration: BoxDecoration(

                      color: Colors.white,

                      borderRadius:
                      BorderRadius.circular(20),
                    ),

                    child: Text(

                      booking['status'],

                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 25),

            detailsCard(
              Icons.home,
              'Property Size',
              booking['size'],
            ),

            const SizedBox(height: 18),

            detailsCard(
              Icons.location_on,
              'Address',
              booking['address'],
            ),

            const SizedBox(height: 18),

            detailsCard(
              Icons.calendar_month,
              'Booking Date',
              '${date.day}/${date.month}/${date.year}',
            ),

            const SizedBox(height: 18),

            detailsCard(
              Icons.attach_money,
              'Total Price',
              'RM${booking['price']}',
            ),

            const SizedBox(height: 18),

            detailsCard(
              Icons.email,
              'Customer Email',
              booking['email'],
            ),

            // =========================
            // ASSIGNED CLEANER
            // ONLY SHOW IF ASSIGNED
            // OR COMPLETED
            // =========================

            if (
            booking['status'] == 'Assigned' ||
                booking['status'] == 'Completed'
            ) ...[

              const SizedBox(height: 18),

              detailsCard(
                Icons.cleaning_services,
                'Assigned Cleaner',
                booking['cleanerName'],
              ),

            ],

            const SizedBox(height: 35),

            Container(

              width: double.infinity,

              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(

                color:
                statusColor.withValues(
                  alpha: 0.12,
                ),

                borderRadius:
                BorderRadius.circular(22),
              ),

              child: Row(

                children: [

                  Icon(
                    Icons.info,
                    color: statusColor,
                  ),

                  const SizedBox(width: 12),

                  Expanded(

                    child: Text(

                      isPending
                          ? 'Your booking is waiting for cleaner confirmation.'
                          : isCancelled
                          ? 'This booking has been cancelled.'
                          : booking['status'] == 'Assigned'
                          ? 'Cleaner has been assigned to your booking.'
                          : 'Your cleaning service is completed.',

                      style: TextStyle(
                        color: statusColor,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),

                ],
              ),
            ),

            // =========================
            // CANCEL BUTTON
            // ONLY FOR PENDING
            // =========================

            if (isPending) ...[

              const SizedBox(height: 35),

              SizedBox(

                width: double.infinity,
                height: 58,

                child: ElevatedButton(

                  onPressed: () async {

                    showDialog(

                      context: context,

                      builder: (context) {

                        return AlertDialog(

                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              20,
                            ),
                          ),

                          title: const Text(
                            'Cancel Booking?',
                          ),

                          content: const Text(
                            'Are you sure you want to cancel this booking?',
                          ),

                          actions: [

                            TextButton(

                              onPressed: () {

                                Navigator.pop(
                                  context,
                                );
                              },

                              child: const Text(
                                'No',
                              ),
                            ),

                            ElevatedButton(

                              onPressed: () async {

                                Navigator.pop(
                                  context,
                                );

                                await cancelBooking(
                                  context,
                                );
                              },

                              style:
                              ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.red,
                              ),

                              child: const Text(
                                'Yes',
                                style: TextStyle(
                                  color:
                                  Colors.white,
                                ),
                              ),
                            ),

                          ],
                        );
                      },
                    );
                  },

                  style: ElevatedButton.styleFrom(

                    backgroundColor: Colors.red,

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                  ),

                  child: const Text(
                    'Cancel Booking',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            ],

            const SizedBox(height: 30),

          ],
        ),
      ),
    );
  }

  Widget detailsCard(
      IconData icon,
      String title,
      String value,
      ) {

    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
        BorderRadius.circular(25),

        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Row(

        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Container(

            padding: const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: Colors.green.shade100,

              borderRadius:
              BorderRadius.circular(16),
            ),

            child: Icon(
              icon,
              color: Colors.green,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(

            child: Column(

              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }
}