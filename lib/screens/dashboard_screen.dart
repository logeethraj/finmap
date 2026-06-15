import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'assets_screen.dart';
import 'transactions_screen.dart';
import 'goals_screen.dart';
import 'settings_screen.dart';
import 'liabilities_screen.dart';
import 'health_check_screen.dart';
import 'snapshots_screen.dart';
import 'pricing_screen.dart';
import 'profiles_screen.dart';
import '../services/currency_service.dart';
import '../main.dart';

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
    final assets = await _supabase.from('assets').select('amount, currency');
    final liabilities = await _supabase.from('liabilities').select('amount');

    double totalAssets = 0;
    for (final a in assets) {
      final amount = (a['amount'] as num).toDouble();
      final currency = a['currency'] ?? 'INR';
      totalAssets += await CurrencyService.convertToINR(amount, currency);
    }

    final totalLiabilities = (liabilities as List).fold(0.0, (sum, l) => sum + (l['amount'] as num));
    setState(() {
      _totalAssets = totalAssets;
      _totalLiabilities = totalLiabilities;
    });
  }

  void _showShareDialog() {
    final link = 'finmap.app/share/${_supabase.auth.currentUser!.id.substring(0, 8)}';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Dashboard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.share, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            const Text('Share your financial dashboard with your CA or family member.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(link,
                  style: const TextStyle(fontFamily: 'monospace', color: Colors.blue)),
            ),
            const SizedBox(height: 8),
            const Text('View-only access • Expires in 7 days',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: link));
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard! ✅')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Copy Link', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _homeTab(),
      AssetsScreen(),
      LiabilitiesScreen(),
      TransactionsScreen(),
      GoalsScreen(),
      SnapshotsScreen(),
      HealthCheckScreen(),
      ProfilesScreen(),
      PricingScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Snapshots'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Health'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Family'),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'Pro'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _homeTab() {
    final user = _supabase.auth.currentUser;
    final netWorthINR = _totalAssets - _totalLiabilities;

    return ValueListenableBuilder<String>(
      valueListenable: currencyNotifier,
      builder: (context, currency, _) {
        return FutureBuilder<List<double>>(
          future: Future.wait([
            CurrencyService.convertFromINR(_totalAssets, currency),
            CurrencyService.convertFromINR(_totalLiabilities, currency),
            CurrencyService.convertFromINR(netWorthINR, currency),
          ]),
          builder: (context, snapshot) {
            final totalAssets = snapshot.data?[0] ?? _totalAssets;
            final totalLiabilities = snapshot.data?[1] ?? _totalLiabilities;
            final netWorth = snapshot.data?[2] ?? netWorthINR;
            final symbol = CurrencyService.symbolFor(currency);

            return Scaffold(
              appBar: AppBar(
                title: const Text('Finmap'),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _showShareDialog,
                    tooltip: 'Share Dashboard',
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome, ${user?.email ?? 'User'}!',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.workspace_premium, color: Colors.purple, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('🎉 14-day Pro trial active! Enjoy all features free.',
                                style: TextStyle(color: Colors.purple, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: netWorth >= 0 ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text('Net Worth',
                              style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('$symbol${netWorth.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold)),
                          Text(currency,
                              style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                            child: _summaryCard('Total Assets',
                                '$symbol${totalAssets.toStringAsFixed(0)}', Colors.blue)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _summaryCard('Total Liabilities',
                                '$symbol${totalLiabilities.toStringAsFixed(0)}', Colors.red)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}