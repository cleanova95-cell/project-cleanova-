import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class CleanerProfilePage extends StatefulWidget {
  const CleanerProfilePage({super.key});

  @override
  State<CleanerProfilePage> createState() => _CleanerProfilePageState();
}

class _CleanerProfilePageState extends State<CleanerProfilePage> {

  final _nameController  = TextEditingController();
  final _phoneController = TextEditingController();

  bool   _isLoading   = true;
  bool   _isSaving    = false;
  bool   _isEditMode  = false;
  String _email       = '';
  String _memberSince = '';
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text  = data['full_name'] ?? '';
        _phoneController.text = data['phone']     ?? '';
        _email                = data['email']     ?? '';
        _photoBase64          = data['photo_base64'];

        final createdAt = data['created_at'];
        if (createdAt is Timestamp) {
          final dt = createdAt.toDate();
          _memberSince = '${_monthName(dt.month)} ${dt.year}';
        }
      }
    } catch (e) {
      _showSnack('Failed to load profile', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final name  = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showSnack('Full name cannot be empty', isError: true);
      return;
    }

    if (phone.isNotEmpty &&
        !RegExp(r'^\+?[0-9]{8,15}$').hasMatch(phone)) {
      _showSnack('Enter a valid phone number', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final Map<String, dynamic> updates = {
        'full_name':  name,
        'phone':      phone,
        'updated_at': Timestamp.now(),
      };

      if (_photoBase64 != null) {
        updates['photo_base64'] = _photoBase64;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update(updates);

      _showSnack('Profile updated successfully');
      setState(() => _isEditMode = false);
    } catch (e) {
      _showSnack('Failed to save profile', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source:       ImageSource.gallery,
        maxWidth:     400,
        maxHeight:    400,
        imageQuality: 70,
      );

      if (picked == null) return;

      final bytes  = await picked.readAsBytes();
      final base64 = base64Encode(bytes);

      if (base64.length > 800000) {
        _showSnack(
          'Image too large for storage. Try a lower-resolution photo.',
          isError: true,
        );
        return;
      }

      setState(() => _photoBase64 = base64);
    } catch (e) {
      _showSnack('Could not load image', isError: true);
    }
  }

  Future<void> _sendPasswordReset() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _email);
      _showSnack('Password reset email sent to $_email');
    } catch (e) {
      _showSnack('Failed to send reset email', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
        isError ? Colors.red : const Color(0xFF43A047),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF43A047)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),

      appBar: AppBar(
        automaticallyImplyLeading: false,
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

        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              tooltip: 'Edit Profile',
              onPressed: () => setState(() => _isEditMode = true),
            )
          else
            TextButton(
              onPressed: () {
                setState(() => _isEditMode = false);
                _loadProfile(); // discard unsaved changes
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            _buildAvatarSection(),

            const SizedBox(height: 24),

            _buildInfoCard(),

            const SizedBox(height: 20),

            _buildAccountCard(),

            const SizedBox(height: 20),

            if (_isEditMode) _buildSaveButton(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: _photoBase64 != null
                    ? Image.memory(
                  base64Decode(_photoBase64!),
                  fit: BoxFit.cover,
                  width: 110,
                  height: 110,
                  errorBuilder: (context, error, stackTrace) =>
                      _defaultAvatar(),
                )
                    : _defaultAvatar(),
              ),
            ),

            if (_isEditMode)
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF43A047),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 14),

        Text(
          _nameController.text.isNotEmpty
              ? _nameController.text
              : 'Cleaner',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          _email,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),

        if (_memberSince.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Member since $_memberSince',
              style: const TextStyle(
                color: Color(0xFF43A047),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        if (_isEditMode) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickPhoto,
            child: const Text(
              'Tap camera icon to change photo',
              style: TextStyle(
                color: Color(0xFF43A047),
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _defaultAvatar() {
    return const Center(
      child: Icon(
        Icons.cleaning_services,
        color: Colors.white,
        size: 55,
      ),
    );
  }

  Widget _buildInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Personal Information', Icons.person_outline),
          const SizedBox(height: 16),

          _isEditMode
              ? _editableField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            inputType: TextInputType.name,
          )
              : _infoRow(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: _nameController.text.isNotEmpty
                ? _nameController.text
                : '—',
          ),

          const Divider(height: 24),

          _infoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _email.isNotEmpty ? _email : '—',
          ),

          const Divider(height: 24),

          _isEditMode
              ? _editableField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            inputType: TextInputType.phone,
          )
              : _infoRow(
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            value: _phoneController.text.isNotEmpty
                ? _phoneController.text
                : '—',
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Account Settings', Icons.settings_outlined),
          const SizedBox(height: 16),

          // Change password
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => _passwordResetDialog(),
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
                    Icons.lock_outline,
                    color: Color(0xFF43A047),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Password',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'A reset link will be sent to your email',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 14,
                ),
              ],
            ),
          ),

          const Divider(height: 24),

          // Account type
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cleaning_services_outlined,
                  color: Color(0xFF43A047),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Type',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Cleaner',
                      style: TextStyle(
                        color: Color(0xFF43A047),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
              : const Text(
            'Save Changes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordResetDialog() {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: Color(0xFF43A047)),
          SizedBox(width: 10),
          Text(
            'Change Password',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Text(
        'A password reset link will be sent to:\n\n$_email\n\nPlease check your inbox and follow the instructions.',
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _sendPasswordReset();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF43A047),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Send Link',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }


  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF43A047), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      ],
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF43A047), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _editableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF43A047)),
        filled: true,
        fillColor: const Color(0xFFF2F2F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF43A047),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}