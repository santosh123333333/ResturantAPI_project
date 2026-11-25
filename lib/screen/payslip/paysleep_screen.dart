
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../services/api_services.dart';

class PayslipScreen extends StatefulWidget {
  const PayslipScreen({super.key, required this.role});

  final String role;

  @override
  State<PayslipScreen> createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  final ApiService _apiService = ApiService();

  late Future<List<dynamic>> _payslipsFuture;

  final NumberFormat _currency =
      NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);

  bool _isGenerating = false;
  final Set<int> _payingIds = {};

  bool get _isManager {
    final role = widget.role.toLowerCase();
    return role == 'admin' || role == 'manager';
  }

  @override
  void initState() {
    super.initState();
    _payslipsFuture = _fetchPayslips();
  }

  Future<List<dynamic>> _fetchPayslips() {
    if (_isManager) {
      return _apiService.getAllPayslips();
    }
    return _apiService.getMyPayslips();
  }

  Future<void> _refreshPayslips() async {
    setState(() {
      _payslipsFuture = _fetchPayslips();
    });

    try {
      await _payslipsFuture;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  double _number(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int? _integer(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String _money(dynamic value) => _currency.format(_number(value));

  String _text(dynamic value, [String fallback = 'Not provided']) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  // -------------------------------------------------------
  // GENERATE PAYSLIP
  // -------------------------------------------------------

  Future<void> _showGenerateDialog() async {
    final formKey = GlobalKey<FormState>();

    final userIdController = TextEditingController();
    final monthController = TextEditingController(
      text: DateFormat('yyyy-MM').format(DateTime.now()),
    );
    final salaryController = TextEditingController();
    final deductionsController = TextEditingController(text: '0');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Generate Payslip',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: userIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Employee User ID',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final id = int.tryParse(value?.trim() ?? '');
                      if (id == null || id <= 0) {
                        return 'Enter a valid employee ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: monthController,
                    decoration: const InputDecoration(
                      labelText: 'Payroll Month',
                      hintText: 'YYYY-MM',
                      prefixIcon: Icon(Icons.calendar_month),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      final valid = RegExp(r'^\d{4}-(0[1-9]|1[0-2])$')
                          .hasMatch(text);
                      if (!valid) return 'Use YYYY-MM format';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: salaryController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Base Salary (Rs.)',
                      prefixIcon: Icon(Icons.payments),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final amount =
                          double.tryParse(value?.trim() ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Enter a salary greater than zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: deductionsController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Deductions (Rs.)',
                      prefixIcon: Icon(Icons.remove_circle_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final amount =
                          double.tryParse(value?.trim() ?? '');
                      if (amount == null || amount < 0) {
                        return 'Enter a valid deduction';
                      }

                      final salary =
                          double.tryParse(salaryController.text.trim());

                      if (salary != null && amount > salary) {
                        return 'Deductions cannot exceed salary';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Generate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(dialogContext, {
                  'userId': int.parse(userIdController.text.trim()),
                  'month': monthController.text.trim(),
                  'salary': double.parse(salaryController.text.trim()),
                  'deductions':
                      double.parse(deductionsController.text.trim()),
                });
              },
            ),
          ],
        );
      },
    );

    userIdController.dispose();
    monthController.dispose();
    salaryController.dispose();
    deductionsController.dispose();

    if (result == null || !mounted) return;

    await _generatePayslip(
      userId: result['userId'] as int,
      month: result['month'] as String,
      salary: result['salary'] as double,
      deductions: result['deductions'] as double,
    );
  }

  Future<void> _generatePayslip({
    required int userId,
    required String month,
    required double salary,
    required double deductions,
  }) async {
    if (_isGenerating) return;

    setState(() => _isGenerating = true);

    try {
      await _apiService.generatePayslip(
        userId,
        month,
        salary,
        deductions,
      );

      if (!mounted) return;

      _showMessage('Payslip generated successfully.');
      await _refreshPayslips();
    } catch (e) {
      _showMessage('Could not generate payslip: $e', error: true);
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  // -------------------------------------------------------
  // MARK PAYSLIP AS PAID
  // -------------------------------------------------------

  Future<void> _confirmPayment(Map<String, dynamic> slip) async {
    final payslipId = _integer(slip['id']);

    if (payslipId == null) {
      _showMessage('Invalid payslip ID.', error: true);
      return;
    }

    final employeeName = _text(slip['employee_name'], 'Employee');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Payment'),
        content: Text(
          'Mark the payslip for $employeeName '
          '(${_money(slip['net_pay'])}) as paid?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _payingIds.add(payslipId));

    try {
      await _apiService.markPayslipAsPaid(payslipId);

      if (!mounted) return;

      _showMessage('Payment marked as successful.');
      await _refreshPayslips();
    } catch (e) {
      _showMessage('Payment update failed: $e', error: true);
    } finally {
      if (mounted) {
        setState(() => _payingIds.remove(payslipId));
      }
    }
  }

  // -------------------------------------------------------
  // PDF GENERATOR
  // -------------------------------------------------------

  Future<void> _downloadPayslip(Map<String, dynamic> slip) async {
    try {
      final pdf = pw.Document();

      final employeeName = _text(slip['employee_name'], 'Employee');
      final userId = _text(slip['user_id']);
      final month = _text(slip['month']);
      final baseSalary = _number(slip['base_salary']);
      final deductions = _number(slip['deductions']);
      final netPay = slip['net_pay'] == null
          ? baseSalary - deductions
          : _number(slip['net_pay']);

      final status =
          _text(slip['status'], 'pending').toUpperCase();

      pw.Widget detailRow(String label, String value) {
        return pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                label,
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => [
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: const pw.BoxDecoration(
                color: PdfColors.green800,
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'RESTAURANT',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'EMPLOYEE PAYSLIP',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 25,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Salary statement',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 25),
            pw.Text(
              'EMPLOYEE INFORMATION',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.Divider(color: PdfColors.green800),
            detailRow('Employee Name', employeeName),
            detailRow('Employee/User ID', userId),
            detailRow('Payroll Month', month),
            detailRow('Payslip ID', _text(slip['id'])),
            pw.SizedBox(height: 25),
            pw.Text(
              'EARNINGS AND DEDUCTIONS',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.Divider(color: PdfColors.green800),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    _pdfCell('Description', bold: true),
                    _pdfCell('Amount', bold: true, alignRight: true),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfCell('Base Salary'),
                    _pdfCell(
                      _money(baseSalary),
                      alignRight: true,
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfCell('Deductions'),
                    _pdfCell(
                      '- ${_money(deductions)}',
                      alignRight: true,
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                color: PdfColors.green50,
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'NET PAY',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                  pw.Text(
                    _money(netPay),
                    style: pw.TextStyle(
                      fontSize: 19,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green900,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 25),
            pw.Text(
              'PAYMENT INFORMATION',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
            pw.Divider(color: PdfColors.green800),
            detailRow('Payment Status', status),
            detailRow(
              'Generated Date',
              DateFormat('dd MMM yyyy').format(DateTime.now()),
            ),
            pw.SizedBox(height: 45),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 180, child: pw.Divider()),
                    pw.Text(
                      'Employee Signature',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 180, child: pw.Divider()),
                    pw.Text(
                      'Authorized Signature',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Center(
              child: pw.Text(
                'This is a computer-generated payslip.',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
            ),
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Payslip_${userId}_$month.pdf',
      );
    } catch (e) {
      _showMessage('Could not create PDF: $e', error: true);
    }
  }

  pw.Widget _pdfCell(
    String value, {
    bool bold = false,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Align(
        alignment:
            alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight:
                bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------
  // SCREEN
  // -------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Payslip Records',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh payslips',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPayslips,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPayslips,
        child: FutureBuilder<List<dynamic>>(
          future: _payslipsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 150),
                  const Icon(
                    Icons.error_outline,
                    size: 55,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text('Unable to load payslips.'),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _refreshPayslips,
                      child: const Text('Try Again'),
                    ),
                  ),
                ],
              );
            }

            final payslips = snapshot.data ?? [];

            if (payslips.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(
                    Icons.receipt_long,
                    size: 65,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 15),
                  Center(
                    child: Text(
                      'No payslips found.',
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: payslips.length,
              itemBuilder: (context, index) {
                final slip = Map<String, dynamic>.from(
                  payslips[index] as Map,
                );

                return _buildPayslipCard(slip);
              },
            );
          },
        ),
      ),
      floatingActionButton: _isManager
          ? FloatingActionButton.extended(
              onPressed: _isGenerating ? null : _showGenerateDialog,
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              icon: _isGenerating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.add),
              label: Text(
                _isGenerating ? 'Generating...' : 'Generate Payslip',
              ),
            )
          : null,
    );
  }

  // -------------------------------------------------------
  // PAYSLIP CARD
  // -------------------------------------------------------

  Widget _buildPayslipCard(Map<String, dynamic> slip) {
    final isPaid =
        _text(slip['status'], 'pending').toLowerCase() == 'paid';

    final payslipId = _integer(slip['id']);
    final isPaying =
        payslipId != null && _payingIds.contains(payslipId);

    final employeeName =
        _text(slip['employee_name'], 'Unknown Employee');

    final baseSalary = _number(slip['base_salary']);
    final deductions = _number(slip['deductions']);
    final netPay = slip['net_pay'] == null
        ? baseSalary - deductions
        : _number(slip['net_pay']);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green.shade50,
                  child: Icon(
                    Icons.person,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employeeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        'Payslip #${_text(slip['id'])} • User ID: ${_text(slip['user_id'])}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? Colors.green.shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPaid ? 'PAID' : 'PENDING',
                    style: TextStyle(
                      color: isPaid
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            _buildInfoRow('Payroll Month', _text(slip['month'])),
            _buildInfoRow('Base Salary', _money(baseSalary)),
            _buildInfoRow(
              'Deductions',
              '- ${_money(deductions)}',
              valueColor: Colors.red.shade700,
            ),
            const Divider(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Net Pay',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _money(netPay),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 21,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _downloadPayslip(slip),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
                if (_isManager && !isPaid)
                  ElevatedButton.icon(
                    onPressed: isPaying
                        ? null
                        : () => _confirmPayment(slip),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    icon: isPaying
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(isPaying ? 'Updating...' : 'Mark as Paid'),
                  ),
                if (isPaid)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.green),
                      SizedBox(width: 5),
                      Text(
                        'Payment Successful',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
