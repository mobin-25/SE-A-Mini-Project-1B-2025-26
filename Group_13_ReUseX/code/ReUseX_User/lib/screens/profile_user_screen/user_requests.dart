import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main_navigation.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  final user = FirebaseAuth.instance.currentUser;

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';

    final date = timestamp.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  int? parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  String getSellDisplayTitle(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    final deviceType = (data['deviceType'] ?? '').toString().trim();

    if (title.isNotEmpty &&
        title != 'Phone Sell Request' &&
        title != 'Laptop Sell Request' &&
        title != 'Other Item Sell Request') {
      return title;
    }

    switch (deviceType.toLowerCase()) {
      case 'phone':
        return 'Phone Sell Request';
      case 'laptop':
        return 'Laptop Sell Request';
      case 'others':
        return 'Other Item Sell Request';
      default:
        return 'Sell Request';
    }
  }

  String getSellDisplayCategory(Map<String, dynamic> data) {
    final requestType = (data['requestType'] ?? '').toString().trim();
    final deviceType = (data['deviceType'] ?? '').toString().trim();

    final requestText = requestType.isEmpty
        ? 'Request'
        : requestType[0].toUpperCase() + requestType.substring(1);

    final deviceText = deviceType.isEmpty
        ? ''
        : deviceType[0].toUpperCase() + deviceType.substring(1);

    return deviceText.isEmpty ? requestText : '$requestText • $deviceText';
  }

  List<_RequestItem> buildApprovalRequests({
    required List<QueryDocumentSnapshot> approvalDocs,
  }) {
    final List<_RequestItem> items = [];

    for (final doc in approvalDocs) {
      final data = doc.data() as Map<String, dynamic>;

      items.add(
        _RequestItem(
          docId: doc.id,
          collectionName: 'approval_requests',
          data: data,
          imageUrl: (data['imageUrl'] ?? '').toString(),
          productName: getSellDisplayTitle(data),
          category: getSellDisplayCategory(data),
          submittedDate: formatDate(data['createdAt'] as Timestamp?),
          status: (data['status'] ?? 'pending').toString(),
          offeredAmount: parsePrice(data['price']),
          adminNote: (data['adminNote'] ?? '').toString(),
          createdAt: data['createdAt'] as Timestamp?,
        ),
      );
    }

    items.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return items;
  }

  void openDetail(_RequestItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _RequestDetailPage(
          docId: item.docId,
          collectionName: item.collectionName,
          item: item.data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F6F4),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'My Requests',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Lora',
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          backgroundColor: Colors.green,
        ),
        body: const Center(
          child: Text("User not logged in"),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Requests',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lora',
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('approval_requests')
            .where('userId', isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, approvalSnapshot) {
          if (approvalSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (approvalSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Something went wrong:\n${approvalSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final approvalDocs = approvalSnapshot.data?.docs ?? [];

          final allItems = buildApprovalRequests(
            approvalDocs: approvalDocs,
          );

          if (allItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No requests yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your submitted product approvals will appear here.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: allItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final item = allItems[index];

              return _RequestCard(
                docId: item.docId,
                imageUrl: item.imageUrl,
                productName: item.productName,
                category: item.category,
                submittedDate: item.submittedDate,
                status: item.status,
                offeredAmount: item.offeredAmount,
                adminNote: item.adminNote,
                onViewMore: () => openDetail(item),
              );
            },
          );
        },
      ),
    );
  }
}

class _RequestItem {
  final String docId;
  final String collectionName;
  final Map<String, dynamic> data;
  final String imageUrl;
  final String productName;
  final String category;
  final String submittedDate;
  final String status;
  final int? offeredAmount;
  final String adminNote;
  final Timestamp? createdAt;

  _RequestItem({
    required this.docId,
    required this.collectionName,
    required this.data,
    required this.imageUrl,
    required this.productName,
    required this.category,
    required this.submittedDate,
    required this.status,
    required this.offeredAmount,
    required this.adminNote,
    required this.createdAt,
  });
}

