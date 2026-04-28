class BankModel {
  final int id;
  final String bankName;
  final String accountNumber;
  final double balance;

  BankModel({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.balance,
  });

  factory BankModel.fromJson(Map<String, dynamic> json) {
    return BankModel(
      id: json["id"],
      bankName: json["bank_name"],
      accountNumber: json["account_number"],
      balance: (json["balance"]).toDouble(),
    );
  }
}
