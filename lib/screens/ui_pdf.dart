import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/firestore_servicves.dart';
import '../services/local_db_service.dart';

enum ReportType { finance, purchase, expense, sales, payments, hr }

class PdfService {
  static Future<void> exportReportPdf(
      BuildContext context, {
        required ReportType reportType,
        String? filename,
        bool useFirebase = true,
        String? currentUserId, // filter by user
      }) async {
    final scaffold = ScaffoldMessenger.of(context);
    filename ??= '${reportType.name}_Report.pdf';

    try {
      // 1️⃣ Load data
      List<Map<String, dynamic>> data = [];
      switch (reportType) {
        case ReportType.finance:
          data = useFirebase
              ? await FirebaseService.getAllRecords('credits_debits')
              : LocalDBService.getAllRecords('credits_debits')
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          break;
        case ReportType.purchase:
          data = useFirebase
              ? await FirebaseService.getAllRecords('purchases')
              : LocalDBService.getAllRecords('purchases')
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          break;
        case ReportType.expense:
          data = useFirebase
              ? await FirebaseService.getAllRecords('expenses')
              : LocalDBService.getAllRecords('expenses')
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          break;
        case ReportType.sales:
          data = useFirebase
              ? await FirebaseService.getAllRecords('sales')
              : LocalDBService.getAllRecords('sales')
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          break;
        case ReportType.payments:
          data = useFirebase
              ? await FirebaseService.getAllRecords('payments')
              : LocalDBService.getAllRecords('payments')
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          break;
        case ReportType.hr:
          data = useFirebase
              ? await FirebaseService.getAllRecords('employees')
              : LocalDBService.getAllRecords('employees')
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          break;
      }

      // 2️⃣ Filter by user
      if (currentUserId != null) {
        data = data.where((e) => e['userId'] == currentUserId).toList();
      }

      // 3️⃣ Build PDF
      final doc = pw.Document();

      double totalAmount = 0;
      double totalSalary = 0;
      double totalPayment = 0;

      if ([ReportType.finance, ReportType.expense, ReportType.purchase, ReportType.sales]
          .contains(reportType)) {
        for (var row in data) totalAmount += double.tryParse(row['amount']?.toString() ?? '0') ?? 0;
      }
      if (reportType == ReportType.hr) {
        for (var row in data) totalSalary += double.tryParse(row['salary']?.toString() ?? '0') ?? 0;
      }
      if (reportType == ReportType.payments) {
        for (var row in data) totalPayment += double.tryParse(row['amount']?.toString() ?? '0') ?? 0;
      }

      // Cover Page
      doc.addPage(
        pw.Page(
          build: (ctx) => pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  '${reportType.name.toUpperCase()} REPORT',
                  style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 12),
                pw.Text('Generated: ${DateTime.now().toLocal()}'),
                pw.SizedBox(height: 24),
                if (data.isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Summary', style: pw.TextStyle(fontSize: 20)),
                      pw.SizedBox(height: 12),
                      if (reportType == ReportType.hr) ...[
                        pw.Bullet(text: 'Total Employees: ${data.length}'),
                        pw.Bullet(text: 'Total Salaries: Rs ${totalSalary.toStringAsFixed(2)}'),
                      ] else if (reportType == ReportType.payments) ...[
                        pw.Bullet(text: 'Total Payments: ${data.length}'),
                        pw.Bullet(text: 'Total Amount Paid: Rs ${totalPayment.toStringAsFixed(2)}'),
                      ] else ...[
                        pw.Bullet(text: 'Total Records: ${data.length}'),
                        pw.Bullet(text: 'Total Amount: Rs ${totalAmount.toStringAsFixed(2)}'),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      );

      // Table Page
      if (data.isNotEmpty) {
        List<String> headers = [];
        List<List<dynamic>> rows = [];

        switch (reportType) {
          case ReportType.hr:
            headers = ['Employee ID', 'Name', 'Phone', 'Position', 'Salary', 'DOB', 'Joining Date'];
            rows = data.map((e) => [
              e['employeeId'] ?? '-',
              e['name'] ?? '-',
              e['phone'] ?? '-',
              e['position'] ?? '-',
              double.tryParse(e['salary']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0',
              e['dob'] ?? '-',
              e['joiningDate'] ?? '-',
            ]).toList();
            break;
          case ReportType.payments:
            headers = ['Payment ID', 'Receiver', 'Amount', 'Created At'];
            rows = data.map((e) => [
              e['paymentId'] ?? '-',
              e['receiver'] ?? '-',
              double.tryParse(e['amount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0',
              e['createdAt'] ?? '-',
            ]).toList();
            break;
          default:
            headers = ['ID', 'Description', 'Amount', 'Date', 'Type'];
            rows = data.map((e) => [
              e['id'] ?? '-',
              e['description'] ?? '-',
              double.tryParse(e['amount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0',
              e['date'] ?? '-',
              e['type'] ?? '-',
            ]).toList();
        }

        doc.addPage(
          pw.MultiPage(
            build: (ctx) => [
              pw.Header(level: 1, child: pw.Text('Details')),
              pw.Table.fromTextArray(
                headers: headers,
                data: rows,
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                rowDecoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 0.2))),
              ),
            ],
          ),
        );
      }

      final bytes = await doc.save();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(bytes);
      await Printing.sharePdf(bytes: bytes, filename: filename);

      scaffold.showSnackBar(SnackBar(content: Text('PDF saved to ${file.path} and share sheet opened.')));
    } catch (e) {
      scaffold.showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
    }
  }
}
