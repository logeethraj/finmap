import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'assets_screen.dart';
import 'transactions_screen.dart';
import 'goals_screen.dart';
import 'settings_screen.dart';
import 'liabilities_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final _supabase = Supabase.instance.client;
  double _totalAssets = 0;
  double _totalLiabilities = 0;

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  Future<void> _loadTotals() async {
    final assets = await _supabase.from('assets').select('amount');
    final liabilities = await _supabase.from('liabilities').select('amount');
    final totalAssets = (assets as List).fold(0.0, (sum, a) => sum + (a['amount'] as num));
    final totalLiabilities = (liabilities as List).fold(0.0, (sum, l) => sum + (l['amount'] as num));
    setState(() {
      _totalAssets = totalAssets;
      _totalLiabilities = totalLiabilities;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _homeTab(),
      AssetsScreen(),
      LiabilitiesScreen(),
      TransactionsScreen(),
      GoalsScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 0) _loadTotals();
        },
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Assets'),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Liabilities'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_vert), label: 'Transactions'),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _homeTab() {
    final user = _supabase.auth.currentUser;
    final netWorth = _totalAssets - _totalLiabilities;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finmap'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${user?.email ?? 'User'}!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: netWorth >= 0 ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Net Worth', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('₹${netWorth.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _summaryCard('Total Assets', '₹${_totalAssets.toStringAsFixed(0)}', Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _summaryCard('Total Liabilities', '₹${_totalLiabilities.toStringAsFixed(0)}', Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}