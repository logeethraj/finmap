import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final _supabase = Supabase.instance.client;
  String _currentPlan = 'free';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    final userId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    setState(() {
      _currentPlan = data?['plan'] ?? 'free';
      _isLoading = false;
    });
  }

  Future<void> _upgradeTo(String plan) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('subscriptions').upsert({
      'user_id': userId,
      'plan': plan,
      'updated_at': DateTime.now().toIso8601String(),
    });

    setState(() => _currentPlan = plan);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upgraded to ${plan == 'pro_yearly' ? 'Pro Yearly' : 'Lifetime'}! Synced across all devices ✅'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium, size: 64, color: Colors.purple),
                  const SizedBox(height: 8),
                  const Text('Finmap Pro', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text('Unlock your full financial potential', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sync, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Current Plan: ${_planName(_currentPlan)} • Synced',
                          style: const TextStyle(color: Colors.green, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _planCard(
                    title: 'Free',
                    price: '₹0',
                    period: 'forever',
                    color: Colors.grey,
                    planKey: 'free',
                    features: [
                      '25 assets',
                      '5 liabilities',
                      '3 goals',
                      '2 snapshots/month',
                      'Basic dashboard',
                      'Income & expense tracking',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _planCard(
                    title: 'Pro Yearly',
                    price: '₹999',
                    period: 'per year',
                    color: Colors.purple,
                    planKey: 'pro_yearly',
                    features: [
                      'Unlimited assets',
                      'Unlimited liabilities',
                      'Unlimited goals',
                      'Unlimited snapshots',
                      'Advanced charts',
                      'CSV/JSON export',
                      'Family profiles',
                      'Priority support',
                    ],
                  ),
                  const SizedBox(height: 16),
                  _planCard(
                    title: 'Lifetime',
                    price: '₹2499',
                    period: 'one time',
                    color: Colors.orange,
                    planKey: 'lifetime',
                    features: [
                      'Everything in Pro',
                      'Lifetime access',
                      'All future features',
                      'Early access to new features',
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.security, color: Colors.green),
                        SizedBox(height: 8),
                        Text('100% Secure Payment via UPI/Google Pay',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey)),
                        Text('Cancel anytime • No hidden charges',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _planName(String plan) {
    switch (plan) {
      case 'pro_yearly': return 'Pro Yearly';
      case 'lifetime': return 'Lifetime';
      default: return 'Free';
    }
  }

  Widget _planCard({
    required String title,
    required String price,
    required String period,
    required Color color,
    required String planKey,
    required List<String> features,
  }) {
    final isCurrent = _currentPlan == planKey;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: isCurrent ? 1 : 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              if (!isCurrent)
                ElevatedButton(
                  onPressed: () => _upgradeTo(planKey),
                  style: ElevatedButton.styleFrom(backgroundColor: color),
                  child: const Text('Upgrade', style: TextStyle(color: Colors.white)),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Current Plan', style: TextStyle(color: Colors.grey)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: price, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
                TextSpan(text: ' / $period', style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(f),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}