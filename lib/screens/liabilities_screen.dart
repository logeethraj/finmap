import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiabilitiesScreen extends StatefulWidget {
  const LiabilitiesScreen({super.key});

  @override
  State<LiabilitiesScreen> createState() => _LiabilitiesScreenState();
}

class _LiabilitiesScreenState extends State<LiabilitiesScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _liabilities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiabilities();
  }

  Future<void> _loadLiabilities() async {
    final data = await _supabase
        .from('liabilities')
        .select()
        .order('created_at', ascending: false);
    setState(() {
      _liabilities = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  Future<void> _deleteLiability(String id) async {
    await _supabase.from('liabilities').delete().eq('id', id);
    _loadLiabilities();
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final emiController = TextEditingController();
    final categories = ['Home Loan', 'Car Loan', 'Personal Loan', 'Credit Card', 'Education Loan', 'Other'];
    String selectedCategory = 'Home Loan';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Liability'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setDialogState(() => selectedCategory = v!),
                decoration: const InputDecoration(labelText: 'Type'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name (e.g. SBI Home Loan)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Outstanding Amount (₹)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emiController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monthly EMI (₹)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _supabase.from('liabilities').insert({
                  'user_id': _supabase.auth.currentUser!.id,
                  'name': '${selectedCategory}: ${nameController.text}',
                  'amount': double.parse(amountController.text),
                  'emi': double.tryParse(emiController.text) ?? 0,
                });
                if (mounted) Navigator.pop(context);
                _loadLiabilities();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _liabilities.fold(0.0, (sum, l) => sum + (l['amount'] as num));
    final totalEmi = _liabilities.fold(0.0, (sum, l) => sum + (l['emi'] as num));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liabilities'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.red,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.red.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(children: [
                  const Text('Total Debt', style: TextStyle(color: Colors.red, fontSize: 12)),
                  Text('₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
                Column(children: [
                  const Text('Monthly EMI', style: TextStyle(color: Colors.orange, fontSize: 12)),
                  Text('₹${totalEmi.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.orange, fontSize: 20, fontWeight: FontWeight.bold)),
                ]),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _liabilities.isEmpty
                    ? const Center(child: Text('No liabilities. Tap + to add one.'))
                    : ListView.builder(
                        itemCount: _liabilities.length,
                        itemBuilder: (context, index) {
                          final l = _liabilities[index];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.red,
                              child: Icon(Icons.credit_card, color: Colors.white),
                            ),
                            title: Text(l['name']),
                            subtitle: Text('EMI: ₹${l['emi']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('₹${l['amount']}',
                                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteLiability(l['id']),
                                ),
                              ],
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