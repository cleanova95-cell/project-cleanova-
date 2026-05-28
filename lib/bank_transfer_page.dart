import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cleanova/pending_payment_page.dart';

class BankTransferPage extends StatefulWidget {
  final String service;
  final String size;
  final String address;
  final DateTime bookingDate;
  final int totalPrice;

  const BankTransferPage({
    super.key,
    required this.service,
    required this.size,
    required this.address,
    required this.bookingDate,
    required this.totalPrice,
  });

  @override
  State<BankTransferPage> createState() => _BankTransferPageState();
}

class _BankTransferPageState extends State<BankTransferPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _bankDetails;
  bool _loadingBank = true;
  File? _receiptImage;
  Uint8List? _imageBytes;
  bool _uploading = false;
  bool _copied = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _fetchBankDetails();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchBankDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bank_details')
          .doc('main')
          .get();

      if (doc.exists) {
        setState(() {
          _bankDetails = doc.data();
          _loadingBank = false;
        });
        _animController.forward();
      } else {
        setState(() => _loadingBank = false);
        _showSnack('Bank details not found.', isError: true);
      }
    } catch (e) {
      setState(() => _loadingBank = false);
      _showSnack('Failed to load bank details.', isError: true);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _receiptImage = null;
      });
    } else {
      setState(() {
        _receiptImage = File(picked.path);
        _imageBytes = null;
      });
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Receipt',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how to attach your proof of payment',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      color: const Color(0xFF43A047),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SourceOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: const Color(0xFF2E7D32),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _uploadToStorage(File image) async {
    final user = FirebaseAuth.instance.currentUser;
    final fileName =
        'receipts/${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }

  Future<String?> _uploadBytesToStorage(Uint8List bytes) async {
    final user = FirebaseAuth.instance.currentUser;
    final fileName =
        'receipts/${user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance.ref().child(fileName);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  Future<String> _saveBooking(String? imageUrl) async {
    final user = FirebaseAuth.instance.currentUser;
    final docRef =
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
    return docRef.id;
  }

  Future<void> _submitReceipt() async {
    if (_receiptImage == null && _imageBytes == null) {
      _showSnack('Please upload your payment receipt first.', isError: true);
      return;
    }

    setState(() => _uploading = true);

    try {
      String? imageUrl;

      if (kIsWeb && _imageBytes != null) {
        imageUrl = await _uploadBytesToStorage(_imageBytes!);
      } else if (_receiptImage != null) {
        imageUrl = await _uploadToStorage(_receiptImage!);
      }

      final bookingId = await _saveBooking(imageUrl);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PendingPaymentPage(
            bookingId: bookingId,
            service: widget.service,
            size: widget.size,
            address: widget.address,
            bookingDate: widget.bookingDate,
            totalPrice: widget.totalPrice,
          ),
        ),
      );
    } catch (e) {
      _showSnack('Upload failed. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _copyAccountNumber() async {
    final number = _bankDetails?['account_number'] ?? '';
    await Clipboard.setData(ClipboardData(text: number));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
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

  @override
  Widget build(BuildContext context) {
    final bool hasImage = _receiptImage != null || _imageBytes != null;

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
          'Bank Transfer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _loadingBank
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF43A047)),
      )
          : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 24, horizontal: 20),
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
                      'Amount to Transfer',
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3)),
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

              const _StepHeader(
                  number: '1', title: 'Transfer to this account'),

              const SizedBox(height: 14),

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
                  children: [
                    _BankDetailRow(
                      icon: Icons.account_balance_rounded,
                      label: 'Bank',
                      value: _bankDetails?['bank_name'] ?? '-',
                    ),
                    const Divider(height: 24, color: Color(0xFFE8F5E9)),
                    _BankDetailRow(
                      icon: Icons.person_rounded,
                      label: 'Account Name',
                      value: _bankDetails?['account_name'] ?? '-',
                    ),
                    const Divider(height: 24, color: Color(0xFFE8F5E9)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.tag_rounded,
                            color: Color(0xFF43A047),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Account Number',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _bankDetails?['account_number'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B5E20),
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _copyAccountNumber,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _copied
                                  ? const Color(0xFF43A047)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _copied
                                      ? Icons.check_rounded
                                      : Icons.copy_rounded,
                                  size: 14,
                                  color: _copied
                                      ? Colors.white
                                      : const Color(0xFF43A047),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _copied ? 'Copied!' : 'Copy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _copied
                                        ? Colors.white
                                        : const Color(0xFF43A047),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFE082)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: Color(0xFFF9A825), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Please transfer the exact amount: RM ${widget.totalPrice}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5D4037),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const _StepHeader(
                  number: '2', title: 'Upload payment receipt'),

              const SizedBox(height: 14),

              hasImage
                  ? _ReceiptPreview(
                image: _receiptImage,
                imageBytes: _imageBytes,
                onRemove: () => setState(() {
                  _receiptImage = null;
                  _imageBytes = null;
                }),
                onReplace: _showImageSourceSheet,
              )
                  : GestureDetector(
                onTap: _showImageSourceSheet,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFA5D6A7),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.green.shade100.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.upload_file_rounded,
                          color: Color(0xFF43A047),
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tap to upload receipt',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Camera or Gallery',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  onPressed: _uploading ? null : _submitReceipt,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 4,
                    shadowColor:
                    const Color(0xFF43A047).withOpacity(0.4),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: _uploading
                          ? null
                          : const LinearGradient(
                        colors: [
                          Color(0xFF2E7D32),
                          Color(0xFF43A047),
                          Color(0xFF66BB6A),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      child: _uploading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Submit Receipt',
                            style: TextStyle(
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

              const SizedBox(height: 16),

              Center(
                child: Text(
                  '⏳ Your booking will be confirmed after admin verifies your receipt',
                  textAlign: TextAlign.center,
                  style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String number;
  final String title;

  const _StepHeader({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1B5E20),
          ),
        ),
      ],
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _BankDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF43A047), size: 18),
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
                style: const TextStyle(
                  fontSize: 15,
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

class _ReceiptPreview extends StatelessWidget {
  final File? image;
  final Uint8List? imageBytes;
  final VoidCallback onRemove;
  final VoidCallback onReplace;

  const _ReceiptPreview({
    this.image,
    this.imageBytes,
    required this.onRemove,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF43A047), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF43A047).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(18)),
            child: kIsWeb && imageBytes != null
                ? Image.memory(
              imageBytes!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            )
                : Image.file(
              image!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF43A047), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Receipt uploaded',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onReplace,
                  child: const Text(
                    'Replace',
                    style: TextStyle(
                      color: Color(0xFF43A047),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRemove,
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
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

class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}