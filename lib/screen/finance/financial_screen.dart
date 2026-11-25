import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myrestro/screen/finance/widget/line_chart_widget.dart';
import 'package:myrestro/screen/finance/widget/pie_chart_widget.dart';
import 'package:myrestro/screen/finance/widget/sales_chart.dart';
import 'package:myrestro/services/api_services.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({super.key});
  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  final ApiService _apiService = ApiService();
  final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
  
  String _period = 'daily';
  Map<String, dynamic>? _summary;
  List<dynamic> _chartData = [];
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() { 
    super.initState(); 
    _loadAllData(); 
  }

  void _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final sum = await _apiService.getFinancialSummary(_period);
      final chart = await _apiService.getChartData();
      final txs = await _apiService.getTransactions(_period);
      
      setState(() { 
        _summary = sum; 
        _chartData = chart; 
        _transactions = txs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddTransactionDialog() {
    String type = 'sale';
    final catController = TextEditingController();
    final amtController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  items: ['sale', 'expense'].map((t) {
                    return DropdownMenuItem(
                      value: t, 
                      child: Text(t.toUpperCase(), style: TextStyle(color: t == 'sale' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                  onChanged: (v) => setDialogState(() => type = v!),
                  decoration: const InputDecoration(labelText: 'Transaction Type', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: catController, 
                  decoration: const InputDecoration(labelText: 'Category (e.g., Food, Groceries)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amtController, 
                  keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                  decoration: const InputDecoration(labelText: 'Amount (Rs.)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController, 
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              onPressed: () async {
                if (amtController.text.isEmpty || catController.text.isEmpty) return;
                try {
                  await _apiService.addTransaction(
                    type, 
                    catController.text.trim(), 
                    double.parse(amtController.text.trim()), 
                    descController.text.trim()
                  );
                  if (mounted) Navigator.pop(context);
                  _loadAllData();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction Added!'), backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Financials', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async => _loadAllData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['daily', 'weekly', 'monthly', 'yearly'].map((p) => ChoiceChip(
                      label: Text(p.toUpperCase()), 
                      selected: _period == p,
                      onSelected: (v) { setState(() => _period = p); _loadAllData(); },
                    )).toList(),
                  ),
                  const SizedBox(height: 20),

                  if (_summary != null) ...[
                    Row(
                      children: [
                        Expanded(child: _buildMetricCard('Total Sales', _summary!['total_sales'], Colors.green)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildMetricCard('Total Expenses', _summary!['total_expenses'], Colors.redAccent)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildMetricCard('Net Profit', _summary!['net_profit'], Colors.blue, isLarge: true),
                  ],
                  
                  const SizedBox(height: 30),

                  const Text('Last 7 Days Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SalesChart(chartData: _chartData),
                  const SizedBox(height: 20),
                  SalesLineChart(chartData: _chartData),
                  const SizedBox(height: 20),
                  if (_summary != null) 
                    ExpensesPieChart(
                      sales: _summary!['total_sales'].toDouble(), 
                      expenses: _summary!['total_expenses'].toDouble()
                    ),
                  
                  const SizedBox(height: 30),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Transaction Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 10),
                  _transactions.isEmpty 
                    ? const Text("No transactions found for this period.")
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final txn = _transactions[index];
                          final isSale = txn['type'] == 'sale';
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSale ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                child: Icon(isSale ? Icons.arrow_downward : Icons.arrow_upward, color: isSale ? Colors.green : Colors.red),
                              ),
                              title: Text(txn['category'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${txn['description']} \nBy: ${txn['creator_name'] ?? 'System'}'),
                              trailing: Text(
                                '${isSale ? '+' : '-'}${currencyFormat.format(txn['amount'])}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: isSale ? Colors.green : Colors.red),
                              ),
                            ),
                          );
                        },
                      ),
                ],
              ),
            ),
          ),
          
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionDialog(),
        backgroundColor: Colors.blueAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMetricCard(String title, num amount, Color color, {bool isLarge = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isLarge ? color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isLarge ? Colors.white70 : Colors.grey)),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(fontSize: isLarge ? 28 : 20, fontWeight: FontWeight.bold, color: isLarge ? Colors.white : Colors.black87),
          ),
        ],
      ),
    );
  }
}