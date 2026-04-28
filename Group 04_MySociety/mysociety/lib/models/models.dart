import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String flatNo;
  final String role; // 'admin' | 'resident'
  final String status; // 'pending' | 'approved'
  final String phone;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.flatNo,
    required this.role,
    required this.status,
    this.phone = '',
  });

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserModel(
      uid: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      flatNo: d['flatNo'] ?? '',
      role: d['role'] ?? 'resident',
      status: d['status'] ?? 'pending',
      phone: d['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'flatNo': flatNo,
        'role': role,
        'status': status,
        'phone': phone,
      };
}

class ComplaintModel {
  final String id;
  final String uid;
  final String residentName;
  final String flatNo;
  final String category;
  final String description;
  final String status; // 'open' | 'resolved'
  final String adminNote;
  final DateTime createdAt;

  ComplaintModel({
    required this.id,
    required this.uid,
    required this.residentName,
    required this.flatNo,
    required this.category,
    required this.description,
    required this.status,
    this.adminNote = '',
    required this.createdAt,
  });

  factory ComplaintModel.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return ComplaintModel(
      id: doc.id,
      uid: d['uid'] ?? '',
      residentName: d['residentName'] ?? '',
      flatNo: d['flatNo'] ?? '',
      category: d['category'] ?? '',
      description: d['description'] ?? '',
      status: d['status'] ?? 'open',
      adminNote: d['adminNote'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'residentName': residentName,
        'flatNo': flatNo,
        'category': category,
        'description': description,
        'status': status,
        'adminNote': adminNote,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class NoticeModel {
  final String id;
  final String title;
  final String body;
  final String postedBy;
  final DateTime createdAt;

  NoticeModel({
    required this.id,
    required this.title,
    required this.body,
    required this.postedBy,
    required this.createdAt,
  });

  factory NoticeModel.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return NoticeModel(
      id: doc.id,
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      postedBy: d['postedBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'postedBy': postedBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class BookingModel {
  final String id;
  final String uid;
  final String residentName;
  final String flatNo;
  final String amenity;
  final DateTime date;
  final String time;
  final String status; // 'pending' | 'approved' | 'rejected'

  BookingModel({
    required this.id,
    required this.uid,
    required this.residentName,
    required this.flatNo,
    required this.amenity,
    required this.date,
    required this.time,
    required this.status,
  });

  factory BookingModel.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    
    DateTime parsedDate = DateTime.now();
    if (d['date'] is Timestamp) {
      parsedDate = (d['date'] as Timestamp).toDate();
    } else if (d['date'] is String) {
      try {
        final str = d['date'] as String;
        if (str.contains('/')) {
          final parts = str.split('/');
          if (parts.length == 3) {
            parsedDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        } else {
          parsedDate = DateTime.parse(str);
        }
      } catch (_) {}
    }

    return BookingModel(
      id: doc.id,
      uid: d['uid'] ?? '',
      residentName: d['residentName'] ?? '',
      flatNo: d['flatNo'] ?? '',
      amenity: d['amenity'] ?? '',
      date: parsedDate,
      time: d['time'] ?? '',
      status: d['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'residentName': residentName,
        'flatNo': flatNo,
        'amenity': amenity,
        'date': Timestamp.fromDate(date),
        'time': time,
        'status': status,
      };
}

class ExpenseModel {
  final String id;
  final String category;
  final double amount;
  final String description;
  final DateTime date;
  final String addedBy;

  ExpenseModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.addedBy,
  });

  factory ExpenseModel.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return ExpenseModel(
      id: doc.id,
      category: d['category'] ?? '',
      amount: (d['amount'] ?? 0).toDouble(),
      description: d['description'] ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      addedBy: d['addedBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'category': category,
        'amount': amount,
        'description': description,
        'date': Timestamp.fromDate(date),
        'addedBy': addedBy,
      };
}

class PaymentModel {
  final String id;
  final double amount;
  final String month;
  final int year;
  final String recordedBy;
  final DateTime createdAt;

  PaymentModel({
    required this.id,
    required this.amount,
    required this.month,
    required this.year,
    required this.recordedBy,
    required this.createdAt,
  });

  factory PaymentModel.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? {};
    return PaymentModel(
      id: doc.id,
      amount: (d['amount'] ?? 0).toDouble(),
      month: d['month'] ?? '',
      year: d['year'] ?? DateTime.now().year,
      recordedBy: d['recordedBy'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'amount': amount,
        'month': month,
        'year': year,
        'recordedBy': recordedBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
