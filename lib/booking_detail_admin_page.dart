import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDetailAdminPage extends StatelessWidget {
  final String bookingId;

  const BookingDetailAdminPage({
    super.key,
    required this.bookingId,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return const Color(0xFF43A047);
      case 'Assigned':
        return const Color(0xFF1565C0);
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
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}  ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '-';
    final d = ts.toDate();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF43A047), Color(0xFF66BB6A)],
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
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .get(),
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

          final service      = data['service']         ?? '-';
          final size         = data['size']            ?? '-';
          final address      = data['address']         ?? '-';
          final status       = data['status']          ?? 'Pending';
          final email        = data['email']           ?? '-';
          final userId       = data['userId']          ?? '-';
          final cleanerName  = data['cleanerName']     ?? 'Not Assigned';
          final cleanerEmail = data['cleanerEmail']    ?? 'Not Assigned';
          final payMethod    = data['paymentMethod']   ?? '-';
          final price        = data['price']           ?? 0;
          final payStatus    = data['paymentStatus']   ?? '-';
          final payIntentId  = data['paymentIntentId'] ?? '-';

          final bookingDate = _formatDate(data['bookingDate'] as Timestamp?);
          final paidAt      = _formatTimestamp(data['paidAt'] as Timestamp?);
          final createdAt   = _formatTimestamp(data['created_at'] as Timestamp?);

          final bool cleanerAssigned = data['cleanerName'] != null;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                // ── Header Banner ──────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047), Color(0xFF66BB6A)],
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
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bookingId,
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
                                color: Colors.white70,
                                fontSize: 11,
                              ),
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

                // ── Booking Info ───────────────────────────
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

                // ── Customer Info ──────────────────────────
                _InfoCard(
                  icon: Icons.person_outline_rounded,
                  title: 'Customer info',
                  rows: [
                    _InfoRow('Email', email),
                    _InfoRow('User ID', userId, isLast: true),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Cleaner Info ───────────────────────────
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
                      valueColor: cleanerAssigned
                          ? null
                          : Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Payment Info ───────────────────────────
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
          );
        },
      ),
    );
  }
}

// ── Info Card ────────────────────────────────────────────────────
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
                  child: Icon(icon, color: const Color(0xFF2E7D32), size: 16),
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

// ── Info Row ─────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  final bool isSmall;
  final bool isBadge;
  final Color? valueColor;

  const _InfoRow(
      this.label,
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