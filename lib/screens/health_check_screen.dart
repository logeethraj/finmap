import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HealthCheckScreen extends StatefulWidget {
  const HealthCheckScreen({super.key});

  @override
  State<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends State<HealthCheckScreen> {
  final _supabase = Supabase.instance.client;
  double _monthlyExpenses = 0;
  double _monthlyIncome = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final transactions = await _supabase.from('transactions').select();
    double income = 0, expenses = 0;
    for (final t in transactions) {
      if (t['type'] == 'income') income += (t['amount'] as num);
      if (t['type'] == 'expense') expenses += (t['amount'] as num);
    }
    setState(() {
      _monthlyIncome = income;
      _monthlyExpenses = expenses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final emergencyFundNeeded = _monthlyExpenses * 6;
    final emergencyFundProgress = emergencyFundNeeded > 0 ? (_monthlyIncome / emergencyFundNeeded).clamp(0.0, 1.0) : 0.0;
    final savingsRate = _monthlyIncome > 0 ? ((_monthlyIncome - _monthlyExpenses) / _monthlyIncome * 100) : 0.0;
    final termInsuranceNeeded = _monthlyIncome * 12 * 10;
    final healthInsuranceOk = _monthlyIncome > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Check'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Financial Health Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _healthCard(
                  icon: Icons.savings,
                  title: 'Emergency Fund',
                  subtitle: '6 months of expenses = ₹${emergencyFundNeeded.toStringAsFixed(0)}',
                  progress: emergencyFundProgress,
                  tip: emergencyFundProgress < 1
                      ? 'You need ₹${(emergencyFundNeeded - _monthlyIncome).toStringAsFixed(0)} more in emergency fund'
                      : 'Emergency fund is sufficient ✅',
                  isOk: emergencyFundProgress >= 1,
                ),
                const SizedBox(height: 12),
                _healthCard(
                  icon: Icons.health_and_safety,
                  title: 'Health Insurance',
                  subtitle: 'Recommended: ₹5L minimum coverage',
                  progress: healthInsuranceOk ? 0.7 : 0.0,
                  tip: 'Ensure you have at least ₹5L health insurance for your family',
                  isOk: healthInsuranceOk,
                ),
                const SizedBox(height: 12),
                _healthCard(
                  icon: Icons.shield,
                  title: 'Term Insurance',
                  subtitle: 'Recommended: ₹${termInsuranceNeeded.toStringAsFixed(0)} (10x annual income)',
                  progress: termInsuranceNeeded > 0 ? 0.5 : 0.0,
                  tip: 'Get term insurance worth 10x your annual income',
                  isOk: false,
                ),
                const SizedBox(height: 12),
                _healthCard(
                  icon: Icons.trending_up,
                  title: 'Savings Rate',
                  subtitle: 'Current: ${savingsRate.toStringAsFixed(0)}% (Target: 20%+)',
                  progress: (savingsRate / 100).clamp(0.0, 1.0),
                  tip: savingsRate < 20
                      ? 'Try to save at least 20% of your income'
                      : 'Great savings rate! Keep it up ✅',
                  isOk: savingsRate >= 20,
                ),
              ],
            ),
    );
  }

  Widget _healthCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required double progress,
    required String tip,
    required bool isOk,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isOk ? Colors.green : Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Icon(isOk ? Icons.check_circle : Icons.warning,
                    color: isOk ? Colors.green : Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: isOk ? Colors.green : Colors.orange,
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text(tip, style: TextStyle(color: isOk ? Colors.green : Colors.orange, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}