class _StatusMeta {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;

  _StatusMeta(this.label, this.icon, this.color, this.bgColor, this.borderColor);
}

_StatusMeta _getMeta(String status, int? price) {
  if (status == 'approved' && price != null) {
    return _StatusMeta(
      'Price Offered!',
      Icons.local_offer_outlined,
      Colors.blue.shade600,
      Colors.blue.shade50,
      Colors.blue.shade200,
    );
  }

  switch (status) {
    case 'sold':
    case 'completed':
      return _StatusMeta(
        'Item Sold',
        Icons.check_circle_outline,
        Colors.green,
        Colors.green.shade50,
        Colors.green.shade200,
      );
    case 'declined':
    case 'rejected':
      return _StatusMeta(
        'Offer Declined',
        Icons.cancel_outlined,
        Colors.red.shade400,
        Colors.red.shade50,
        Colors.red.shade200,
      );
    case 'withdrawn':
      return _StatusMeta(
        'Withdrawn',
        Icons.cancel_outlined,
        Colors.grey.shade600,
        Colors.grey.shade50,
        Colors.grey.shade300,
      );
    case 'pending':
    default:
      return _StatusMeta(
        'Under Review',
        Icons.hourglass_top_rounded,
        Colors.orange,
        Colors.orange.shade50,
        Colors.orange.shade200,
      );
  }
}

class _RequestCard extends StatelessWidget {
  final String docId;
  final String imageUrl;
  final String productName;
  final String category;
  final String submittedDate;
  final String status;
  final int? offeredAmount;
  final String adminNote;
  final VoidCallback onViewMore;

