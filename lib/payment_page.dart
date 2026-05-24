import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cleanova/receipt_page.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  static const String _stripeSecretKey =
      'sk_test_51TYse0ILpdbUz8ZmOY72lJXr0qXuNOcddKEHvq6JbKt2ctfy9ufxQ2J93r9zrDKjCc4GWmkZy3DDcT4t7ODR2FNR00sfiYl4RA';

  String selectedMethod = 'card';
  bool isProcessing = false;
  File? _receiptImage;
  bool _uploadingReceipt = false;
  // ── Create Payment Intent (Card) ─────────────────────────────
  Future<String?> _createPaymentIntent() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (widget.totalPrice * 100).toString(),
          'currency': 'myr',
          'payment_method_types[]': 'card',
          'description': '${widget.service} - ${widget.size}',
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

  // ── Create Payment Intent (GrabPay) ──────────────────────────
  Future<Map<String, String>?> _createGrabPayIntent() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (widget.totalPrice * 100).toString(),
          'currency': 'myr',
          'payment_method_types[]': 'grabpay',
          'description': '${widget.service} - ${widget.size}',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'client_secret': data['client_secret'] as String,
          'id': data['id'] as String,
        };
      }
      debugPrint('GrabPay intent error: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('GrabPay intent error: $e');
      return null;
    }
  }

  // ── Save to Firestore ────────────────────────────────────────
  Future<void> _saveToFirestore({
    required String paymentIntentId,
    required String paymentMethod,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('bookings').add({
      'userId': user?.uid,
      'email': user?.email,
      'service': widget.service,
      'size': widget.size,
      'address': widget.address,
      'bookingDate': Timestamp.fromDate(widget.bookingDate),
      'price': widget.totalPrice,
      'status': 'Confirmed',
      'paymentStatus': 'Paid',
      'paymentMethod': paymentMethod,
      'paymentIntentId': paymentIntentId,
      'paidAt': Timestamp.now(),
      'created_at': Timestamp.now(),
      'updated_at': Timestamp.now(),
    });
  }

  // ── Verify Payment Intent ───────────────────────────────────
  Future<bool> _verifyPaymentIntent(String paymentIntentId) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.stripe.com/v1/payment_intents/$paymentIntentId'),
        headers: {'Authorization': 'Bearer $_stripeSecretKey'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'succeeded';
      }
      return false;
    } catch (e) {
      debugPrint('Verify error: $e');
      return false;
    }
  }

  // ── Pay with Card ────────────────────────────────────────────
  Future<void> _payWithCard() async {
    setState(() => isProcessing = true);
    try {
      final clientSecret = await _createPaymentIntent();
      if (clientSecret == null) throw Exception('Failed to create payment intent');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'CleaNova',
          style: ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: const Color(0xFF43A047),
            ),
            shapes: PaymentSheetShape(
              borderRadius: 16,
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // ── Verify payment actually succeeded before saving ──
      final paymentIntentId = clientSecret.split('_secret_')[0];
      final isSucceeded = await _verifyPaymentIntent(paymentIntentId);

      if (!isSucceeded) {
        if (!mounted) return;
        _showError('Payment was not completed. Please try again.');
        setState(() => isProcessing = false);
        return;
      }

      await _saveToFirestore(
        paymentIntentId: paymentIntentId,
        paymentMethod: 'Credit / Debit Card',
      );

      if (!mounted) return;
      _goToReceipt('Credit / Debit Card');
    } on StripeException catch (e) {
      setState(() => isProcessing = false);
      if (e.error.code == FailureCode.Canceled) return;
      if (!mounted) return;
      _showError('Payment failed: ${e.error.localizedMessage}');
    } catch (e) {
      setState(() => isProcessing = false);
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
    }
    if (mounted) setState(() => isProcessing = false);
  }


  // ── Pay with GrabPay ─────────────────────────────────────────
  Future<void> _payWithGrabPay() async {
    setState(() => isProcessing = true);
    try {
      final intentData = await _createGrabPayIntent();
      if (intentData == null) throw Exception('Failed to create GrabPay intent');

      final clientSecret = intentData['client_secret']!;
      final intentId = intentData['id']!;

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'CleaNova',
          style: ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: const Color(0xFF00B14F),
            ),
            shapes: PaymentSheetShape(
              borderRadius: 16,
            ),
          ),
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await _saveToFirestore(
        paymentIntentId: intentId,
        paymentMethod: 'GrabPay',
      );

      if (!mounted) return;
      _goToReceipt('GrabPay');
    } on StripeException catch (e) {
      setState(() => isProcessing = false);
      if (e.error.code == FailureCode.Canceled) return;
      if (!mounted) return;
      _showError('GrabPay failed: ${e.error.localizedMessage}');
    } catch (e) {
      setState(() => isProcessing = false);
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
    }
    if (mounted) setState(() => isProcessing = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _goToReceipt(String paymentMethod) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptPage(
          service: widget.service,
          size: widget.size,
          address: widget.address,
          bookingDate: widget.bookingDate,
          totalPrice: widget.totalPrice,
          paymentMethod: paymentMethod,
        ),
      ),
    );
  }

  Future<void> _pickReceiptImage() async {
    final picker = ImagePicker();

    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery, // or ImageSource.camera
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() {
      _receiptImage = File(pickedFile.path);
    });

    _uploadReceipt();
  }
  Future<String?> _uploadReceiptToStorage(File image) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      final fileName =
          'receipts/${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final ref = FirebaseStorage.instance.ref().child(fileName);

      await ref.putFile(image);

      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }
  Future<void> _saveReceiptPayment(String? imageUrl) async {
    final user = FirebaseAuth.instance.currentUser;

    await FirebaseFirestore.instance.collection('bookings').add({
      'userId': user?.uid,
      'email': user?.email,
      'service': widget.service,
      'size': widget.size,
      'address': widget.address,
      'bookingDate': Timestamp.fromDate(widget.bookingDate),
      'price': widget.totalPrice,

      'paymentMethod': 'Bank Transfer',
      'paymentStatus': 'Pending Verification',

      'receiptImage': imageUrl,

      'status': 'Pending',
      'created_at': Timestamp.now(),
      'updated_at': Timestamp.now(),
    });
  }
  Future<void> _uploadReceipt() async {
    if (_receiptImage == null) return;

    setState(() => _uploadingReceipt = true);

    try {
      // final url = await _uploadReceiptToStorage(_receiptImage!); //
      //
      // // if (url == null) {
      // //   _showError('Upload failed');
      // //   return;
      // // }
      final url = null;
      await _saveReceiptPayment(url);

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
            paymentMethod: 'Bank Transfer (Receipt Uploaded)',
          ),
        ),
      );
    } catch (e) {
      _showError('Receipt upload failed');
    } finally {
      if (mounted) setState(() => _uploadingReceipt = false);
    }
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
          'Payment',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Amount Banner ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D32), Color(0xFF43A047), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF43A047).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RM ${widget.totalPrice}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${widget.service} · ${widget.size}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Payment Method Label ─────────────────────────
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),

            const SizedBox(height: 14),

            // ── Card Option ──────────────────────────────────
            _PaymentMethodTile(
              value: 'card',
              groupValue: selectedMethod,
              onChanged: (val) => setState(() => selectedMethod = val!),
              icon: Icons.credit_card_rounded,
              iconColor: const Color(0xFF1565C0),
              iconBg: const Color(0xFFE3F2FD),
              title: 'Credit / Debit Card',
              subtitle: 'Visa, Mastercard, American Express',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CardBadge('VISA', const Color(0xFF1A1F71)),
                  const SizedBox(width: 4),
                  _CardBadge('MC', const Color(0xFFEB001B)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── GrabPay Option ───────────────────────────────
            _PaymentMethodTile(
              value: 'grabpay',
              groupValue: selectedMethod,
              onChanged: (val) => setState(() => selectedMethod = val!),
              icon: Icons.account_balance_wallet_rounded,
              iconColor: const Color(0xFF00B14F),
              iconBg: const Color(0xFFE8F5E9),
              title: 'GrabPay',
              subtitle: 'Pay with your Grab wallet',
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B14F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Grab',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Upload Receipt Button (UI only) ──────────────
            GestureDetector(
              onTap: _pickReceiptImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFA5D6A7),
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade100.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.upload_file_rounded,
                        color: Color(0xFF43A047),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Payment Receipt',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Optional — attach proof of payment',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF43A047),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Secure Badge ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    color: Color(0xFF43A047), size: 14),
                const SizedBox(width: 6),
                Text(
                  'Secured by Stripe · 256-bit SSL Encryption',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Pay Button ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () {
                  if (selectedMethod == 'card') {
                    _payWithCard();
                  } else {
                    _payWithGrabPay();
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0xFF43A047).withOpacity(0.4),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: isProcessing
                        ? null
                        : const LinearGradient(
                      colors: [
                        Color(0xFF2E7D32),
                        Color(0xFF43A047),
                        Color(0xFF66BB6A)
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Container(
                    alignment: Alignment.center,
                    child: isProcessing
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          selectedMethod == 'card'
                              ? Icons.credit_card_rounded
                              : Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Pay RM ${widget.totalPrice}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ── Payment Method Tile ──────────────────────────────────────────
class _PaymentMethodTile extends StatelessWidget {
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _PaymentMethodTile({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = value == groupValue;

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF43A047) : const Color(0xFFD4E8D4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF43A047).withOpacity(0.15)
                  : Colors.grey.shade100,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Radio
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF43A047) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF43A047),
                  ),
                ),
              )
                  : null,
            ),
            const SizedBox(width: 12),
            // Icon
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? const Color(0xFF1B5E20)
                          : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}



// ── Card Badge ───────────────────────────────────────────────────
class _CardBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _CardBadge(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}