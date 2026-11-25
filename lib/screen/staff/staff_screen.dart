import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_services.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _staffFuture;
  final currencyFormat = NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  void _loadStaff() {
    setState(() {
      _staffFuture = _apiService.getStaff();
    });
  }

  // --- 1. ADD EMPLOYEE DIALOG ---
  void _showRegisterDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final posController = TextEditingController();
    final salaryController = TextEditingController();
    String role = 'employee';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Register Employee', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: passController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  items: ['employee', 'manager', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                  onChanged: (v) => setDialogState(() => role = v!),
                  decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(controller: posController, decoration: const InputDecoration(labelText: 'Position (e.g., Chef)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: salaryController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Salary (Rs.)', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, foregroundColor: Colors.white),
              onPressed: () async {
                if (emailController.text.isEmpty || passController.text.isEmpty || nameController.text.isEmpty) return;
                try {
                  await _apiService.registerStaff(
                    nameController.text.trim(), emailController.text.trim(), passController.text.trim(), role, 
                    posController.text.trim(), double.parse(salaryController.text.trim().isEmpty ? '0' : salaryController.text.trim())
                  );
                  if (mounted) Navigator.pop(context);
                  _loadStaff();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee Registered!'), backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. EDIT EMPLOYEE DIALOG ---
  void _showEditDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['full_name']);
    final posController = TextEditingController(text: user['position'] ?? '');
    final salaryController = TextEditingController(text: user['salary']?.toString() ?? '0');
    String role = user['role'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Employee', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  items: ['employee', 'manager', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                  onChanged: (v) => setDialogState(() => role = v!),
                  decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(controller: posController, decoration: const InputDecoration(labelText: 'Position', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: salaryController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Salary (Rs.)', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
              onPressed: () async {
                await _apiService.updateStaff(user['id'], nameController.text.trim(), role, posController.text.trim(), double.parse(salaryController.text.trim()));
                if (mounted) Navigator.pop(context);
                _loadStaff();
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
        title: const Text('Staff Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purpleAccent,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStaff)],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _staffFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));

          final staff = snapshot.data!;
          if (staff.isEmpty) return const Center(child: Text('No staff found.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: staff.length,
            itemBuilder: (context, index) {
              final user = staff[index];
              final isAdmin = user['role'] == 'admin';
              final isManager = user['role'] == 'manager';
              Color roleColor = isAdmin ? Colors.red : (isManager ? Colors.orange : Colors.blue);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  onTap: () => _showEditDialog(user), // Tap to edit
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: roleColor.withValues(alpha: 0.1),
                    child: Text(user['full_name'][0].toUpperCase(), style: TextStyle(color: roleColor, fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                  title: Text(user['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(user['email'], style: const TextStyle(color: Colors.grey)),
                      Text('${user['position'] ?? 'Staff'} • ${currencyFormat.format(user['salary'] ?? 0)}/mo'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Employee?'),
                          content: Text('Delete ${user['full_name']}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(context, true), 
                              child: const Text('Delete', style: TextStyle(color: Colors.white))
                            ),
                          ],
                        ),
                      ) ?? false;

                      if (confirm) {
                        await _apiService.deleteStaff(user['id']);
                        _loadStaff();
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRegisterDialog(), // NOW IT OPENS THE FORM
        backgroundColor: Colors.purpleAccent,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Employee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}