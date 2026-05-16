import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PricingManagementPage extends StatefulWidget {
  const PricingManagementPage({super.key});

  @override
  State<PricingManagementPage> createState() =>
      _PricingManagementPageState();
}

class _PricingManagementPageState
    extends State<PricingManagementPage> {

  final Color primaryGreen = const Color(0xFF2E7D32);

  final List<Map<String, dynamic>> services = [
    {
      'id': 'House Cleaning',
      'title': 'House Cleaning',
      'icon': Icons.home,
    },
    {
      'id': 'Deep Cleaning',
      'title': 'Deep Cleaning',
      'icon': Icons.cleaning_services,
    },
    {
      'id': 'Office Cleaning',
      'title': 'Office Cleaning',
      'icon': Icons.business,
    },
  ];

  Map<String, Map<String, TextEditingController>> controllers = {};
  Map<String, Map<String, int>> originalPrices = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initControllers();
    _fetchPrices();
  }

  void _initControllers() {
    for (var service in services) {
      final id = service['id'] as String;
      controllers[id] = {
        'Small': TextEditingController(),
        'Medium': TextEditingController(),
        'Large': TextEditingController(),
      };
      originalPrices[id] = {'Small': 0, 'Medium': 0, 'Large': 0};
    }
  }

  Future<void> _fetchPrices() async {
    for (var service in services) {
      final id = service['id'] as String;
      final doc = await FirebaseFirestore.instance
          .collection('service_prices')
          .doc(id)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final small = (data['smallPrice'] ?? 0) as int;
        final medium = (data['mediumPrice'] ?? 0) as int;
        final large = (data['largePrice'] ?? 0) as int;

        controllers[id]!['Small']!.text = small.toString();
        controllers[id]!['Medium']!.text = medium.toString();
        controllers[id]!['Large']!.text = large.toString();

        originalPrices[id] = {
          'Small': small,
          'Medium': medium,
          'Large': large,
        };
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _confirmAndSave(
      String serviceId, String serviceTitle) async {
    final newSmall =
        int.tryParse(controllers[serviceId]!['Small']!.text) ?? 0;
    final newMedium =
        int.tryParse(controllers[serviceId]!['Medium']!.text) ?? 0;
    final newLarge =
        int.tryParse(controllers[serviceId]!['Large']!.text) ?? 0;

    final oldSmall = originalPrices[serviceId]!['Small']!;
    final oldMedium = originalPrices[serviceId]!['Medium']!;
    final oldLarge = originalPrices[serviceId]!['Large']!;

    final List<Map<String, dynamic>> changes = [];
    if (newSmall != oldSmall) {
      changes.add({'label': 'Small', 'old': oldSmall, 'new': newSmall});
    }
    if (newMedium != oldMedium) {
      changes.add({'label': 'Medium', 'old': oldMedium, 'new': newMedium});
    }
    if (newLarge != oldLarge) {
      changes.add({'label': 'Large', 'old': oldLarge, 'new': newLarge});
    }

    if (changes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes detected.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.edit_note, color: primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'Confirm Changes',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to update $serviceTitle pricing?',
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ...changes.map((change) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      change['label'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'RM ${change['old']}',
                    style: const TextStyle(
                      color: Colors.red,
                      decoration: TextDecoration.lineThrough,
                      fontSize: 14,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'RM ${change['new']}',
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Yes, Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _savePrices(serviceId);
      originalPrices[serviceId] = {
        'Small': newSmall,
        'Medium': newMedium,
        'Large': newLarge,
      };
    }
  }

  Future<void> _savePrices(String serviceId) async {
    final small =
        int.tryParse(controllers[serviceId]!['Small']!.text) ?? 0;
    final medium =
        int.tryParse(controllers[serviceId]!['Medium']!.text) ?? 0;
    final large =
        int.tryParse(controllers[serviceId]!['Large']!.text) ?? 0;

    await FirebaseFirestore.instance
        .collection('service_prices')
        .doc(serviceId)
        .set({
      'smallPrice': small,
      'mediumPrice': medium,
      'largePrice': large,
      'updated_at': Timestamp.now(),
    }, SetOptions(merge: true));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$serviceId pricing updated!'),
        backgroundColor: primaryGreen,
      ),
    );
  }

  @override
  void dispose() {
    for (var service in services) {
      final id = service['id'] as String;
      controllers[id]!['Small']!.dispose();
      controllers[id]!['Medium']!.dispose();
      controllers[id]!['Large']!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FFF3),

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF43A047),
                Color(0xFF66BB6A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        title: const Text(
          'Pricing Management',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 10,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          final id = service['id'] as String;
          final icon = service['icon'] as IconData;
          final title = service['title'] as String;

          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: primaryGreen,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _priceField('Small', controllers[id]!['Small']!),
                  const SizedBox(height: 12),
                  _priceField('Medium', controllers[id]!['Medium']!),
                  const SizedBox(height: 12),
                  _priceField('Large', controllers[id]!['Large']!),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => _confirmAndSave(id, title),
                      icon: const Icon(
                        Icons.save,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Save Pricing',
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
        },
      ),
    );
  }

  Widget _priceField(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: 'RM ',
              prefixStyle: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.bold,
              ),
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
                borderSide: BorderSide(color: primaryGreen, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}