import 'enums.dart';

class AppSettings {
  const AppSettings({
    required this.cafeName,
    required this.logoBase64,
    required this.taxPercent,
    required this.servicePercent,
    required this.activePayments,
  });

  final String cafeName;
  final String? logoBase64;
  final double taxPercent;
  final double servicePercent;
  final List<PaymentMethod> activePayments;

  AppSettings copyWith({
    String? cafeName,
    String? logoBase64,
    double? taxPercent,
    double? servicePercent,
    List<PaymentMethod>? activePayments,
  }) {
    return AppSettings(
      cafeName: cafeName ?? this.cafeName,
      logoBase64: logoBase64 ?? this.logoBase64,
      taxPercent: taxPercent ?? this.taxPercent,
      servicePercent: servicePercent ?? this.servicePercent,
      activePayments: activePayments ?? this.activePayments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cafeName': cafeName,
      'logoBase64': logoBase64,
      'taxPercent': taxPercent,
      'servicePercent': servicePercent,
      'activePayments': activePayments.map((payment) => payment.name).toList(),
    };
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    final paymentList = (map['activePayments'] as List<dynamic>? ?? [])
        .map((value) => value.toString())
        .toList();

    return AppSettings(
      cafeName: map['cafeName']?.toString() ?? 'Cafe Kamu',
      logoBase64: map['logoBase64']?.toString(),
      taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 10,
      servicePercent: (map['servicePercent'] as num?)?.toDouble() ?? 5,
      activePayments: paymentList
          .map(
            (name) => PaymentMethod.values.firstWhere(
              (method) => method.name == name,
              orElse: () => PaymentMethod.cash,
            ),
          )
          .toList(),
    );
  }
}
