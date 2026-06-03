import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDetailAdminPage extends StatefulWidget {
  final String bookingId;

  const BookingDetailAdminPage({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailAdminPage> createState() =>
      _BookingDetailAdminPageState();
}

class _BookingDetailAdminPageState extends State<BookingDetailAdminPage> {
  bool _isProcessing = false;

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return const Color(0xFF43A047);
      case 'Assigned':
        return const Color(0xFF1565C0);
      case 'Pending Verification':
        return Colors.amber.shade700;
      case 'Completed':
        return const Color(0xFF2E7D32);
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}  '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _verifyJob(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Verify Cleaning'),
        content: const Text(
            'Confirm that the proof photo is satisfactory and mark this job as Completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verify',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'status': 'Completed',
        'verifiedAt': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Job verified and marked as Completed!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _rejectProof(BuildContext context) async {
    final TextEditingController _reasonCtrl = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Proof'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Proof photo does not meet standards. The cleaner will be asked to re-submit.'),
            const SizedBox(height: 14),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF43A047)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'status': 'In Progress',
        'proofImageUrl': FieldValue.delete(),
        'proofUploadedAt': FieldValue.delete(),
        'proofRejectedAt': Timestamp.now(),
        'proofRejectionReason': _reasonCtrl.text.trim().isEmpty
            ? 'Proof did not meet standards.'
            : _reasonCtrl.text.trim(),
        'updated_at': Timestamp.now(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '❌ Proof rejected. Cleaner will need to re-submit.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _openPhotoViewer(BuildContext context, String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Proof Photo',
                style: TextStyle(color: Colors.white)),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF2E7D32),
                Color(0xFF43A047),
                Color(0xFF66BB6A)
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
            fontSize: 20,
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
              child: CircularProgressIndicator(color: Color(0xFF43A047)),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Booking not found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final service = data['service'] ?? '-';
          final size = data['size'] ?? '-';
          final address = data['address'] ?? '-';
          final status = data['status'] ?? 'Pending';
          final email = data['email'] ?? '-';
          final userId = data['userId'] ?? '-';
          final cleanerName = data['cleanerName'] ?? 'Not Assigned';
          final cleanerEmail = data['cleanerEmail'] ?? 'Not Assigned';
          final payMethod = data['paymentMethod'] ?? '-';
          final price = data['price'] ?? 0;
          final payStatus = data['paymentStatus'] ?? '-';

          // ── REPAIR: Bank Transfer payIntentId & paidAt ──
          final payIntentId = data['paymentIntentId'] ??
              (payMethod == 'Bank Transfer'
                  ? 'BT-${(data['created_at'] as Timestamp?)?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}'
                  : '-');

          final paidAt = data['paidAt'] != null
              ? _formatTimestamp(data['paidAt'] as Timestamp?)
              : (payMethod == 'Bank Transfer'
              ? _formatTimestamp(data['created_at'] as Timestamp?)
              : '-');
          // ────────────────────────────────────────────────

          final String? proofImageUrl = data['proofImageUrl'] as String?;
          final String? proofRejectionReason =
          data['proofRejectionReason'] as String?;
          final bool isPendingVerification = status == 'Pending Verification';
          final bool isCompleted = status == 'Completed';

          final bookingDate =
          _formatDate(data['bookingDate'] as Timestamp?);
          final createdAt =
          _formatTimestamp(data['created_at'] as Timestamp?);
          final verifiedAt =
          _formatTimestamp(data['verifiedAt'] as Timestamp?);

          final bool cleanerAssigned = data['cleanerName'] != null;

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF2E7D32),
                            Color(0xFF43A047),
                            Color(0xFF66BB6A)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Booking ID',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.bookingId,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Created: $createdAt',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.4)),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (proofImageUrl != null) ...[
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color:
                              Colors.amber.shade100.withOpacity(0.8),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: isPendingVerification
                              ? Border.all(
                              color: Colors.amber.shade400, width: 1.5)
                              : null,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: isPendingVerification
                                          ? Colors.amber.shade50
                                          : const Color(0xFFE8F5E9),
                                      borderRadius:
                                      BorderRadius.circular(9),
                                    ),
                                    child: Icon(
                                      Icons.photo_camera_outlined,
                                      color: isPendingVerification
                                          ? Colors.amber.shade800
                                          : const Color(0xFF2E7D32),
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Proof of Cleaning',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isPendingVerification)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Awaiting Review',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  if (isCompleted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius:
                                        BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Verified ✓',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1B5E20),
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              GestureDetector(
                                onTap: () =>
                                    _openPhotoViewer(context, proofImageUrl),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      child: Image.network(
                                        proofImageUrl,
                                        width: double.infinity,
                                        height: 220,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child,
                                            loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            height: 220,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                              BorderRadius.circular(12),
                                            ),
                                            child: const Center(
                                              child:
                                              CircularProgressIndicator(
                                                  color: Colors.green),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius:
                                          BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.zoom_in,
                                                color: Colors.white,
                                                size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              'Tap to expand',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              if (isCompleted && verifiedAt != '-') ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.verified,
                                        color: Colors.green.shade600,
                                        size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Verified on $verifiedAt',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green.shade700),
                                    ),
                                  ],
                                ),
                              ],

                              if (isPendingVerification) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _isProcessing
                                            ? null
                                            : () =>
                                            _rejectProof(context),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                              color: Colors.red, width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(14),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                        ),
                                        icon: const Icon(Icons.close,
                                            color: Colors.red, size: 18),
                                        label: const Text(
                                          'Reject',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isProcessing
                                            ? null
                                            : () => _verifyJob(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                          const Color(0xFF2E7D32),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(14),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 14),
                                        ),
                                        icon: _isProcessing
                                            ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child:
                                          CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                            : const Icon(Icons.verified,
                                            color: Colors.white,
                                            size: 18),
                                        label: const Text(
                                          'Verify',
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (proofImageUrl == null &&
                        (status == 'In Progress' ||
                            status == 'Arrived' ||
                            status == 'On The Way' ||
                            status == 'Assigned')) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color:
                              Colors.green.shade100.withOpacity(0.5),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.camera_alt_outlined,
                                  color: Colors.grey.shade400, size: 22),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Proof of Cleaning',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Not submitted yet. Cleaner is still working.',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _InfoCard(
                      icon: Icons.calendar_month_outlined,
                      title: 'Booking info',
                      rows: [
                        _InfoRow('Service', service),
                        _InfoRow('Size', size),
                        _InfoRow('Date', bookingDate),
                        _InfoRow('Address', address, isLast: true),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _InfoCard(
                      icon: Icons.person_outline_rounded,
                      title: 'Customer info',
                      rows: [
                        _InfoRow('Email', email),
                        _InfoRow('User ID', userId, isLast: true),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _InfoCard(
                      icon: Icons.cleaning_services_outlined,
                      title: 'Cleaner info',
                      rows: [
                        _InfoRow(
                          'Name',
                          cleanerName,
                          valueColor: cleanerAssigned
                              ? const Color(0xFF1B5E20)
                              : Colors.orange,
                        ),
                        _InfoRow(
                          'Email',
                          cleanerEmail,
                          isLast: true,
                          valueColor:
                          cleanerAssigned ? null : Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _InfoCard(
                      icon: Icons.credit_card_outlined,
                      title: 'Payment info',
                      rows: [
                        _InfoRow('Method', payMethod),
                        _InfoRow('Amount', 'RM $price',
                            valueColor: const Color(0xFF2E7D32)),
                        _InfoRow('Status', payStatus,
                            valueColor: payStatus == 'Paid'
                                ? const Color(0xFF2E7D32)
                                : Colors.orange,
                            isBadge: true),
                        _InfoRow('Paid at', paidAt),
                        _InfoRow('Payment ID', payIntentId,
                            isLast: true, isSmall: true),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              if (_isProcessing)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF43A047)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<_InfoRow> rows;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade100.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child:
                  Icon(icon, color: const Color(0xFF2E7D32), size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  final bool isSmall;
  final bool isBadge;
  final Color? valueColor;

  const _InfoRow(this.label,
      this.value, {
        this.isLast = false,
        this.isSmall = false,
        this.isBadge = false,
        this.valueColor,
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              Expanded(
                child: isBadge
                    ? Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: valueColor?.withOpacity(0.1) ??
                          const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: valueColor ?? const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                )
                    : Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? const Color(0xFF1B5E20),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            color: Colors.green.shade50,
            thickness: 1,
            height: 1,
          ),
      ],
    );
  }
}