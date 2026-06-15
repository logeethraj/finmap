import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthCheckScreen extends StatefulWidget {
  const HealthCheckScreen({super.key});

  @override
  State<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends State<HealthCheckScreen> {
  final _supabase = Supabase.instance.client;
  double _monthlyExpenses = 0;
  double _monthlyIncome = 0;
  double _healthCoverage = 0;
  double _termCoverage = 0;
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

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _monthlyIncome = income;
      _monthlyExpenses = expenses;
      _healthCoverage = prefs.getDouble('healthCoverage') ?? 0;
      _termCoverage = prefs.getDouble('termCoverage') ?? 0;
      _isLoading = false;
    });
  }

  Future<void> _editCoverage(String key, double current, String title) async {
    final controller = TextEditingController(text: current == 0 ? '' : current.toStringAsFixed(0));
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Current Coverage (₹)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, double.tryParse(controller.text) ?? 0),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, result);
      setState(() {
        if (key == 'healthCoverage') _healthCoverage = result;
        if (key == 'termCoverage') _termCoverage = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergencyFundNeeded = _monthlyExpenses * 6;
    final emergencyFundProgress = emergencyFundNeeded > 0 ? (_monthlyIncome / emergencyFundNeeded).clamp(0.0, 1.0) : 0.0;
    final savingsRate = _monthlyIncome > 0 ? ((_monthlyIncome - _monthlyExpenses) / _monthlyIncome * 100) : 0.0;

    const healthNeeded = 500000.0;
    final healthProgress = (_healthCoverage / healthNeeded).clamp(0.0, 1.0);
    final healthOk = _healthCoverage >= healthNeeded;

    final termNeeded = _monthlyIncome * 12 * 10;
    final termProgress = termNeeded > 0 ? (_termCoverage / termNeeded).clamp(0.0, 1.0) : 0.0;
    final termOk = termNeeded > 0 && _termCoverage >= termNeeded;

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
                  subtitle: _healthCoverage > 0
                      ? 'You have ₹${_healthCoverage.toStringAsFixed(0)} • Recommended ₹${healthNeeded.toStringAsFixed(0)}'
                      : 'Recommended: ₹${healthNeeded.toStringAsFixed(0)} minimum coverage',
                  progress: healthProgress,
                  tip: healthOk
                      ? 'Health insurance coverage is sufficient ✅'
                      : 'You need ₹${(healthNeeded - _healthCoverage).toStringAsFixed(0)} more in health insurance',
                  isOk: healthOk,
                  onEdit: () => _editCoverage('healthCoverage', _healthCoverage, 'My Health Insurance Coverage'),
                ),
                const SizedBox(height: 12),
                _healthCard(
                  icon: Icons.shield,
                  title: 'Term Insurance',
                  subtitle: _termCoverage > 0
                      ? 'You have ₹${_termCoverage.toStringAsFixed(0)} • Recommended ₹${termNeeded.toStringAsFixed(0)}'
                      : 'Recommended: ₹${termNeeded.toStringAsFixed(0)} (10x annual income)',
                  progress: termProgress,
                  tip: termOk
                      ? 'Term insurance coverage is sufficient ✅'
                      : 'You need ₹${(termNeeded - _termCoverage).toStringAsFixed(0)} more in term insurance',
                  isOk: termOk,
                  onEdit: () => _editCoverage('termCoverage', _termCoverage, 'My Term Insurance Coverage'),
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
    VoidCallback? onEdit,
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
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    onPressed: onEdit,
                    tooltip: 'Update my coverage',
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