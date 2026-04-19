import 'dart:convert';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/app_settings.dart';
import '../models/app_transaction.dart';
import '../models/enums.dart';

class ReceiptPrinting {
  static Future<void> printTransaction({
    required AppTransaction transaction,
    required AppSettings settings,
  }) async {
    await Printing.layoutPdf(
      name: 'struk-${transaction.orderNo}.pdf',
      onLayout: (format) {
        return buildTransactionPdf(
          transaction: transaction,
          settings: settings,
          pageFormat: format,
        );
      },
    );
  }

  static Future<Uint8List> buildTransactionPdf({
    required AppTransaction transaction,
    required AppSettings settings,
    required PdfPageFormat pageFormat,
  }) async {
    final doc = pw.Document();
    final compactFormat = PdfPageFormat(
      226.77,
      pageFormat.height,
      marginLeft: 16,
      marginTop: 16,
      marginRight: 16,
      marginBottom: 16,
    );
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateText = DateFormat(
      'dd MMM yyyy, HH:mm',
      'id_ID',
    ).format(transaction.createdAt);
    final logoBytes = settings.logoBase64 == null || settings.logoBase64!.isEmpty
        ? null
        : base64Decode(settings.logoBase64!);

    doc.addPage(
      pw.MultiPage(
        pageFormat: compactFormat,
        build: (context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  if (logoBytes != null) ...[
                    pw.Image(
                      pw.MemoryImage(logoBytes),
                      width: 48,
                      height: 48,
                      fit: pw.BoxFit.contain,
                    ),
                    pw.SizedBox(height: 8),
                  ],
                  pw.Text(
                    settings.cafeName,
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Struk Belanja',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            _sectionLine(),
            _infoRow('Order', transaction.orderNo),
            _infoRow('Meja', transaction.tableNo),
            _infoRow('Tanggal', dateText),
            _infoRow('Pelanggan', transaction.customerName),
            _infoRow('Kasir', transaction.cashierName),
            _infoRow('Metode', transaction.paymentMethod.label),
            _infoRow('Status', transaction.status.label),
            _sectionLine(),
            ...transaction.items.map((item) {
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            item.productName,
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Text(
                          currency.format(item.total),
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      '${item.qty} x ${currency.format(item.unitPrice)}',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              );
            }),
            _sectionLine(),
            _totalRow('Subtotal', currency.format(transaction.subtotal)),
            _totalRow(
              'Diskon (${transaction.discountPercent.toStringAsFixed(0)}%)',
              '- ${currency.format(transaction.discountAmount)}',
            ),
            _totalRow(
              'Pajak (${transaction.taxPercent.toStringAsFixed(0)}%)',
              currency.format(transaction.taxAmount),
            ),
            _totalRow(
              'Service (${transaction.servicePercent.toStringAsFixed(0)}%)',
              currency.format(transaction.serviceAmount),
            ),
            _sectionLine(),
            _totalRow(
              'Total',
              currency.format(transaction.grandTotal),
              bold: true,
            ),
            _totalRow('Dibayar', currency.format(transaction.paidAmount)),
            _totalRow(
              'Sisa',
              currency.format(transaction.pendingAmount),
              bold: true,
            ),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Text(
                'Terima kasih sudah berbelanja',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ];
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 52,
            child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          ),
          pw.Text(': ', style: const pw.TextStyle(fontSize: 9)),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: 10,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.SizedBox(width: 8),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  static pw.Widget _sectionLine() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Text(
        '--------------------------------',
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }
}
