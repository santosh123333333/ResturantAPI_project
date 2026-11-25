import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myrestro/services/api_services.dart';
import 'wastage_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _inventoryFuture;
  final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  void _loadInventory() {
    setState(() {
      _inventoryFuture = _apiService.getInventory(
        search: _searchController.text.trim(),
      );
    });
  }

  void _showUpdateDialog(Map<String, dynamic> item) {
    final qtyController = TextEditingController(
      text: item['quantity'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update ${item['item_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: qtyController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'New Quantity',
            suffixText: item['unit'],
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
            onPressed: () async {
              try {
                final newQty = double.parse(qtyController.text.trim());
                await _apiService.updateInventoryItem(
                  item['id'],
                  item['item_name'],
                  newQty,
                  item['unit'],
                  item['cost_per_unit'].toDouble(),
                );
                if (mounted) Navigator.pop(context);
                _loadInventory();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock Updated!'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final unitController = TextEditingController();
    final costController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Inventory Item', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController, 
                decoration: const InputDecoration(labelText: 'Item Name (e.g., Butter)', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController, 
                keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitController, 
                decoration: const InputDecoration(labelText: 'Unit (kg, liters, pieces)', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextField(
                controller: costController, 
                keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                decoration: const InputDecoration(labelText: 'Cost Per Unit (Rs.)', border: OutlineInputBorder())
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white),
            onPressed: () async {
              if (nameController.text.isEmpty || qtyController.text.isEmpty || costController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                return;
              }
              try {
                await _apiService.addInventoryItem(
                  nameController.text.trim(),
                  double.parse(qtyController.text.trim()),
                  unitController.text.trim(),
                  double.parse(costController.text.trim()),
                );
                if (mounted) Navigator.pop(context);
                _loadInventory();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item Added Successfully!'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Inventory Table', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orangeAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInventory),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Record Wastage',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WastageScreen()),
              ).then((_) => _loadInventory()); 
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search item...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _loadInventory),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _loadInventory(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _inventoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

                final items = snapshot.data!;
                if (items.isEmpty) return const Center(child: Text('No items found.'));

                return SingleChildScrollView(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.orange.shade100),
                      columnSpacing: 15,
                      columns: const [
                        DataColumn(label: Text('Item', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Wasted', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Value', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Edit', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: items.map<DataRow>((item) {
                        final wasted = item['total_wasted'] ?? 0;
                        final totalValue = item['quantity'] * item['cost_per_unit'];

                        return DataRow(
                          cells: [
                            DataCell(Text(item['item_name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataCell(Text('${item['quantity']} ${item['unit']}')),
                            DataCell(Text('$wasted ${item['unit']}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                            DataCell(Text(currencyFormat.format(totalValue), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                            DataCell(IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showUpdateDialog(item))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(),
        backgroundColor: Colors.orangeAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}