enum UserRole { owner, admin, kasir }

enum PaymentMethod { cash, qris, debitKredit, ewallet, transfer }

enum TransactionStatus { lunas, pending, splitBill, refund, batal }

extension UserRoleX on UserRole {
  String get label {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.kasir:
        return 'Kasir';
    }
  }
}

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.qris:
        return 'QRIS';
      case PaymentMethod.debitKredit:
        return 'Debit/Kredit';
      case PaymentMethod.ewallet:
        return 'E-Wallet';
      case PaymentMethod.transfer:
        return 'Transfer';
    }
  }
}

extension TransactionStatusX on TransactionStatus {
  String get label {
    switch (this) {
      case TransactionStatus.lunas:
        return 'Lunas';
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.splitBill:
        return 'Split Bill';
      case TransactionStatus.refund:
        return 'Refund';
      case TransactionStatus.batal:
        return 'Batal';
    }
  }
}
