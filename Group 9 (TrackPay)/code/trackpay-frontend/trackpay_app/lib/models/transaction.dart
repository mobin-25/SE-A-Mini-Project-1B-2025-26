class TransactionModel {
  final int id;
  final String receiverName;
  final double amount;
  final String transactionType;
  final String? bankName;
  final String? categoryName;

  TransactionModel({
    required this.id,
    required this.receiverName,
    required this.amount,
    required this.transactionType,
    this.bankName,
    this.categoryName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json["id"],
      receiverName: json["receiver_name"],
      amount: (json["amount"]).toDouble(),
      transactionType: json["transaction_type"],
      bankName: json["bank_name"],
      categoryName: json["category_name"],
    );
  }
}
