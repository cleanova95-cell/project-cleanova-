import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_detail_page.dart';
import 'package:cleanova/pending_payment_page.dart';
import 'package:cleanova/receipt_page.dart'; // ← tambah import

class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
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
          'Booking History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Cleaning Bookings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Track your booking details and service status easily.',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('userId', isEqualTo: user!.uid)
                  .orderBy('created_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cleaning_services,
                            size: 90, color: Colors.grey),
                        SizedBox(height: 20),
                        Text('No Booking History',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Text('Your bookings will appear here.',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var booking = snapshot.data!.docs[index];
                    final data = booking.data() as Map<String, dynamic>;

                    final service = data['service'] ?? 'No Service';
                    final size = data['size'] ?? '-';
                    final price = data['price'] ?? 0;
                    final status = (data['status'] ?? 'Pending').toString();
                    final address = data['address'] ?? '-';
                    final paymentMethod =
                    (data['paymentMethod'] ?? 'Bank Transfer').toString();
                    final paymentStatus =
                    (data['paymentStatus'] ?? '').toString();

                    DateTime date = DateTime.now();
                    if (data['bookingDate'] != null) {
                      date = data['bookingDate'].toDate();
                    }

                    // ✅ Cek payment statuses
                    final bool isPendingVerification =
                        paymentStatus == 'Pending Verification';

                    // ✅ Cek sama ada booking dah confirmed/paid (boleh tengok receipt)
                    final bool isPaid = paymentStatus == 'Paid' &&
                        (status == 'Confirmed' ||
                            status == 'Assigned' ||
                            status == 'On The Way' ||
                            status == 'Arrived' ||
                            status == 'In Progress' ||
                            status == 'Completed');

                    Color statusColor;
                    switch (status) {
                      case 'Pending':
                        statusColor = isPendingVerification
                            ? const Color(0xFF6A1B9A)
                            : Colors.orange;
                        break;
                      case 'Confirmed':
                        statusColor = Colors.green;
                        break;
                      case 'Cancelled':
                        statusColor = Colors.red;
                        break;
                      case 'Assigned':
                        statusColor = Colors.green;
                        break;
                      case 'On The Way':
                        statusColor = Colors.deepOrange.shade800;
                        break;
                      case 'Arrived':
                        statusColor = Colors.purple;
                        break;
                      case 'In Progress':
                        statusColor = Colors.blue.shade800;
                        break;
                      case 'Completed':
                        statusColor = Colors.indigo;
                        break;
                      default:
                        statusColor = Colors.indigo;
                    }

                    final String displayStatus = isPendingVerification
                        ? 'Pending Verification'
                        : status;

                    final Color displayStatusColor = isPendingVerification
                        ? const Color(0xFF6A1B9A)
                        : statusColor;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BookingDetailsPage(booking: booking),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: isPendingVerification
                              ? Border.all(
                            color: const Color(0xFF6A1B9A)
                                .withOpacity(0.4),
                            width: 1.5,
                          )
                              : isPaid
                              ? Border.all(
                            color: const Color(0xFF43A047)
                                .withOpacity(0.4),
                            width: 1.5,
                          )
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: isPendingVerification
                                  ? const Color(0xFF6A1B9A).withOpacity(0.1)
                                  : Colors.grey.shade200,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
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
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: displayStatusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    displayStatus,
                                    style: TextStyle(
                                      color: displayStatusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // ✅ Strip untuk pending verification
                            if (isPendingVerification) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3E5F5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.hourglass_top_rounded,
                                      color: Color(0xFF6A1B9A),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Receipt submitted — waiting for admin verification',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.purple.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // ✅ Strip untuk paid/confirmed
                            if (isPaid) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF43A047),
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Payment verified — booking confirmed',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 20),
                            bookingInfo(Icons.calendar_month, 'Booking Date',
                                '${date.day}/${date.month}/${date.year}'),
                            const SizedBox(height: 15),
                            bookingInfo(Icons.home, 'Property Size', size),
                            const SizedBox(height: 15),
                            bookingInfo(Icons.attach_money, 'Total Price',
                                'RM$price'),
                            const SizedBox(height: 15),
                            bookingInfo(
                                Icons.location_on, 'Address', address),
                            const SizedBox(height: 20),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Tap to view details',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey),
                              ],
                            ),

                            const SizedBox(height: 15),

                            // ✅ View Receipt button untuk booking yang dah paid
                            if (isPaid)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReceiptPage(
                                          service: service,
                                          size: size,
                                          address: address,
                                          bookingDate: date,
                                          totalPrice: price is int
                                              ? price
                                              : (price as num).toInt(),
                                          paymentMethod: paymentMethod,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.receipt_long_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'View Receipt',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFF2E7D32),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),

                            // ✅ Check Payment Status button untuk pending verification
                            if (isPendingVerification)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PendingPaymentPage(
                                          bookingId: booking.id,
                                          service: service,
                                          size: size,
                                          address: address,
                                          bookingDate: date,
                                          totalPrice: price is int
                                              ? price
                                              : (price as num).toInt(),
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.hourglass_top_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Check Payment Status',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFF6A1B9A),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),

                            // ✅ Cancel button untuk pending biasa
                            if (status == 'Pending' &&
                                !isPendingVerification)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('bookings')
                                        .doc(booking.id)
                                        .update({
                                      'status': 'Cancelled',
                                      'updated_at': Timestamp.now(),
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel Booking',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget bookingInfo(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.green),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style:
                  const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 5),
              Text(value,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}