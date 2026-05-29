import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:cleanova/receipt_page.dart';
import 'package:cleanova/customer_dashboard.dart';

class PendingPaymentPage extends StatefulWidget {
  final String bookingId;
  final String service;
  final String size;
  final String address;
  final DateTime bookingDate;
  final int totalPrice;

  const PendingPaymentPage({
    super.key,
    required this.bookingId,
    required this.service,
    required this.size,
    required this.address,
    required this.bookingDate,
    required this.totalPrice,
  });

  @override
  State<PendingPaymentPage> createState() => _PendingPaymentPageState();
}

class _PendingPaymentPageState extends State<PendingPaymentPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _dotController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _dotAnim;

  StreamSubscription<DocumentSnapshot>? _bookingListener;
  String _currentStatus = 'Pending';
  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dotAnim =
        CurvedAnimation(parent: _dotController, curve: Curves.linear);

    _listenToBooking();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _dotController.dispose();
    _bookingListener?.cancel();
    super.dispose();
  }

  void _listenToBooking() {
    _bookingListener = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists || _navigating) return;

      final status =
          snapshot.data()?['status'] as String? ?? 'Pending';

      if (!mounted) return;

      setState(() => _currentStatus = status);

      if (status == 'Confirmed') {
        _onConfirmed();
      } else if (status == 'Rejected') {
        _onRejected();
      }
    });
  }

  void _onConfirmed() {
    if (_navigating) return;
    _navigating = true;

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptPage(
            service: widget.service,
            size: widget.size,
            address: widget.address,
            bookingDate: widget.bookingDate,
            totalPrice: widget.totalPrice,
            paymentMethod: 'Bank Transfer',
          ),
        ),
      );
    });
  }

  void _onRejected() {
    if (_navigating) return;
    _navigating = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cancel_rounded,
                color: Colors.red.shade400,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Rejected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment receipt was not verified by admin. Please try again or contact support.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _navigating = false;
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Try Again',
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
    );
  }

  void _goToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CustomerDashboard()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isConfirmed = _currentStatus == 'Confirmed';
    final bool isRejected = _currentStatus == 'Rejected';
    final bool isPending = !isConfirmed && !isRejected;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        // ✅ Back arrow yang navigate ke CustomerDashboard
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: _goToHome,
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
          'Payment Status',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              isConfirmed
                  ? _ConfirmedIcon()
                  : isRejected
                  ? Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.cancel_rounded,
                  color: Colors.red.shade400,
                  size: 52,
                ),
              )
                  : ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFF8E1),
                        Color(0xFFFFF3CD)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF9A825)
                            .withOpacity(0.25),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: Color(0xFFF9A825),
                    size: 52,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                isConfirmed
                    ? 'Payment Confirmed! 🎉'
                    : isRejected
                    ? 'Payment Rejected'
                    : 'Waiting for Verification',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isRejected
                      ? Colors.red.shade600
                      : const Color(0xFF1B5E20),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                isConfirmed
                    ? 'Admin has verified your payment.\nYour booking is now confirmed!'
                    : isRejected
                    ? 'Your receipt was not verified by admin.\nPlease try again or contact support.'
                    : 'Admin is reviewing your payment receipt.\nPlease wait a moment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
              ),

              if (isPending) ...[
                const SizedBox(height: 20),
                _DotLoader(animation: _dotAnim),
              ],

              const SizedBox(height: 32),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFA5D6A7), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade100.withOpacity(0.5),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SummaryRow(
                      icon: Icons.cleaning_services_rounded,
                      label: 'Service',
                      value: widget.service,
                    ),
                    const Divider(height: 20, color: Color(0xFFE8F5E9)),
                    _SummaryRow(
                      icon: Icons.straighten_rounded,
                      label: 'Size',
                      value: widget.size,
                    ),
                    const Divider(height: 20, color: Color(0xFFE8F5E9)),
                    _SummaryRow(
                      icon: Icons.location_on_rounded,
                      label: 'Address',
                      value: widget.address,
                    ),
                    const Divider(height: 20, color: Color(0xFFE8F5E9)),
                    _SummaryRow(
                      icon: Icons.payments_rounded,
                      label: 'Total Amount',
                      value: 'RM ${widget.totalPrice}',
                      valueColor: const Color(0xFF2E7D32),
                      bold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? const Color(0xFFE8F5E9)
                      : isRejected
                      ? Colors.red.shade50
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isConfirmed
                        ? const Color(0xFF43A047)
                        : isRejected
                        ? Colors.red.shade200
                        : const Color(0xFFFFE082),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConfirmed
                          ? Icons.check_circle_rounded
                          : isRejected
                          ? Icons.cancel_rounded
                          : Icons.info_outline_rounded,
                      color: isConfirmed
                          ? const Color(0xFF43A047)
                          : isRejected
                          ? Colors.red.shade400
                          : const Color(0xFFF9A825),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConfirmed
                          ? 'Status: Confirmed ✅'
                          : isRejected
                          ? 'Status: Rejected ❌'
                          : 'Status: Pending Verification ⏳',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isConfirmed
                            ? const Color(0xFF2E7D32)
                            : isRejected
                            ? Colors.red.shade600
                            : const Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Hanya tunjuk info strip, BUANG button Back to Home bawah
              if (isPending)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFF43A047),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'This page will update automatically once admin verifies your payment. You can go back and check status in Booking History.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (isRejected) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      _navigating = false;
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF43A047),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Try Again',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
      ),
    );
  }
}

class _ConfirmedIcon extends StatefulWidget {
  @override
  State<_ConfirmedIcon> createState() => _ConfirmedIconState();
}

class _ConfirmedIconState extends State<_ConfirmedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _scaleAnim =
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF43A047).withOpacity(0.35),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(Icons.check_rounded,
            color: Colors.white, size: 56),
      ),
    );
  }
}

class _DotLoader extends StatelessWidget {
  final Animation<double> animation;

  const _DotLoader({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final delay = i / 3;
            final value =
            ((animation.value - delay) % 1.0).clamp(0.0, 1.0);
            final opacity =
            (value < 0.5 ? value * 2 : (1 - value) * 2).clamp(0.2, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF43A047),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
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
          child: Icon(icon, color: const Color(0xFF43A047), size: 16),
        ),
        const SizedBox(width: 12),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  bold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? const Color(0xFF1B5E20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}