import 'package:flutter/material.dart';
import 'package:myrestro/screen/payslip/paysleep_screen.dart';
import 'package:myrestro/services/api_services.dart';
import 'login_screen.dart';
import 'finance/financial_screen.dart';
import 'inventory/inventory_screen.dart';
import 'staff/staff_screen.dart';
import 'profile/profile_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  String _role = 'loading';
  String _name = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    try {
      final profile = await _apiService.getMyProfile();
      setState(() {
        _role = profile['role'];
        _name = profile['full_name'];
      });
    } catch (e) {
      setState(() => _role = 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while fetching user role
    if (_role == 'loading') {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    bool isAdminOrManager = _role == 'admin' || _role == 'manager';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Welcome, $_name', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'My Profile',
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const ProfileScreen())
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _apiService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (context) => const LoginScreen()), 
                  (route) => false
                );
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: [
            // --- ADMIN & MANAGER VIEW ---
            if (isAdminOrManager) ...[
              _buildNavCard(
                context, 'Financials', Icons.pie_chart, Colors.blueAccent, 
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FinancialScreen()))
              ),
              _buildNavCard(
                context, 'Inventory', Icons.inventory, Colors.orangeAccent, 
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen()))
              ),
              _buildNavCard(
                context, 'Staff', Icons.people, Colors.purpleAccent, 
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StaffScreen()))
              ),
              
              // Payroll Card (Admin/Manager)
              _buildNavCard(
                context, 'Payroll', Icons.receipt_long, Colors.green, 
                () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => PayslipScreen(role: _role))
                )
              ),
            ] 
            
            // --- EMPLOYEE VIEW ---
            else ...[
              // Employees only see their own payslips
              _buildNavCard(
                context, 'My Payslips', Icons.receipt_long, Colors.green, 
                () => Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => PayslipScreen(role: _role))
                )
              ),
            ],
            
            // Both roles can see My Profile
            _buildNavCard(
              context, 'My Profile', Icons.person, Colors.teal, 
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the navigation cards
  Widget _buildNavCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15), // Updated to withValues to fix deprecation warning
              blurRadius: 10,
              offset: const Offset(0, 5)
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}