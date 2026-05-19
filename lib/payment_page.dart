import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentPage extends StatefulWidget {
  final String service;
  final String size;
  final String address;
  final DateTime bookingDate;
  final int totalPrice;

  const PaymentPage({
    super.key,
    required this.service,
    required this.size,
    required this.address,
    required this.bookingDate,
    required this.totalPrice,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const String _stripeSecretKey = 'sk_test_51TYse0ILpdbUz8ZmOY72lJXr0qXuNOcddKEHvq6JbKt2ctfy9ufxQ2J93r9zrDKjCc4GWmkZy3DDcT4t7ODR2FNR00sfiYl4RA';

  String  selectedMethod = 'card';
  String? selectedBank;
  bool    isProcessing   = false;

  final List<Map<String, String>> fpxBanks = [
    {'id': 'maybank2u',        'name': 'Maybank2u'},
    {'id': 'cimb',             'name': 'CIMB Clicks'},
    {'id': 'public_bank',      'name': 'Public Bank'},
    {'id': 'rhb',              'name': 'RHB Now'},
    {'id': 'hong_leong_bank',  'name': 'Hong Leong'},
    {'id': 'ambank',           'name': 'AmBank'},
    {'id': 'bank_islam',       'name': 'Bank Islam'},
    {'id': 'bsn',              'name': 'BSN'},
  ];

  @override
  void initState() {
    super.initState();
  }


  Future<String?> _createPaymentIntent() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount':                 (widget.totalPrice * 100).toString(),
          'currency':               'myr',
          'payment_method_types[]': 'card',
          'description':            '${widget.service} - ${widget.size}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['client_secret'] as String?;
      }
      debugPrint('Stripe error: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('CreatePaymentIntent error: $e');
      return null;
    }
  }


  Future<void> _saveToFirestore({
    required String paymentIntentId,
    required String paymentMethod,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('bookings').add({
      'userId':          user?.uid,
      'email':           user?.email,
      'service':         widget.service,
      'size':            widget.size,
      'address':         widget.address,
      'bookingDate':     Timestamp.fromDate(widget.bookingDate),
      'price':           widget.totalPrice,
      'status':          'Confirmed',
      'paymentStatus':   'Paid',
      'paymentMethod':   paymentMethod,
      'paymentIntentId': paymentIntentId,
      'paidAt':          Timestamp.now(),
      'created_at':      Timestamp.now(),
      'updated_at':      Timestamp.now(),
    });
  }


  Future<void> _payWithCard() async {
    setState(() => isProcessing = true);

    try {

      if (kIsWeb) {
        await Future.delayed(const Duration(seconds: 2));
        await _saveToFirestore(
          paymentIntentId: 'web_test_${DateTime.now().millisecondsSinceEpoch}',
          paymentMethod:   'Credit/Debit Card',
        );
        if (!mounted) return;
        _goToReceipt('Credit/Debit Card');
        return;
      }


      final clientSecret = await _createPaymentIntent();
      if (clientSecret == null) throw Exception('Failed to create payment intent');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName:       'CleaningApp',
          style:                     ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: const Color(0xFF43A047),
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final paymentIntentId = clientSecret.split('_secret_')[0];

      await _saveToFirestore(
        paymentIntentId: paymentIntentId,
        paymentMethod:   'Credit/Debit Card',
      );

      if (!mounted) return;
      _goToReceipt('Credit/Debit Card');

    } on StripeException catch (e) {
      setState(() => isProcessing = false);
      if (e.error.code == FailureCode.Canceled) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text('Payment failed: ${e.error.localizedMessage}'),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      setState(() => isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text('Something went wrong: $e'),
        backgroundColor: Colors.red,
      ));
    }

    setState(() => isProcessing = false);
  }

  // ── Pay with FPX ──────────────────────────────────────────────
  Future<void> _payWithFPX() async {
    if (selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('Sila pilih bank anda'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() => isProcessing = true);

    try {
      // Test mode: simulate FPX payment berjaya
      await Future.delayed(const Duration(seconds: 2));

      await _saveToFirestore(
        paymentIntentId: 'fpx_test_${DateTime.now().millisecondsSinceEpoch}',
        paymentMethod:   'FPX - $selectedBank',
      );

      if (!mounted) return;
      _goToReceipt('FPX - $selectedBank');

    } catch (e) {
      setState(() => isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text('FPX error: $e'),
        backgroundColor: Colors.red,
      ));
    }

    setState(() => isProcessing = false);
  }

  void _goToReceipt(String paymentMethod) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptPage(
          service:       widget.service,
          size:          widget.size,
          address:       widget.address,
          bookingDate:   widget.bookingDate,
          totalPrice:    widget.totalPrice,
          paymentMethod: paymentMethod,
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Order Summary ────────────────────────────────
            const Text('Order Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
              ),
              child: Column(children: [
                _summaryRow(Icons.cleaning_services_outlined, 'Service', widget.service),
                const SizedBox(height: 10),
                _summaryRow(Icons.straighten_outlined, 'Size', widget.size),
                const SizedBox(height: 10),
                _summaryRow(Icons.calendar_month_outlined, 'Date',
                    '${widget.bookingDate.day}/${widget.bookingDate.month}/${widget.bookingDate.year}'),
                const SizedBox(height: 10),
                _summaryRow(Icons.location_on_outlined, 'Address', widget.address),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFE8F5E9)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    Text('RM ${widget.totalPrice}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF43A047))),
                  ],
                ),
              ]),
            ),

            const SizedBox(height: 28),

            // ── Payment Method ───────────────────────────────
            const Text('Payment Method',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            Row(children: [
              Expanded(child: _methodTab(
                label: 'Credit / Debit\nCard',
                icon: Icons.credit_card_outlined,
                isSelected: selectedMethod == 'card',
                onTap: () => setState(() => selectedMethod = 'card'),
              )),
              const SizedBox(width: 12),
              Expanded(child: _methodTab(
                label: 'FPX Online\nBanking',
                icon: Icons.account_balance_outlined,
                isSelected: selectedMethod == 'fpx',
                onTap: () => setState(() => selectedMethod = 'fpx'),
              )),
            ]),

            const SizedBox(height: 20),

            // ── Card Panel ───────────────────────────────────
            if (selectedMethod == 'card') ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
                ),
                child: Column(children: [
                  const Icon(Icons.credit_card, color: Color(0xFF43A047), size: 40),
                  const SizedBox(height: 12),
                  const Text('Card details collected securely',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    kIsWeb
                        ? 'Test mode — payment akan simulate terus.'
                        : 'Tekan Pay — Stripe akan tunjukkan\nform card yang selamat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFF176)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFFF9A825), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Test Mode — Guna card ni:',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF795548))),
                              const SizedBox(height: 4),
                              Text(
                                '4242 4242 4242 4242\nExpiry: 12/34  CVV: 123',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontFamily: 'monospace'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ],

            // ── FPX Panel ────────────────────────────────────
            if (selectedMethod == 'fpx') ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Your Bank',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: fpxBanks.length,
                      itemBuilder: (context, i) {
                        final bank       = fpxBanks[i];
                        final isSelected = selectedBank == bank['name'];
                        return GestureDetector(
                          onTap: () => setState(() => selectedBank = bank['name']),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE8F5E9) : const Color(0xFFF7FFF8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF43A047) : const Color(0xFFD4E8D4),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(children: [
                              Icon(Icons.account_balance_outlined,
                                  color: isSelected ? const Color(0xFF43A047) : Colors.grey, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(bank['name']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFDE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFF176)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.info_outline, color: Color(0xFFF9A825), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Test mode — FPX akan simulate payment berjaya terus.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Secure Badge ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, color: Color(0xFF43A047), size: 16),
                const SizedBox(width: 6),
                Text('Secured by Stripe · Your data is encrypted',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),

            const SizedBox(height: 20),

            // ── Pay Button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () => selectedMethod == 'card' ? _payWithCard() : _payWithFPX(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF43A047),
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: isProcessing
                    ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text('Pay RM ${widget.totalPrice}',
                    style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF43A047), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _methodTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF43A047) : const Color(0xFFD4E8D4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6)],
        ),
        child: Column(children: [
          Icon(icon, color: isSelected ? const Color(0xFF43A047) : Colors.grey, size: 26),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF2E7D32) : Colors.black54,
              )),
        ]),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────
