import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobDetailPage extends StatelessWidget {
  final String bookingId;

  const JobDetailPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      appBar: AppBar(
        elevation: 0,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Job Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Job not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final service = data['service'] ?? '-';
          final email   = data['email']   ?? '-';
          final address = data['address'] ?? '-';
          final size    = data['size']    ?? '-';
          final status  = (data['status'] ?? 'Pending').toString();

          String bookingDate = '-';
          if (data['bookingDate'] != null) {
            final date = (data['bookingDate'] as Timestamp).toDate();
            bookingDate = '${date.day}/${date.month}/${date.year}  ${_formatTime(date)}';
          }

          String createdAt = '-';
          if (data['created_at'] != null) {
            final date = (data['created_at'] as Timestamp).toDate();
            createdAt = '${date.day}/${date.month}/${date.year}';
          }

          String updatedAt = '-';
          if (data['updated_at'] != null) {
            final date = (data['updated_at'] as Timestamp).toDate();
            updatedAt = '${date.day}/${date.month}/${date.year}';
          }

          final bool isCancelled = status == 'Cancelled';
          final bool isCompleted = status == 'Completed';
          final bool isFinal = isCancelled || isCompleted;

          Color statusBgColor;
          Color statusTextColor;
          switch (status) {
            case 'On The Way':
              statusBgColor = Colors.deepOrange.shade100;
              statusTextColor = Colors.deepOrange.shade800;
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
              statusBgColor = Colors.red.shade200;
              statusTextColor = Colors.red;
              break;
            default:
              statusBgColor = Colors.green.shade100;
              statusTextColor = Colors.green;
          }

          String nextStatusLabel = '';
          Color btnColor = Colors.green;
          IconData btnIcon = Icons.check_circle_outline;

          switch (status) {
            case 'Assigned':
              nextStatusLabel = "I'm On The Way";
              btnColor = Colors.orange;
              btnIcon = Icons.directions_car;
              break;
            case 'On The Way':
              nextStatusLabel = "I've Arrived";
              btnColor = Colors.purple;
              btnIcon = Icons.location_on;
              break;
            case 'Arrived':
              nextStatusLabel = 'Start Cleaning';
              btnColor = Colors.blue;
              btnIcon = Icons.cleaning_services;
              break;
            case 'In Progress':
              nextStatusLabel = 'Mark As Completed';
              btnColor = const Color(0xFF43A047);
              btnIcon = Icons.check_circle_outline;
              break;
            case 'Completed':
              nextStatusLabel = 'Job Completed';
              btnColor = Colors.grey;
              btnIcon = Icons.check_circle_outline;
              break;
            case 'Cancelled':
              nextStatusLabel = 'Job Cancelled';
              btnColor = Colors.grey;
              btnIcon = Icons.cancel_outlined;
              break;
          }

          final List<String> stepLabels = ['Assigned', 'On The Way', 'Arrived', 'In Progress', 'Completed'];
          final int currentStep = stepLabels.indexOf(status);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [

                _card(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: $bookingId',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                ),

                const SizedBox(height: 14),

                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Progress'),
                      Row(
                        children: List.generate(stepLabels.length * 2 - 1, (i) {
                          if (i.isOdd) {
                            final lineIndex = i ~/ 2;
                            final isDone = currentStep > lineIndex;
                            return Expanded(
                              child: Container(
                                height: 2,
                                color: isDone ? const Color(0xFF43A047) : Colors.grey.shade200,
                              ),
                            );
                          }
                          final stepIndex = i ~/ 2;
                          final isDone = currentStep > stepIndex ||
                              (status == 'Completed' && stepIndex == stepLabels.length - 1);
                          final isActive = currentStep == stepIndex && !isCompleted;
                          return Column(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDone
                                      ? const Color(0xFF43A047)
                                      : isActive
                                      ? Colors.white
                                      : Colors.grey.shade100,
                                  border: isActive
                                      ? Border.all(color: const Color(0xFF43A047), width: 2)
                                      : null,
                                ),
                                child: Center(
                                  child: isDone
                                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                                      : Text(
                                    '${stepIndex + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? const Color(0xFF43A047)
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                width: 52,
                                child: Text(
                                  stepLabels[stepIndex],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isDone || isActive
                                        ? const Color(0xFF2E7D32)
                                        : Colors.grey,
                                    fontWeight: isDone || isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Job Info'),
                      _infoRow(Icons.calendar_month,  'Booking Date',   bookingDate),
                      _infoRow(Icons.location_on,     'Address',        address),
                      _infoRow(Icons.home_work,       'Property Size',  size),
                      _infoRow(Icons.email_outlined,  'Customer Email', email),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Timeline'),
                      _timelineRow('Booking Created', createdAt, Colors.green.shade300),
                      _timelineRow('Last Updated',    updatedAt, const Color(0xFF43A047)),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isFinal
                        ? null
                        : () async {
                      final doc = await FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(bookingId)
                          .get();

                      final docData = doc.data();

                      if (docData?['cleanerId'] != user?.uid) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Not your job'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      String nextStatus = '';
                      switch (status) {
                        case 'Assigned':
                          nextStatus = 'On The Way';
                          break;
                        case 'On The Way':
                          nextStatus = 'Arrived';
                          break;
                        case 'Arrived':
                          nextStatus = 'In Progress';
                          break;
                        case 'In Progress':
                          nextStatus = 'Completed';
                          break;
                      }

                      if (nextStatus.isEmpty) return;

                      await FirebaseFirestore.instance
                          .collection('bookings')
                          .doc(bookingId)
                          .update({
                        'status': nextStatus,
                        'updated_at': Timestamp.now(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Status updated to $nextStatus'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      if (nextStatus == 'Completed') {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFinal ? Colors.grey : btnColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: Icon(btnIcon, color: Colors.white),
                    label: Text(
                      nextStatusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E7D32),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2E7D32), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineRow(String label, String value, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour   = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}