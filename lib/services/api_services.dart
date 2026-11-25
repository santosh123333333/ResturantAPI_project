import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, or your PC's IP (e.g., 192.168.1.78) for real phones
  static const String baseUrl = 'https://myrestrofastapi.onrender.com'; 

  // ==========================================
  // 1. AUTHENTICATION
  // ==========================================
  Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', jsonDecode(response.body)['access_token']);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<Map<String, dynamic>> getMyProfile() async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.get(
      Uri.parse('$baseUrl/employee/me'), 
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load profile');
  }

  Future<void> registerStaff(String name, String email, String password, String role, String position, double salary) async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'full_name': name, 
        'email': email, 
        'password': password, 
        'role': role, 
        'position': position, 
        'salary': salary
      }),
    );
    if (response.statusCode != 201) throw Exception('Failed to register staff');
  }

  // ==========================================
  // 2. FINANCIALS
  // ==========================================
  Future<Map<String, dynamic>> getFinancialSummary(String period) async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.get(
      Uri.parse('$baseUrl/finance/summary?period=$period'), 
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load summary');
  }

  Future<List<dynamic>> getChartData() async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.get(
      Uri.parse('$baseUrl/finance/chart-data'), 
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load chart data');
  }

  Future<List<dynamic>> getTransactions(String period) async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.get(
      Uri.parse('$baseUrl/finance/transactions?period=$period'), 
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load transactions');
  }

  Future<void> addTransaction(String type, String category, double amount, String description) async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.post(
      Uri.parse('$baseUrl/finance/transactions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'type': type, 
        'category': category, 
        'amount': amount, 
        'description': description
      }),
    );
    if (response.statusCode != 201) throw Exception('Failed to add transaction');
  }

  // ==========================================
  // 3. INVENTORY & WASTAGE
  // ==========================================
  Future<List<dynamic>> getInventory({String? search}) async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    String url = '$baseUrl/inventory/';
    if (search != null && search.isNotEmpty) url += '?search=$search';
    
    final response = await http.get(
      Uri.parse(url), 
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load inventory');
  }

  Future<void> addInventoryItem(String name, double qty, String unit, double cost) async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.post(
      Uri.parse('$baseUrl/inventory/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'item_name': name, 
        'quantity': qty, 
        'unit': unit, 
        'cost_per_unit': cost
      }),
    );
    if (response.statusCode != 201) throw Exception('Failed to add item');
  }

  Future<void> updateInventoryItem(int id, String name, double qty, String unit, double cost) async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.put(
      Uri.parse('$baseUrl/inventory/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'item_name': name,
        'quantity': qty,
        'unit': unit,
        'cost_per_unit': cost,
      }),
    );
    if (response.statusCode != 200) throw Exception('Failed to update item');
  }

  Future<void> recordWastage(int itemId, double quantity, String reason) async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.post(
      Uri.parse('$baseUrl/inventory/wastage'),
      headers: {
        'Authorization': 'Bearer $token', 
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'item_id': itemId, 
        'quantity': quantity, 
        'reason': reason
      }),
    );
    if (response.statusCode != 201) throw Exception('Failed to record wastage');
  }

  // ==========================================
  // 4. STAFF MANAGEMENT
  // ==========================================
  Future<List<dynamic>> getStaff() async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.get(
      Uri.parse('$baseUrl/manager/users'), 
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load staff');
  }

  // NEW: Update Staff
  Future<void> updateStaff(int id, String name, String role, String position, double salary) async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.put(
      Uri.parse('$baseUrl/manager/users/$id'),
      headers: {
        'Authorization': 'Bearer $token', 
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'full_name': name, 
        'role': role, 
        'position': position, 
        'salary': salary
      }),
    );
    if (response.statusCode != 200) throw Exception('Failed to update staff');
  }

  // NEW: Delete Staff
  Future<void> deleteStaff(int id) async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.delete(
      Uri.parse('$baseUrl/manager/users/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Failed to delete staff');
  }

  // ==========================================
  // 5. PAYSLIPS
  // ==========================================
  Future<List<dynamic>> getMyPayslips() async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.get(
      Uri.parse('$baseUrl/employee/my-payslips'), 
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load payslips');
  }

  Future<List<dynamic>> getAllPayslips() async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.get(
      Uri.parse('$baseUrl/manager/payslips'), 
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load all payslips');
  }

  Future<void> generatePayslip(int userId, String month, double baseSalary, double deductions) async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.post(
      Uri.parse('$baseUrl/manager/payslips'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'month': month,
        'base_salary': baseSalary,
        'deductions': deductions,
      }),
    );
    if (response.statusCode != 201) throw Exception('Failed to generate payslip');
  }

  Future<void> markPayslipAsPaid(int payslipId) async {
    final token = (await SharedPreferences.getInstance()).getString('jwt_token');
    final response = await http.put(
      Uri.parse('$baseUrl/manager/payslips/$payslipId/pay'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark payslip as paid');
    }
  }
}