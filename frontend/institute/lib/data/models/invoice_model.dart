import '../../domain/entities/invoice_entity.dart';

class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required String id,
    required String invoiceNumber,
    required String studentId,
    required String instituteId,
    required double amount,
    required double taxAmount,
    required double totalAmount,
    double paidAmount = 0.0,
    required String status,
    required DateTime dueDate,
    DateTime? paidAt,
    String? notes,
    required List<InvoiceItemEntity> items,
    required String createdBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super(
          id: id,
          invoiceNumber: invoiceNumber,
          studentId: studentId,
          instituteId: instituteId,
          amount: amount,
          taxAmount: taxAmount,
          totalAmount: totalAmount,
          paidAmount: paidAmount,
          status: status,
          dueDate: dueDate,
          paidAt: paidAt,
          notes: notes,
          items: items,
          createdBy: createdBy,
          createdAt: createdAt,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        );

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    List<InvoiceItemEntity> itemsList = [];
    if (json['items'] != null) {
      final itemsJson = json['items'] as List;
      itemsList = itemsJson.map((i) => InvoiceItemModel.fromJson(i)).toList();
    }

    return InvoiceModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      studentId: json['student_id'] ?? '',
      instituteId: json['institute_id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      paidAmount: (json['paid_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      dueDate: DateTime.parse(json['due_date']),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      notes: json['notes'],
      items: itemsList,
      createdBy: json['created_by'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'institute_id': instituteId,
      'due_date': dueDate.toIso8601String(),
      'notes': notes,
      'items': items.map((item) => InvoiceItemModel.toJsonCreate(item)).toList(),
    };
  }
}

class InvoiceItemModel extends InvoiceItemEntity {
  const InvoiceItemModel({
    required String id,
    required String invoiceId,
    required String description,
    required int quantity,
    required double unitPrice,
    required double amount,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) : super(
          id: id,
          invoiceId: invoiceId,
          description: description,
          quantity: quantity,
          unitPrice: unitPrice,
          amount: amount,
          createdAt: createdAt,
          updatedAt: updatedAt,
          deletedAt: deletedAt,
        );

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceItemModel(
      id: json['id'] ?? '',
      invoiceId: json['invoice_id'] ?? '',
      description: json['description'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unit_price'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  static Map<String, dynamic> toJsonCreate(InvoiceItemEntity item) {
    return {
      'description': item.description,
      'quantity': item.quantity,
      'unit_price': item.unitPrice,
    };
  }
}
