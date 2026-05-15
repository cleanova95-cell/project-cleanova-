import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class CleanerPage extends StatefulWidget {
  const CleanerPage({super.key});

  @override
  State<CleanerPage> createState() => _CleanerPageState();
}

class _CleanerPageState extends State<CleanerPage> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  bool isLoading = true;
  List<Map<String, dynamic>> cleaners = [];

  @override
  void initState() {
    super.initState();
    _fetchCleaners();
  }

  // ─── Task 2: Retrieve cleaner profile & completed job count ───────────────
  Future<void> _fetchCleaners() async {
    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'cleaner')
        .get();

    final List<Map<String, dynamic>> fetchedCleaners = [];

    for (final doc in snapshot.docs) {
      final data = {'id': doc.id, ...doc.data()};

      // ✅ FIXED: guna 'cleanerId' dan filter status 'Completed'
      final jobsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('cleanerId', isEqualTo: doc.id)
          .where('status', isEqualTo: 'Completed')
          .get();

      data['job_count'] = jobsSnapshot.docs.length;
      fetchedCleaners.add(data);
    }

    setState(() {
      cleaners = fetchedCleaners;
      isLoading = false;
    });
  }

  // ─── Task 5: Delete cleaner ───────────────────────────────────────────────
  Future<void> _deleteCleaner(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Delete Cleaner',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$userName"? This action cannot be undone.',
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
            .httpsCallable('deleteUser');
        await callable.call({'userId': userId});

        setState(() => cleaners.removeWhere((c) => c['id'] == userId));

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cleaner deleted successfully.'),
            backgroundColor: Colors.red,
          ),
        );
      } on FirebaseFunctionsException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Task 7: Update email via Cloud Function ──────────────────────────────
  Future<void> _updateEmail(String userId, String newEmail) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('updateUserEmail');
      await callable.call({'userId': userId, 'newEmail': newEmail});

      setState(() {
        final index = cleaners.indexWhere((c) => c['id'] == userId);
        if (index != -1) cleaners[index]['email'] = newEmail;
      });
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email update failed: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── Task 4: Edit cleaner (Name, Email, Phone only) ──────────────────────
  Future<void> _editCleaner(Map<String, dynamic> cleaner) async {
    final nameController = TextEditingController(
        text: cleaner['full_name'] ?? cleaner['name'] ?? '');
    final emailController =
    TextEditingController(text: cleaner['email'] ?? '');
    final phoneController =
    TextEditingController(text: cleaner['phone'] ?? '');

    final readyToSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.edit, color: primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'Edit Cleaner',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _editField('Name', nameController, Icons.person),
              const SizedBox(height: 12),
              _editField('Email', emailController, Icons.email),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 13, color: Colors.orange),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Changing email will update login email too.',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _editField('Phone', phoneController, Icons.phone),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (readyToSave != true) {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'Confirm Changes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to save these changes?',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            _confirmRow('Name', nameController.text.trim()),
            const SizedBox(height: 8),
            _confirmRow('Email', emailController.text.trim()),
            const SizedBox(height: 8),
            _confirmRow('Phone', phoneController.text.trim()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('Yes, Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final newEmail = emailController.text.trim();
      final oldEmail = cleaner['email'] ?? '';

      final updatedData = {
        'full_name': nameController.text.trim(),
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'updated_at': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cleaner['id'])
          .update(updatedData);

      if (newEmail.isNotEmpty && newEmail != oldEmail) {
        await _updateEmail(cleaner['id'], newEmail);
      }

      setState(() {
        final index = cleaners.indexWhere((c) => c['id'] == cleaner['id']);
        if (index != -1) {
          cleaners[index] = {...cleaners[index], ...updatedData};
          if (newEmail.isNotEmpty) cleaners[index]['email'] = newEmail;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cleaner updated successfully!'),
          backgroundColor: primaryGreen,
        ),
      );
    }

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  // ─── Helper: Confirm row ──────────────────────────────────────────────────
  Widget _confirmRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 55,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // ─── Helper: Edit text field ──────────────────────────────────────────────
  Widget _editField(
      String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        filled: true,
        fillColor: const Color(0xFFF1FFF3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
    );
  }

  // ─── Task 1 & 3: Cleaner management page + display cleaner list ───────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 20, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF43A047), Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cleaners',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Manage cleaner accounts',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Body ──────────────────────────────────────────────────────────
          isLoading
              ? const Expanded(
              child: Center(child: CircularProgressIndicator()))
              : cleaners.isEmpty
              ? const Expanded(
            child: Center(
              child: Text(
                'No cleaners found.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          )
              : Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchCleaners,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 10),
                itemCount: cleaners.length,
                itemBuilder: (context, index) {
                  final cleaner = cleaners[index];
                  final name = cleaner['full_name'] ??
                      cleaner['name'] ??
                      'Unknown';
                  final email = cleaner['email'] ?? '-';
                  final phone = cleaner['phone'] ?? '-';
                  final jobCount = cleaner['job_count'] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                            const Color(0xFFE8F5E9),
                            child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  email,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  phone,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey),
                                ),
                                const SizedBox(height: 5),
                                // ✅ Job count badge
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 13,
                                      color: primaryGreen,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$jobCount job${jobCount == 1 ? '' : 's'} completed',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: primaryGreen,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Action buttons
                          IconButton(
                            onPressed: () => _editCleaner(cleaner),
                            icon: Icon(Icons.edit,
                                color: primaryGreen, size: 22),
                          ),
                          IconButton(
                            onPressed: () =>
                                _deleteCleaner(cleaner['id'], name),
                            icon: const Icon(Icons.delete,
                                color: Colors.red, size: 22),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}