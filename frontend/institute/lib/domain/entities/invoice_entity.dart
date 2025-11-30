class InvoiceEntity {
  final String id;
  final String invoiceNumber;
  final String studentId;
  final String instituteId;
  final double amount;
  final double taxAmount;
  final double totalAmount;
  final double paidAmount;
  final String status;
  final DateTime dueDate;
  final DateTime? paidAt;
  final String? notes;
  final List<InvoiceItemEntity> items;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const InvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    required this.studentId,
    required this.instituteId,
    required this.amount,
    required this.taxAmount,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.status,
    required this.dueDate,
    this.paidAt,
    this.notes,
    required this.items,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isOverdue => status == 'overdue';
  bool get isCanceled => status == 'canceled';

  bool get isOverdueDate {
    if (isPaid || isCanceled) return false;
    return DateTime.now().isAfter(dueDate);
  }

  double get remainingAmount => totalAmount - paidAmount;
  bool get isPartiallyPaid => paidAmount > 0 && paidAmount < totalAmount;
}

class InvoiceItemEntity {
  final String id;
  final String invoiceId;
  final String description;
  final int quantity;
  final double unitPrice;
  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  const InvoiceItemEntity({
    required this.id,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
}
