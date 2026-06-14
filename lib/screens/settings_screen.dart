import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabase = Supabase.instance.client;
  String _selectedCurrency = 'INR';
  bool _darkMode = false;
  bool _biometric = false;

  final List<String> _currencies = ['INR', 'USD', 'EUR', 'GBP', 'AED', 'SGD'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('currency') ?? 'INR';
      _darkMode = prefs.getBool('darkMode') ?? false;
      _biometric = prefs.getBool('biometric') ?? false;
    });
  }

  Future<void> _saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currency);
    setState(() => _selectedCurrency = currency);
  }

  Future<void> _saveTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    setState(() => _darkMode = value);
  }

  Future<void> _saveBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric', value);
    setState(() => _biometric = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Biometric lock enabled' : 'Biometric lock disabled'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _exportData() async {
    final assets = await _supabase.from('assets').select();
    final liabilities = await _supabase.from('liabilities').select();
    final transactions = await _supabase.from('transactions').select();
    final goals = await _supabase.from('goals').select();
    final snapshots = await _supabase.from('snapshots').select();

    final exportData = {
      'exported_at': DateTime.now().toIso8601String(),
      'assets': assets,
      'liabilities': liabilities,
      'transactions': transactions,
      'goals': goals,
      'snapshots': snapshots,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Your Data Export'),
          content: SingleChildScrollView(
            child: Text(jsonString,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(user?.email ?? 'User'),
            subtitle: const Text('Logged in'),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('PREFERENCES', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ListTile(
            leading: const Icon(Icons.currency_rupee, color: Colors.green),
            title: const Text('Base Currency'),
            trailing: DropdownButton<String>(
              value: _selectedCurrency,
              underline: const SizedBox(),
              items: _currencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => _saveCurrency(v!),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode, color: Colors.green),
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: _darkMode,
              activeColor: Colors.green,
              onChanged: _saveTheme,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint, color: Colors.green),
            title: const Text('Biometric Lock'),
            subtitle: const Text('Use fingerprint to unlock app'),
            trailing: Switch(
              value: _biometric,
              activeColor: Colors.green,
              onChanged: _saveBiometric,
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('DATA', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.green),
            title: const Text('Export My Data'),
            subtitle: const Text('Download all your data as JSON'),
            onTap: _exportData,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('ACCOUNT', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async => await _supabase.auth.signOut(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                      'This will permanently delete all your assets, transactions, goals and account data. This cannot be undone.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () async {
                        final userId = _supabase.auth.currentUser!.id;
                        await _supabase.from('assets').delete().eq('user_id', userId);
                        await _supabase.from('liabilities').delete().eq('user_id', userId);
                        await _supabase.from('transactions').delete().eq('user_id', userId);
                        await _supabase.from('goals').delete().eq('user_id', userId);
                        await _supabase.from('snapshots').delete().eq('user_id', userId);
                        await _supabase.auth.signOut();
                        if (mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Delete Everything',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}