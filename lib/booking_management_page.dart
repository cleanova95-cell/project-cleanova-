import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingManagementPage extends StatefulWidget {
  const BookingManagementPage({super.key});

  @override
  State<BookingManagementPage> createState() =>
      _BookingManagementPageState();
}

class _BookingManagementPageState
    extends State<BookingManagementPage> {

  final Color primaryGreen = const Color(0xFF2E7D32);

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
          'Booking Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .orderBy('created_at', descending: true)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No bookings found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 10,
            ),
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

              Timestamp? timestamp = data['bookingDate'];
              String bookingDate = 'No Date';

              if (timestamp != null) {
                final date = timestamp.toDate();
                bookingDate = '${date.day}/${date.month}/${date.year}';
              }

              final bool isFrozen =
                  status == 'Cancelled' || status == 'Completed';

              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
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
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
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
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: getStatusColor(status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                        ],
                      ),

                      const SizedBox(height: 18),

                      bookingInfo(Icons.cleaning_services, 'Service Type', serviceType),
                      bookingInfo(Icons.home_work, 'Property Size', propertySize),
                      bookingInfo(Icons.calendar_month, 'Booking Date', bookingDate),
                      bookingInfo(Icons.location_on, 'Address', address),
                      bookingInfo(Icons.person, 'Cleaner', cleanerName),

                      const SizedBox(height: 20),

                      Row(
                        children: [

                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: isFrozen
                                  ? null
                                  : () {
                                showStatusDialog(
                                    context, bookingId, status);
                              },
                              icon: const Icon(
                                Icons.update,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Update',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              onPressed: isFrozen
                                  ? null
                                  : () {
                                showAssignCleanerDialog(
                                    context, bookingId);
                              },
                              icon: const Icon(
                                Icons.person_add,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Assign',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        ],
                      ),

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
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Assigned':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void showStatusDialog(
      BuildContext context, String bookingId, String currentStatus) {

    String selectedStatus =
    (currentStatus == 'Assigned') ? 'Pending' : currentStatus;

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text('Update Booking Status'),

          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children:
                ['Pending', 'Completed', 'Cancelled'].map((status) {
                  final isSelected = selectedStatus == status;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedStatus = status;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
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
                          color:
                          isSelected ? Colors.white : Colors.black87,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
              ),

              onPressed: () async {

                if (selectedStatus == 'Completed' &&
                    currentStatus != 'Assigned') {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Cannot complete. Please assign a cleaner first!',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .update({
                  'status': selectedStatus,
                  'updated_at': Timestamp.now(),
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Booking updated to $selectedStatus'),
                    backgroundColor: primaryGreen,
                  ),
                );
              },

              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),

          ],
        );
      },
    );
  }

  void showAssignCleanerDialog(BuildContext context, String bookingId) {
    String selectedCleanerId = '';
    String selectedCleanerName = '';
    String selectedCleanerEmail = '';

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

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
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
              ),

              onPressed: () async {

                if (selectedCleanerId.isEmpty) return;

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

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cleaner Assigned Successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },

              child: const Text(
                'Assign',
                style: TextStyle(color: Colors.white),
              ),
            ),

          ],
        );
      },
    );
  }
}