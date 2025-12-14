import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ Timestamp کے لیے import
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/firestore_servicves.dart';
import '../services/local_db_service.dart';

enum ReportType { finance, purchase, sales, expense, payments, hr }

class PdfService {
  static Future<void> exportReportPdf(
      BuildContext context, {
        required ReportType reportType,
        String? filename,
        bool useFirebase = true,
        required String currentUserId,
      }) async {
    final scaffold = ScaffoldMessenger.of(context);
    filename ??= '${reportType.name}_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';

    try {
      // 1️⃣ Load data based on report type
      List<Map<String, dynamic>> data = [];
      String title = reportType.name.toUpperCase();

      switch (reportType) {
        case ReportType.finance:
          data = await _getData('credits_debits', useFirebase, currentUserId);
          title = 'FINANCE REPORT (CREDITS/DEBITS)';
          break;
        case ReportType.purchase:
          data = await _getData('purchases', useFirebase, currentUserId);
          title = 'PURCHASE REPORT';
          break;
        case ReportType.sales:
          data = await _getData('sales', useFirebase, currentUserId);
          title = 'SALES REPORT';
          break;
        case ReportType.expense:
          data = await _getData('expenses', useFirebase, currentUserId);
          title = 'EXPENSES REPORT';
          break;
        case ReportType.payments:
          data = await _getData('payments', useFirebase, currentUserId);
          title = 'PAYMENTS REPORT';
          break;
        case ReportType.hr:
          data = await _getData('employees', useFirebase, currentUserId);
          title = 'HR MANAGEMENT REPORT';
          break;
      }

      // 2️⃣ Calculate totals
      double totalAmount = 0;
      double totalQuantity = 0;
      int recordCount = data.length;

      for (var record in data) {
        // Amount calculation
        if (record['amount'] != null) {
          totalAmount += double.tryParse(record['amount'].toString()) ?? 0;
        }
        if (record['price'] != null && record['quantity'] != null) {
          final price = double.tryParse(record['price'].toString()) ?? 0;
          final qty = int.tryParse(record['quantity'].toString()) ?? 0;
          totalAmount += price * qty;
        }
        if (record['salary'] != null) {
          totalAmount += double.tryParse(record['salary'].toString()) ?? 0;
        }

        // Quantity calculation
        if (record['quantity'] != null) {
          totalQuantity += double.tryParse(record['quantity'].toString()) ?? 0;
        }
      }

      // 3️⃣ Create PDF document
      final pdf = pw.Document();

      // Cover Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF0B1B3A), // Primary color
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'RECORA',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),

                // Title
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF00C2A8), // Accent color
                  ),
                ),
                pw.SizedBox(height: 20),

                // Report Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300, width: 1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Report Summary',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 15),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Generated Date:'),
                          pw.Text(DateTime.now().toString().split('.').first),
                        ],
                      ),
                      pw.Divider(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Records:'),
                          pw.Text('$recordCount'),
                        ],
                      ),
                      pw.Divider(),
                      if (reportType == ReportType.purchase || reportType == ReportType.sales)
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Quantity:'),
                            pw.Text(totalQuantity.toStringAsFixed(2)),
                          ],
                        ),
                      if (reportType == ReportType.purchase || reportType == ReportType.sales)
                        pw.Divider(),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('Total Amount:'),
                          pw.Text('Rs ${totalAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 40),

                // Footer
                pw.Text(
                  'This report is generated by Recora App',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                ),
              ],
            );
          },
        ),
      );

      // Data Table Page (if data exists)
      if (data.isNotEmpty) {
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return [
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Detailed Records',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(0xFF00C2A8),
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildTable(reportType, data),
              ];
            },
          ),
        );
      }

      // 4️⃣ Save and share PDF
      final bytes = await pdf.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);

      // Show share dialog
      await Printing.sharePdf(
        bytes: bytes,
        filename: filename,
      );

      scaffold.showSnackBar(
        SnackBar(
          content: Text('✅ PDF generated successfully: $filename'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('❌ Error generating PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // Helper method to get data
  static Future<List<Map<String, dynamic>>> _getData(
      String collection,
      bool useFirebase,
      String currentUserId
      ) async {
    List<Map<String, dynamic>> data = [];

    if (useFirebase) {
      data = await FirebaseService.getAllRecords(collection);
    } else {
      final localData = LocalDBService.getAllRecords(collection);
      data = localData.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    // Filter by current user
    return data.where((e) => e['userId'] == currentUserId).toList();
  }

  // Helper method to build table based on report type
  static pw.Widget _buildTable(ReportType reportType, List<Map<String, dynamic>> data) {
    List<String> headers = [];
    List<List<String>> rows = [];

    switch (reportType) {
      case ReportType.purchase:
        headers = ['Item', 'Quantity', 'Price', 'Supplier', 'Date'];
        rows = data.map((record) => [
          record['item']?.toString() ?? 'N/A',
          record['quantity']?.toString() ?? '0',
          'Rs ${(double.tryParse(record['price']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
          record['supplier']?.toString() ?? 'N/A',
          _formatDate(record['createdAt']),
        ]).toList();
        break;

      case ReportType.sales:
        headers = ['Item', 'Quantity', 'Price', 'Customer', 'Date'];
        rows = data.map((record) => [
          record['item']?.toString() ?? 'N/A',
          record['quantity']?.toString() ?? '0',
          'Rs ${(double.tryParse(record['price']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
          record['customer']?.toString() ?? 'N/A',
          _formatDate(record['createdAt']),
        ]).toList();
        break;

      case ReportType.expense:
        headers = ['Reason', 'Amount', 'Date'];
        rows = data.map((record) => [
          record['reason']?.toString() ?? 'N/A',
          'Rs ${(double.tryParse(record['amount']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
          _formatDate(record['createdAt']),
        ]).toList();
        break;

      case ReportType.payments:
        headers = ['Payment ID', 'Receiver', 'Amount', 'Date'];
        rows = data.map((record) => [
          record['paymentId']?.toString() ?? 'N/A',
          record['receiver']?.toString() ?? 'N/A',
          'Rs ${(double.tryParse(record['amount']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
          _formatDate(record['createdAt']),
        ]).toList();
        break;

      case ReportType.hr:
        headers = ['Employee ID', 'Name', 'Position', 'Salary', 'Phone'];
        rows = data.map((record) => [
          record['employeeId']?.toString() ?? 'N/A',
          record['name']?.toString() ?? 'N/A',
          record['position']?.toString() ?? 'N/A',
          'Rs ${(double.tryParse(record['salary']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
          record['phone']?.toString() ?? 'N/A',
        ]).toList();
        break;

      case ReportType.finance:
        headers = ['Title', 'Type', 'Amount', 'Date'];
        rows = data.map((record) => [
          record['title']?.toString() ?? 'N/A',
          (record['type']?.toString() ?? 'N/A').toUpperCase(),
          'Rs ${(double.tryParse(record['amount']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
          _formatDate(record['createdAt']),
        ]).toList();
        break;
    }

    return pw.Table.fromTextArray(
      headers: headers,
      data: rows,
      border: pw.TableBorder.all(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF0B1B3A), // Primary color
      ),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.all(8),
      rowDecoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 0.5, color: PdfColors.grey300)),
      ),
    );
  }

  // Helper method to format date
  static String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    // ✅ Handle Timestamp from Firebase
    if (date is Timestamp) {
      try {
        return date.toDate().toString().split('.').first;
      } catch (e) {
        return 'Date Error';
      }
    }

    // Handle String date
    if (date is String) {
      try {
        return DateTime.parse(date).toString().split('.').first;
      } catch (e) {
        return date;
      }
    }

    // Handle DateTime object
    if (date is DateTime) {
      return date.toString().split('.').first;
    }

    // Default fallback
    return date.toString();
  }
}