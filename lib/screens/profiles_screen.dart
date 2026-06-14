import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/currency_service.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _profiles = [];
  double _myNetWorth = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profiles = await _supabase
        .from('profiles')
        .select()
        .order('created_at', ascending: true);

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
      _profiles = List<Map<String, dynamic>>.from(profiles);
      _myNetWorth = totalAssets - totalLiabilities;
      _isLoading = false;
    });
  }

  Future<void> _deleteProfile(String id) async {
    await _supabase.from('profiles').delete().eq('id', id);
    _loadData();
  }

  void _showAddProfileDialog() {
    final nameController = TextEditingController();
    final assetsController = TextEditingController();
    final liabilitiesController = TextEditingController();
    String selectedType = 'Spouse';
    final types = ['Spouse', 'Business', 'Child', 'Parent', 'Other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Profile Name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: assetsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Their Total Assets (₹)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: liabilitiesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Their Total Liabilities (₹)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _supabase.from('profiles').insert({
                  'owner_id': _supabase.auth.currentUser!.id,
                  'name': nameController.text,
                  'type': selectedType,
                  'total_assets': double.tryParse(assetsController.text) ?? 0,
                  'total_liabilities': double.tryParse(liabilitiesController.text) ?? 0,
                });
                if (mounted) Navigator.pop(context);
                _loadData();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareDialog() {
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
              child: Text(
                'finmap.app/share/${_supabase.auth.currentUser!.id.substring(0, 8)}',
                style: const TextStyle(fontFamily: 'monospace', color: Colors.blue),
              ),
            ),
            const SizedBox(height: 8),
            const Text('View-only access • Expires in 7 days',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share link copied! ✅')),
              );
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
    double profilesNetWorth = 0;
    for (final p in _profiles) {
      final pAssets = (p['total_assets'] as num?) ?? 0;
      final pLiabilities = (p['total_liabilities'] as num?) ?? 0;
      profilesNetWorth += (pAssets - pLiabilities);
    }
    final consolidatedTotal = _myNetWorth + profilesNetWorth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Profiles'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _showShareDialog,
            tooltip: 'Share Dashboard',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProfileDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.teal,
                  child: Column(
                    children: [
                      const Text('Consolidated Family Wealth',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text('₹${consolidatedTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('You: ₹${_myNetWorth.toStringAsFixed(0)} + ${_profiles.length} profile(s): ₹${profilesNetWorth.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.teal.shade50,
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.teal, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Add family/business profiles with their assets and liabilities for combined net worth.',
                          style: TextStyle(color: Colors.teal, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _profiles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text('No profiles yet.'),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _showAddProfileDialog,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                child: const Text('Add First Profile',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _profiles.length,
                          itemBuilder: (context, index) {
                            final profile = _profiles[index];
                            final pAssets = (profile['total_assets'] as num?) ?? 0;
                            final pLiabilities = (profile['total_liabilities'] as num?) ?? 0;
                            final pNetWorth = pAssets - pLiabilities;
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.teal,
                                  child: Text(
                                    profile['name'][0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(profile['name']),
                                subtitle: Text(
                                    '${profile['type']} • Assets ₹${pAssets.toStringAsFixed(0)} - Liabilities ₹${pLiabilities.toStringAsFixed(0)}'),
                                trailing: SizedBox(
                                  height: 60,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('₹${pNetWorth.toStringAsFixed(0)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold)),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () => _deleteProfile(profile['id']),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}