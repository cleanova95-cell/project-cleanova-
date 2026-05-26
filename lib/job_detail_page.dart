import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class JobDetailPage extends StatefulWidget {
  final String bookingId;

  const JobDetailPage({super.key, required this.bookingId});

  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends State<JobDetailPage> {
  bool _isUploading = false;

  // ── Pick image source via bottom sheet ────────────────────────
  Future<XFile?> _pickProofImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    ImageSource? source;

    await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Upload Proof of Cleaning',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Take or choose a photo showing the cleaned area.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: Color(0xFF2E7D32)),
                ),
                title: const Text('Take a Photo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: Colors.blue),
                ),
                title: const Text('Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ).then((val) => source = val);

    if (source == null) return null;
    return await picker.pickImage(
      source: source!,
      imageQuality: 80,
      maxWidth: 1200,
    );
  }

  // ── Handle button press ───────────────────────────────────────
  Future<void> _handleAction(
      BuildContext context, String status, String nextStatus) async {
    final user = FirebaseAuth.instance.currentUser;

    // Verify ownership
    final doc = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .get();
    if (doc.data()?['cleanerId'] != user?.uid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not your job'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (status == 'In Progress') {
      // Require proof photo before completing
      final XFile? photo = await _pickProofImage(context);
      if (photo == null) return; // user cancelled picker

      if (!mounted) return;
      setState(() => _isUploading = true);

      try {
        final File file = File(photo.path);
        final String fileName =
            'proof/${widget.bookingId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final ref = FirebaseStorage.instance.ref().child(fileName);
        await ref.putFile(file);
        final String downloadUrl = await ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .update({
          'status': 'Pending Verification',
          'proofImageUrl': downloadUrl,
          'proofUploadedAt': Timestamp.now(),
          'updated_at': Timestamp.now(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Proof submitted! Waiting for admin to verify.'),
            backgroundColor: Color(0xFF2E7D32),
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
      return;
    }

    // Normal status advance (Assigned → On The Way → Arrived → In Progress)
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .update({
      'status': nextStatus,
      'updated_at': Timestamp.now(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status updated to $nextStatus'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            .doc(widget.bookingId)
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

          final service       = data['service']      ?? '-';
          final email         = data['email']        ?? '-';
          final address       = data['address']      ?? '-';
          final size          = data['size']         ?? '-';
          final status        = (data['status']      ?? 'Pending').toString();
          final proofImageUrl = data['proofImageUrl'] as String?;

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

          // ── Status flags ─────────────────────────────────────
          final bool isCancelled           = status == 'Cancelled';
          final bool isCompleted           = status == 'Completed';
          final bool isPendingVerification = status == 'Pending Verification';
          final bool isFinal = isCancelled || isCompleted || isPendingVerification;

          // ── Status chip colours ───────────────────────────────
          Color statusBgColor;
          Color statusTextColor;
          switch (status) {
            case 'On The Way':
              statusBgColor   = Colors.deepOrange.shade100;
              statusTextColor = Colors.deepOrange.shade800;
              break;
            case 'Arrived':
              statusBgColor   = Colors.purple.shade100;
              statusTextColor = Colors.purple.shade800;
              break;
            case 'In Progress':
              statusBgColor   = Colors.blue.shade100;
              statusTextColor = Colors.blue.shade800;
              break;
            case 'Pending Verification':
              statusBgColor   = Colors.amber.shade100;
              statusTextColor = Colors.amber.shade900;
              break;
            case 'Completed':
              statusBgColor   = Colors.indigo.shade100;
              statusTextColor = Colors.indigo;
              break;
            case 'Cancelled':
              statusBgColor   = Colors.red.shade200;
              statusTextColor = Colors.red;
              break;
            default:
              statusBgColor   = Colors.green.shade100;
              statusTextColor = Colors.green;
          }

          // ── Button config ─────────────────────────────────────
          String nextStatusLabel = '';
          String nextStatus      = '';
          Color  btnColor        = Colors.green;
          IconData btnIcon       = Icons.check_circle_outline;

          switch (status) {
            case 'Assigned':
              nextStatusLabel = "I'm On The Way";
              nextStatus      = 'On The Way';
              btnColor        = Colors.orange;
              btnIcon         = Icons.directions_car;
              break;
            case 'On The Way':
              nextStatusLabel = "I've Arrived";
              nextStatus      = 'Arrived';
              btnColor        = Colors.purple;
              btnIcon         = Icons.location_on;
              break;
            case 'Arrived':
              nextStatusLabel = 'Start Cleaning';
              nextStatus      = 'In Progress';
              btnColor        = Colors.blue;
              btnIcon         = Icons.cleaning_services;
              break;
            case 'In Progress':
              nextStatusLabel = 'Submit Proof & Complete';
              nextStatus      = 'Pending Verification';
              btnColor        = const Color(0xFF43A047);
              btnIcon         = Icons.camera_alt_outlined;
              break;
            case 'Pending Verification':
              nextStatusLabel = 'Awaiting Admin Verification';
              btnColor        = Colors.amber.shade700;
              btnIcon         = Icons.hourglass_top_rounded;
              break;
            case 'Completed':
              nextStatusLabel = 'Job Verified & Completed';
              btnColor        = Colors.grey;
              btnIcon         = Icons.verified_outlined;
              break;
            case 'Cancelled':
              nextStatusLabel = 'Job Cancelled';
              btnColor        = Colors.grey;
              btnIcon         = Icons.cancel_outlined;
              break;
          }

          // ── Progress stepper data ─────────────────────────────
          final List<String> stepLabels = [
            'Assigned', 'On The\nWay', 'Arrived', 'In\nProgress',
            'Pending\nVerif.', 'Completed',
          ];
          final List<String> stepKeys = [
            'Assigned', 'On The Way', 'Arrived', 'In Progress',
            'Pending Verification', 'Completed',
          ];
          final int currentStep = stepKeys.indexOf(status);

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [

                    // ── Header card ──────────────────────────────
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
                                  'ID: ${widget.bookingId}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
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

                    // ── Progress stepper ─────────────────────────
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Progress'),
                          Row(
                            children: List.generate(
                              stepLabels.length * 2 - 1,
                                  (i) {
                                if (i.isOdd) {
                                  final lineIndex = i ~/ 2;
                                  final isDone   = currentStep > lineIndex;
                                  return Expanded(
                                    child: Container(
                                      height: 2,
                                      color: isDone
                                          ? const Color(0xFF43A047)
                                          : Colors.grey.shade200,
                                    ),
                                  );
                                }
                                final stepIndex   = i ~/ 2;
                                final isDone      = currentStep > stepIndex ||
                                    (isCompleted &&
                                        stepIndex == stepLabels.length - 1);
                                final isActive    = currentStep == stepIndex;
                                final isPendStep  =
                                    stepKeys[stepIndex] == 'Pending Verification';

                                return Column(
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDone
                                            ? const Color(0xFF43A047)
                                            : isActive
                                            ? (isPendStep
                                            ? Colors.amber.shade200
                                            : Colors.white)
                                            : Colors.grey.shade100,
                                        border: isActive
                                            ? Border.all(
                                            color: isPendStep
                                                ? Colors.amber.shade700
                                                : const Color(0xFF43A047),
                                            width: 2)
                                            : null,
                                      ),
                                      child: Center(
                                        child: isDone
                                            ? const Icon(Icons.check,
                                            size: 13, color: Colors.white)
                                            : isActive && isPendStep
                                            ? Icon(Icons.hourglass_top,
                                            size: 13,
                                            color: Colors.amber.shade800)
                                            : Text(
                                          '${stepIndex + 1}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight:
                                            FontWeight.bold,
                                            color: isActive
                                                ? const Color(
                                                0xFF43A047)
                                                : Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        stepLabels[stepIndex],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 8,
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
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Proof image card ─────────────────────────
                    if (proofImageUrl != null) ...[
                      _card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('Proof of Cleaning'),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                proofImageUrl,
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 220,
                                    color: Colors.grey.shade100,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.green),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (isPendingVerification)
                              _infoBanner(
                                icon: Icons.info_outline,
                                color: Colors.amber,
                                text:
                                'Proof submitted. Admin will review and verify your work.',
                              ),
                            if (isCompleted)
                              _infoBanner(
                                icon: Icons.verified,
                                color: Colors.green,
                                text:
                                'Proof verified by admin. Job marked as completed!',
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Job info ─────────────────────────────────
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Job Info'),
                          _infoRow(
                              Icons.calendar_month, 'Booking Date', bookingDate),
                          _infoRow(Icons.location_on, 'Address', address),
                          _infoRow(Icons.home_work, 'Property Size', size),
                          _infoRow(
                              Icons.email_outlined, 'Customer Email', email),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Timeline ─────────────────────────────────
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Timeline'),
                          _timelineRow(
                              'Booking Created', createdAt, Colors.green.shade300),
                          _timelineRow(
                              'Last Updated', updatedAt, const Color(0xFF43A047)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Action button ────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isFinal || _isUploading
                            ? null
                            : () => _handleAction(context, status, nextStatus),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          isFinal ? Colors.grey.shade400 : btnColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: _isUploading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                            : Icon(btnIcon, color: Colors.white),
                        label: Text(
                          _isUploading ? 'Uploading…' : nextStatusLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // ── Upload overlay ───────────────────────────────
              if (_isUploading)
                Container(
                  color: Colors.black.withOpacity(0.35),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Uploading proof…',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  Widget _infoBanner(
      {required IconData icon,
        required MaterialColor color,
        required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        ],
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
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
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
                Text(label,
                    style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
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
            decoration:
            BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style:
                const TextStyle(fontSize: 14, color: Colors.grey)),
          ),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
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