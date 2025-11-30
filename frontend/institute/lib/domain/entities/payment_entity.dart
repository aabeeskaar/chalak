class PaymentEntity {
  final String id;
  final String invoiceId;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? notes;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const PaymentEntity({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.notes,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  String get formattedPaymentMethod {
    switch (paymentMethod.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'online':
        return 'Online';
      default:
        return paymentMethod;
    }
  }
}