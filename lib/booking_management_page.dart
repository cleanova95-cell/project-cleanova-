import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cleanova/booking_detail_admin_page.dart';
import 'package:cleanova/verify_payment_page.dart';

class BookingManagementPage extends StatefulWidget {
  const BookingManagementPage({super.key});

  @override
  State<BookingManagementPage> createState() => _BookingManagementPageState();
}

class _BookingManagementPageState extends State<BookingManagementPage> {
  final Color primaryGreen = const Color(0xFF2E7D32);

  // ─────────────────────────────────────────────
  // #81 – Write a notification document so the
  //        customer can see it in their inbox.
  // ─────────────────────────────────────────────
  Future<void> _sendStatusNotification({
    required String bookingId,
    required String newStatus,
    required String customerEmail,
  }) async {
    final bookingDoc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .get();

    final data = bookingDoc.data();
    if (data == null) return;

    final String userId = data['userId'] ?? '';
    if (userId.isEmpty) return;

    // Get the customer's FCM token from users collection
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    final String fcmToken = userDoc.data()?['fcmToken'] ?? '';

    final String message = _notificationMessage(newStatus);

    // Write to notifications collection (for in-app bell icon)
    // AND include fcmToken so the Cloud Function can send the push
    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'bookingId': bookingId,
      'title': 'Booking Status Updated',
      'message': message,
      'status': newStatus,
      'isRead': false,
      'fcmToken': fcmToken,   // Cloud Function reads this to send push
      'createdAt': Timestamp.now(),
    });
  }

  String _notificationMessage(String status) {
    switch (status) {
      case 'Confirmed':
        return 'Your booking has been confirmed by the admin.';
      case 'Assigned':
        return 'A cleaner has been assigned to your booking.';
      case 'On The Way':
        return 'Your cleaner is on the way to your location!';
      case 'Arrived':
        return 'Your cleaner has arrived at your location.';
      case 'In Progress':
        return 'Cleaning is currently in progress at your place.';
      case 'Completed':
        return 'Your cleaning service has been completed. Thank you!';
      case 'Cancelled':
        return 'Your booking has been cancelled.';
      default:
        return 'Your booking status has been updated to $status.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
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
          'Booking Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No bookings found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final data = booking.data() as Map<String, dynamic>;
              final bookingId = booking.id;

              final customerEmail = data['email'] ?? 'No Email';
              final serviceType = data['service'] ?? 'No Service';
              final propertySize = data['size'] ?? 'No Size';
              final status = data['status'] ?? 'Pending';
              final address = data['address'] ?? 'No Address';
              final cleanerName = data['cleanerName'] ?? 'Not Assigned';
              final paymentStatus = (data['paymentStatus'] ?? '').toString();
              final receiptImage = data['receiptImage'] as String?;
              final price = data['price'] ?? 0;

              final bool isPendingVerification =
                  paymentStatus == 'Pending Verification';

              Timestamp? timestamp = data['bookingDate'];
              String bookingDate = 'No Date';
              if (timestamp != null) {
                final date = timestamp.toDate();
                bookingDate = '${date.day}/${date.month}/${date.year}';
              }

              final bool isFrozen =
                  status == 'Cancelled' || status == 'Completed';
              final bool isAssignDisabled = isFrozen || status == 'Confirmed';

              final String displayStatus =
              isPendingVerification ? 'Pending Verification' : status;

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: isPendingVerification
                      ? Border.all(
                    color: const Color(0xFF6A1B9A).withOpacity(0.4),
                    width: 1.5,
                  )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isPendingVerification
                          ? const Color(0xFF6A1B9A).withOpacity(0.1)
                          : Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              customerEmail,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: getStatusColor(displayStatus)
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              displayStatus,
                              style: TextStyle(
                                color: getStatusColor(displayStatus),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

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

                      const SizedBox(height: 18),
                      bookingInfo(
                          Icons.cleaning_services, 'Service Type', serviceType),
                      bookingInfo(
                          Icons.home_work, 'Property Size', propertySize),
                      bookingInfo(
                          Icons.calendar_month, 'Booking Date', bookingDate),
                      bookingInfo(Icons.location_on, 'Address', address),
                      bookingInfo(Icons.person, 'Cleaner', cleanerName),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              // #79 — pass customerEmail so notification can be sent
                              onPressed: isFrozen
                                  ? null
                                  : () => showStatusDialog(
                                  context, bookingId, status, customerEmail),
                              icon: const Icon(Icons.update,
                                  color: Colors.white),
                              label: const Text(
                                'Update',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: isAssignDisabled
                                  ? null
                                  : () => showAssignCleanerDialog(
                                  context, bookingId, customerEmail),
                              icon: const Icon(Icons.person_add,
                                  color: Colors.white),
                              label: const Text(
                                'Assign',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side:
                              BorderSide(color: primaryGreen, width: 1.5),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingDetailAdminPage(
                                    bookingId: bookingId),
                              ),
                            );
                          },
                          icon: Icon(Icons.visibility_outlined,
                              color: primaryGreen),
                          label: Text(
                            'View Details',
                            style: TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      if (isPendingVerification) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6A1B9A),
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VerifyPaymentPage(
                                  bookingId: bookingId,
                                  serviceType: serviceType,
                                  propertySize: propertySize,
                                  bookingDate: bookingDate,
                                  address: address,
                                  price: price is int
                                      ? price
                                      : (price as num).toInt(),
                                  receiptImage: receiptImage,
                                  customerEmail: customerEmail,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.receipt_long_rounded,
                                color: Colors.white),
                            label: const Text(
                              'Verify Payment',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget bookingInfo(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryGreen, size: 24),
          const SizedBox(width: 12),
          Text('$title: ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Pending Verification':
        return const Color(0xFF6A1B9A);
      case 'Confirmed':
        return Colors.teal;
      case 'Assigned':
        return Colors.green;
      case 'On The Way':
        return Colors.deepOrange;
      case 'Arrived':
        return Colors.purple;
      case 'In Progress':
        return Colors.blue;
      case 'Completed':
        return Colors.indigo;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ─────────────────────────────────────────────────────────
  // #79 — Full status list including In Progress & Completed
  // #80 — Saves new status to Firestore
  // #81 — Triggers notification after saving
  // ─────────────────────────────────────────────────────────
  void showStatusDialog(
      BuildContext context,
      String bookingId,
      String currentStatus,
      String customerEmail,
      ) {
    // All possible statuses admin can set
    List<String> statusOptions;

    if (currentStatus == 'Confirmed') {
      statusOptions = ['Pending', 'Cancelled'];
    } else if (currentStatus == 'Assigned') {
      statusOptions = ['On The Way', 'Cancelled'];
    } else if (currentStatus == 'On The Way') {
      statusOptions = ['Arrived', 'Cancelled'];
    } else if (currentStatus == 'Arrived') {
      statusOptions = ['In Progress', 'Cancelled'];
    } else if (currentStatus == 'In Progress') {
      // #79 — In Progress → Completed is now properly available
      statusOptions = ['Completed', 'Cancelled'];
    } else {
      statusOptions = ['Pending', 'Completed', 'Cancelled'];
    }

    String selectedStatus = statusOptions.contains(currentStatus)
        ? currentStatus
        : statusOptions.first;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Update Booking Status'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: statusOptions.map((status) {
                  final isSelected = selectedStatus == status;
                  return GestureDetector(
                    onTap: () => setState(() => selectedStatus = status),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? getStatusColor(status)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? getStatusColor(status)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style:
              ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              onPressed: () async {
                // #80 — Update booking status in Firestore database
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .update({
                  'status': selectedStatus,
                  'updated_at': Timestamp.now(),
                });

                // #81 — Trigger notification to customer
                await _sendStatusNotification(
                  bookingId: bookingId,
                  newStatus: selectedStatus,
                  customerEmail: customerEmail,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Booking updated to $selectedStatus'),
                    backgroundColor: primaryGreen,
                  ),
                );
              },
              child: const Text('Save',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void showAssignCleanerDialog(
      BuildContext context,
      String bookingId,
      String customerEmail,
      ) {
    String selectedCleanerId = '';
    String selectedCleanerName = '';
    String selectedCleanerEmail = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Assign Cleaner'),
          content: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'cleaner')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final cleaners = snapshot.data!.docs;

              return DropdownButtonFormField<String>(
                items: cleaners.map((cleaner) {
                  final data = cleaner.data() as Map<String, dynamic>;
                  return DropdownMenuItem(
                    value: cleaner.id,
                    child: Text(data['full_name'] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  final cleaner =
                  cleaners.firstWhere((e) => e.id == value);
                  final data = cleaner.data() as Map<String, dynamic>;
                  selectedCleanerId = cleaner.id;
                  selectedCleanerName = data['full_name'];
                  selectedCleanerEmail = data['email'];
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style:
              ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              onPressed: () async {
                if (selectedCleanerId.isEmpty) return;

                // #80 — Update Firestore with assigned cleaner + status
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .update({
                  'cleanerId': selectedCleanerId,
                  'cleanerName': selectedCleanerName,
                  'cleanerEmail': selectedCleanerEmail,
                  'status': 'Assigned',
                  'updated_at': Timestamp.now(),
                });

                // #81 — Notify customer that cleaner was assigned
                await _sendStatusNotification(
                  bookingId: bookingId,
                  newStatus: 'Assigned',
                  customerEmail: customerEmail,
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cleaner Assigned Successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Assign',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class _DialogDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DialogDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
        ),
      ],
    );
  }
}