import 'package:flutter/material.dart';
import 'package:myrestro/services/api_services.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _apiService.getMyProfile().then((v) => setState(() => _profile = v));
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(radius: 40, child: Text(_profile!['full_name'][0])),
          const SizedBox(height: 10),
          Center(child: Text(_profile!['full_name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          ListTile(leading: const Icon(Icons.email), title: Text(_profile!['email'])),
          ListTile(leading: const Icon(Icons.work), title: Text(_profile!['role'].toUpperCase())),
        ],
      ),
    );
  }
}