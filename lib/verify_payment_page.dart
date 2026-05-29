import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyPaymentPage extends StatefulWidget {
  final String bookingId;
  final String serviceType;
  final String propertySize;
  final String bookingDate;
  final String address;
  final int price;
  final String? receiptImage;
  final String customerEmail;

  const VerifyPaymentPage({
    super.key,
    required this.bookingId,
    required this.serviceType,
    required this.propertySize,
    required this.bookingDate,
    required this.address,
    required this.price,
    this.receiptImage,
    required this.customerEmail,
  });

  @override
  State<VerifyPaymentPage> createState() => _VerifyPaymentPageState();
}

class _VerifyPaymentPageState extends State<VerifyPaymentPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _imageExpanded = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _acceptPayment() async {
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'status': 'Confirmed',
        'paymentStatus': 'Paid',
        'updated_at': Timestamp.now(),
      });
      if (!mounted) return;
      _showResult(accepted: true);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnack('Failed to update. Please try again.', isError: true);
    }
  }

  Future<void> _rejectPayment() async {
    setState(() => _isProcessing = true);
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
        'status': 'Rejected',
        'paymentStatus': 'Rejected',
        'updated_at': Timestamp.now(),
      });
      if (!mounted) return;
      _showResult(accepted: false);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnack('Failed to update. Please try again.', isError: true);
    }
  }

  void _showResult({required bool accepted}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accepted
                    ? const Color(0xFFE8F5E9)
                    : Colors.red.shade50,
              ),
              child: Icon(
                accepted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: accepted
                    ? const Color(0xFF2E7D32)
                    : Colors.red.shade400,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              accepted ? 'Payment Accepted!' : 'Payment Rejected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: accepted
                    ? const Color(0xFF1B5E20)
                    : Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              accepted
                  ? 'Booking has been confirmed. Customer will be notified.'
                  : 'Receipt has been rejected. Customer can resubmit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accepted
                      ? const Color(0xFF2E7D32)
                      : Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showFullImage() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  widget.receiptImage!,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasImage =
        widget.receiptImage != null && widget.receiptImage!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
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
          'Verify Payment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: const Text(
              'Bank Transfer',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Customer Info Banner ───────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFFA5D6A7), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade50,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.customerEmail,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFFE082)),
                        ),
                        child: const Text(
                          'Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Section: Receipt Image ────────────────────────────
                _SectionLabel(
                  icon: Icons.receipt_long_rounded,
                  label: 'Payment Receipt',
                  color: const Color(0xFF6A1B9A),
                ),

                const SizedBox(height: 12),

                hasImage
                    ? _ReceiptImageCard(
                  imageUrl: widget.receiptImage!,
                  onTapFullscreen: _showFullImage,
                )
                    : Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFD4E8D4), width: 1.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported_rounded,
                          color: Colors.grey.shade400, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        'No receipt image submitted',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Section: Booking Details ──────────────────────────
                _SectionLabel(
                  icon: Icons.assignment_rounded,
                  label: 'Booking Details',
                  color: const Color(0xFF2E7D32),
                ),

                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFA5D6A7), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade50,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.cleaning_services_rounded,
                        label: 'Service',
                        value: widget.serviceType,
                      ),
                      _divider(),
                      _DetailRow(
                        icon: Icons.straighten_rounded,
                        label: 'Size',
                        value: widget.propertySize,
                      ),
                      _divider(),
                      _DetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Booking Date',
                        value: widget.bookingDate,
                      ),
                      _divider(),
                      _DetailRow(
                        icon: Icons.location_on_rounded,
                        label: 'Address',
                        value: widget.address,
                      ),
                      _divider(),
                      _DetailRow(
                        icon: Icons.account_balance_rounded,
                        label: 'Payment',
                        value: 'Bank Transfer (FPX)',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Total Amount ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047),
                        Color(0xFF66BB6A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF43A047).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Customer paid via bank transfer',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'RM ${widget.price}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Verify Notice ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Color(0xFFF9A825), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Please check the receipt image carefully before accepting or rejecting. This action will notify the customer immediately.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.brown.shade600,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Action Buttons ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Reject',
                        icon: Icons.close_rounded,
                        isReject: true,
                        isProcessing: _isProcessing,
                        onTap: () => _showConfirmDialog(accepted: false),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _ActionButton(
                        label: 'Accept',
                        icon: Icons.check_rounded,
                        isReject: false,
                        isProcessing: _isProcessing,
                        onTap: () => _showConfirmDialog(accepted: true),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog({required bool accepted}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(
          accepted ? 'Accept Payment?' : 'Reject Payment?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: accepted
                ? const Color(0xFF1B5E20)
                : Colors.red.shade700,
          ),
        ),
        content: Text(
          accepted
              ? 'This will confirm the booking and notify the customer.'
              : 'This will reject the receipt and notify the customer to resubmit.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600,
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (accepted) {
                _acceptPayment();
              } else {
                _rejectPayment();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
              accepted ? const Color(0xFF2E7D32) : Colors.red.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
            child: Text(
              accepted ? 'Yes, Accept' : 'Yes, Reject',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Divider(color: Colors.green.shade50, thickness: 1),
  );
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ReceiptImageCard extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onTapFullscreen;

  const _ReceiptImageCard({
    required this.imageUrl,
    required this.onTapFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.3),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A1B9A).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 280,
                  color: const Color(0xFFF3E5F5),
                  child: const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF6A1B9A)),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: double.infinity,
                height: 280,
                color: const Color(0xFFF3E5F5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_rounded,
                        color: Colors.grey.shade400, size: 48),
                    const SizedBox(height: 10),
                    Text(
                      'Failed to load image',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.photo_rounded,
                    color: Color(0xFF6A1B9A), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Payment receipt submitted by customer',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onTapFullscreen,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fullscreen_rounded,
                            color: Color(0xFF6A1B9A), size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'View Full',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),
                      ],
                    ),
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF43A047), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isReject;
  final bool isProcessing;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isReject,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainColor =
    isReject ? Colors.red.shade600 : const Color(0xFF2E7D32);
    final Color bgColor =
    isReject ? Colors.red.shade50 : const Color(0xFFE8F5E9);
    final Color borderColor =
    isReject ? Colors.red.shade200 : const Color(0xFFA5D6A7);

    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: isReject ? bgColor : mainColor,
          borderRadius: BorderRadius.circular(18),
          border: isReject
              ? Border.all(color: borderColor, width: 1.5)
              : null,
          boxShadow: isReject
              ? null
              : [
            BoxShadow(
              color: mainColor.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isProcessing
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: isReject ? mainColor : Colors.white,
              ),
            )
                : Icon(
              icon,
              color: isReject ? mainColor : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isReject ? mainColor : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}