  const _RequestCard({
    required this.docId,
    required this.imageUrl,
    required this.productName,
    required this.category,
    required this.submittedDate,
    required this.status,
    required this.offeredAmount,
    required this.adminNote,
    required this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    final m = _getMeta(status, offeredAmount);
    final showViewMore =
        status == 'pending' || (status == 'approved' && offeredAmount != null);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: (status == 'approved' && offeredAmount != null)
            ? Border.all(color: Colors.blue.shade300, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.green.shade50,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.green,
                        size: 30,
                      ),
                    ),
                  )
                      : Container(
                    width: 80,
                    height: 80,
                    color: Colors.green.shade50,
                    child: const Icon(
                      Icons.image_outlined,
                      color: Colors.green,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$category  ·  $submittedDate',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: m.bgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: m.borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(m.icon, size: 12, color: m.color),
                            const SizedBox(width: 4),
                            Text(
                              m.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: m.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showViewMore) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            onPressed: onViewMore,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                            ),
                            child: const Text(
                              'View More',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (status == 'approved' && offeredAmount != null)
            _Banner(
              color: Colors.blue.shade50,
              borderColor: Colors.blue.shade100,
              icon: Icons.local_offer_outlined,
              iconColor: Colors.blue.shade700,
              text: 'Offered ₹$offeredAmount  ·  Tap View More to respond',
              textColor: Colors.blue.shade700,
            ),
          if ((status == 'sold' || status == 'completed') && offeredAmount != null)
            _Banner(
              color: Colors.green.shade50,
              borderColor: Colors.green.shade100,
              icon: Icons.check_circle_outline,
              iconColor: Colors.green.shade700,
              text: 'Sold for ₹$offeredAmount  ·  Payment coming soon',
              textColor: Colors.green.shade700,
            ),
          if (status == 'declined' || status == 'rejected')
            _Banner(
              color: Colors.grey.shade50,
              borderColor: Colors.grey.shade200,
              icon: Icons.cancel_outlined,
              iconColor: Colors.grey.shade500,
              text: 'Offer declined',
              textColor: Colors.grey.shade600,
            ),
          if (status == 'withdrawn')
            _Banner(
              color: Colors.grey.shade50,
              borderColor: Colors.grey.shade200,
              icon: Icons.cancel_outlined,
              iconColor: Colors.grey.shade500,
              text: 'Request withdrawn',
              textColor: Colors.grey.shade600,
            ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;
  final String text;

  const _Banner({
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: color,
        border: Border(top: BorderSide(color: borderColor)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestDetailPage extends StatefulWidget {
  final String docId;
  final String collectionName;
  final Map<String, dynamic> item;

  const _RequestDetailPage({
    required this.docId,
    required this.collectionName,
    required this.item,
  });

  @override
  State<_RequestDetailPage> createState() => _RequestDetailPageState();
}

class _RequestDetailPageState extends State<_RequestDetailPage> {
  bool isLoading = false;

  Future<void> _updateStatus(String status) async {
    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection(widget.collectionName)
          .doc(widget.docId)
          .update({"status": status});

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _OutcomePage(
            sold: status == 'sold',
            productName: _displayTitle(widget.item),
            amount: _parsePrice(widget.item['price']),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _displayTitle(Map<String, dynamic> data) {
    final title = (data['title'] ?? '').toString().trim();
    final deviceType = (data['deviceType'] ?? '').toString().trim();

    if (title.isNotEmpty &&
        title != 'Phone Sell Request' &&
        title != 'Laptop Sell Request' &&
        title != 'Other Item Sell Request') {
      return title;
    }

    switch (deviceType.toLowerCase()) {
      case 'phone':
        return 'Phone Sell Request';
      case 'laptop':
        return 'Laptop Sell Request';
      case 'others':
        return 'Other Item Sell Request';
      default:
        return 'Sell Request';
    }
  }

  int? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }

  String _displayCategory(Map<String, dynamic> data) {
    final requestType = (data['requestType'] ?? '').toString().trim();
    final deviceType = (data['deviceType'] ?? '').toString().trim();

    final requestText = requestType.isEmpty
        ? 'Request'
        : requestType[0].toUpperCase() + requestType.substring(1);

    final deviceText = deviceType.isEmpty
        ? ''
        : deviceType[0].toUpperCase() + deviceType.substring(1);

    return deviceText.isEmpty ? requestText : '$requestText • $deviceText';
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';

    final date = timestamp.toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final status = (item['status'] ?? 'pending').toString();
    final offeredAmount = _parsePrice(item['price']);
    final adminNote = (item['adminNote'] ?? '').toString();
    final imageUrl = (item['imageUrl'] ?? '').toString();
    final productName = _displayTitle(item);
    final category = _displayCategory(item);
    final submittedDate = _formatDate(item['createdAt'] as Timestamp?);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Request Details',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Lora',
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 260,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 260,
                      color: Colors.green.shade50,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 55,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  )
                      : Container(
                    height: 260,
                    color: Colors.green.shade50,
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 55,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.35),
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 16,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Product'),
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      _InfoRow(Icons.inventory_2_outlined, 'Product Name',
                          productName),
                      const _HDivider(),
                      _InfoRow(Icons.category_outlined, 'Category', category),
                      const _HDivider(),
                      _InfoRow(Icons.calendar_today_outlined, 'Submitted On',
                          submittedDate),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel('Status'),
                  const SizedBox(height: 12),
                  _StatusStepper(
                    status: status,
                    hasPriceOffer: offeredAmount != null,
                  ),
                  const SizedBox(height: 24),
                  if (status == 'pending')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.hourglass_top_rounded,
                              color: Colors.orange.shade600, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Our inspection team is reviewing your item. You will be notified once a price is set.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange.shade800,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (status == 'pending') ...[
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        onPressed:
                        isLoading ? null : () => _updateStatus('withdrawn'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade500,
                          side: BorderSide(
                              color: Colors.red.shade300, width: 1.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                          'Withdraw Request',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                  if (status == 'approved' && offeredAmount != null) ...[
                    _SectionLabel('Price Offered'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Our Offer For Your Item',
                            style:
                            TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹$offeredAmount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 46,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const Text(
                            'One-time payment on pickup',
                            style:
                            TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (adminNote.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 17, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                adminNote,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.amber.shade900,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: OutlinedButton(
                              onPressed:
                              isLoading ? null : () => _updateStatus('declined'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade500,
                                side: BorderSide(
                                    color: Colors.red.shade400, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator()
                                  : Text(
                                'Decline',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.red.shade500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed:
                              isLoading ? null : () => _updateStatus('sold'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: Colors.green.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                  color: Colors.white)
                                  : const Row(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sell_outlined, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Sell My Item',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if ((status == 'sold' || status == 'completed') &&
                      offeredAmount != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        'You accepted the offer. Final amount: ₹$offeredAmount',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                  if (status == 'declined' || status == 'rejected') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'You declined the offered price.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                  if (status == 'withdrawn') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Text(
                        'You withdrew this request before approval.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStepper extends StatelessWidget {
  final String status;
  final bool hasPriceOffer;

  const _StatusStepper({
    required this.status,
    required this.hasPriceOffer,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      ['Submitted', 'Your item has been received.'],
      ['Under Review', 'Inspection team is evaluating.'],
      ['Price Offered', 'We have set a price for your item.'],
      ['Decision Made', 'You accepted or declined the offer.'],
    ];

    int activeStep;
    if (status == 'pending') {
      activeStep = 1;
    } else if (status == 'approved' && hasPriceOffer) {
      activeStep = 2;
    } else {
      activeStep = 3;
    }

    final icons = [
      Icons.upload_file_outlined,
      Icons.search_outlined,
      Icons.local_offer_outlined,
      Icons.done_all_outlined,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: List.generate(steps.length, (i) {
          final isDone = i < activeStep;
          final isActive = i == activeStep;
          final isLast = i == steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isDone
                          ? Colors.green
                          : isActive
                          ? Colors.green.shade100
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDone || isActive
                            ? Colors.green
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isDone ? Icons.check : icons[i],
                      size: 15,
                      color: isDone
                          ? Colors.white
                          : isActive
                          ? Colors.green
                          : Colors.grey.shade400,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 36,
                      color:
                      isDone ? Colors.green.shade300 : Colors.grey.shade200,
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[i][0],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDone || isActive
                              ? Colors.black87
                              : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        steps[i][1],
                        style: TextStyle(
                          fontSize: 12,
                          color: isDone || isActive
                              ? Colors.grey
                              : Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _OutcomePage extends StatelessWidget {
  final bool sold;
  final String productName;
  final int? amount;

  const _OutcomePage({
    required this.sold,
    required this.productName,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: sold ? Colors.green.shade50 : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  sold
                      ? Icons.check_circle_outline
                      : Icons.sentiment_dissatisfied_outlined,
                  size: 60,
                  color: sold ? Colors.green : Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                sold ? 'Your Item Has Been Sold! 🎉' : 'Offer Declined',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: sold ? Colors.black87 : Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                sold
                    ? 'Great news! You will receive ₹$amount for your $productName. Our team will contact you shortly to arrange pickup and process your payment.'
                    : 'No worries! You have declined the offer for your $productName. You can always submit it again later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.6,
                ),
              ),
              if (sold) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.currency_rupee,
                          color: Colors.green.shade600, size: 28),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Amount',
                            style: TextStyle(
                                fontSize: 12, color: Colors.green.shade600),
                          ),
                          Text(
                            '₹$amount',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainNavigation()),
                        (route) => false,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sold ? Colors.green : Colors.black87,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.home_outlined, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Go to Home',
                        style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.green,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 19, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
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

class _HDivider extends StatelessWidget {
  const _HDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: Colors.grey.shade100);
  }
}