//  Receipt Page
// ─────────────────────────────────────────────────────────────────

class ReceiptPage extends StatelessWidget {
  final String   service;
  final String   size;
  final String   address;
  final DateTime bookingDate;
  final int      totalPrice;
  final String   paymentMethod;

  const ReceiptPage({
    super.key,
    required this.service,
    required this.size,
    required this.address,
    required this.bookingDate,
    required this.totalPrice,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final receiptNo = 'RCP${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final now       = DateTime.now();

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
        title: const Text('Receipt',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, color: Color(0xFF43A047), size: 60),
          ),

          const SizedBox(height: 16),

          const Text('Payment Successful!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),

          const SizedBox(height: 4),

          Text('Booking anda telah disahkan.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),

          const SizedBox(height: 28),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Receipt',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(receiptNo,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF43A047))),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE8F5E9)),
                const SizedBox(height: 12),

                _receiptRow('Service',      service),
                _receiptRow('Size',         size),
                _receiptRow('Booking Date', '${bookingDate.day}/${bookingDate.month}/${bookingDate.year}'),
                _receiptRow('Address',      address),
                _receiptRow('Payment',      paymentMethod),
                _receiptRow('Date Paid',    '${now.day}/${now.month}/${now.year}  ${now.hour}:${now.minute.toString().padLeft(2,'0')}'),

                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE8F5E9)),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Paid',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    Text('RM $totalPrice',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF43A047))),
                  ],
                ),

                const SizedBox(height: 16),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Powered by Stripe',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Back to Home',
                  style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),

          const SizedBox(height: 30),
        ]),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}