import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SnapshotsScreen extends StatefulWidget {
  const SnapshotsScreen({super.key});

  @override
  State<SnapshotsScreen> createState() => _SnapshotsScreenState();
}

class _SnapshotsScreenState extends State<SnapshotsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _snapshots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSnapshots();
  }

  Future<void> _loadSnapshots() async {
    final data = await _supabase
        .from('snapshots')
        .select()
        .order('created_at', ascending: false);
    setState(() {
      _snapshots = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  Future<void> _takeSnapshot() async {
    final assets = await _supabase.from('assets').select('amount');
    final liabilities = await _supabase.from('liabilities').select('amount');
    final totalAssets = (assets as List).fold(0.0, (sum, a) => sum + (a['amount'] as num));
    final totalLiabilities = (liabilities as List).fold(0.0, (sum, l) => sum + (l['amount'] as num));
    final netWorth = totalAssets - totalLiabilities;

    await _supabase.from('snapshots').insert({
      'user_id': _supabase.auth.currentUser!.id,
      'net_worth': netWorth,
      'total_assets': totalAssets,
      'total_liabilities': totalLiabilities,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Snapshot saved! ✅')),
      );
    }
    _loadSnapshots();
  }

  Future<void> _deleteSnapshot(String id) async {
    await _supabase.from('snapshots').delete().eq('id', id);
    _loadSnapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snapshots'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: _takeSnapshot,
            tooltip: 'Take Snapshot',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _snapshots.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No snapshots yet.'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _takeSnapshot,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                        child: const Text('Take First Snapshot', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _snapshots.length,
                  itemBuilder: (context, index) {
                    final snap = _snapshots[index];
                    final netWorth = (snap['net_worth'] as num).toDouble();
                    final prev = index < _snapshots.length - 1
                        ? (_snapshots[index + 1]['net_worth'] as num).toDouble()
                        : netWorth;
                    final change = netWorth - prev;
                    final isPositive = change >= 0;
                    final date = snap['created_at'].toString().substring(0, 10);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _deleteSnapshot(snap['id']),
                                ),
                              ],
                            ),
                            Text('₹${netWorth.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                    color: isPositive ? Colors.green : Colors.red, size: 16),
                                Text(
                                  '₹${change.abs().toStringAsFixed(0)} vs previous',
                                  style: TextStyle(color: isPositive ? Colors.green : Colors.red),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Assets: ₹${(snap['total_assets'] as num).toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.blue, fontSize: 12)),
                                Text('Liabilities: ₹${(snap['total_liabilities'] as num).toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.red, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}