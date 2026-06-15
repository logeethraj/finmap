import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import '../services/currency_service.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({super.key});

  @override
  State<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _assets = [];
  bool _isLoading = true;
  double _totalInINR = 0;

  final List<String> _currencies = ['INR', 'USD', 'EUR', 'GBP', 'AED', 'SGD'];

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final data = await _supabase
        .from('assets')
        .select()
        .order('created_at', ascending: false);
    
    double total = 0;
    for (final a in data) {
      final amount = (a['amount'] as num).toDouble();
      final currency = a['currency'] ?? 'INR';
      total += await CurrencyService.convertToINR(amount, currency);
    }

    setState(() {
      _assets = List<Map<String, dynamic>>.from(data);
      _totalInINR = total;
      _isLoading = false;
    });
  }

  Future<void> _deleteAsset(String id) async {
    await _supabase.from('assets').delete().eq('id', id);
    _loadAssets();
  }

  Future<void> _importCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) return;

      final csvString = String.fromCharCodes(bytes);
      final rows = const CsvToListConverter().convert(csvString);

      if (rows.isEmpty) return;

      int imported = 0;
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length >= 3) {
          await _supabase.from('assets').insert({
            'user_id': _supabase.auth.currentUser!.id,
            'name': row[0].toString(),
            'category': row[1].toString(),
            'amount': double.tryParse(row[2].toString()) ?? 0,
            'currency': 'INR',
          });
          imported++;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$imported assets imported successfully! ✅')),
        );
      }
      _loadAssets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importing CSV: $e')),
        );
      }
    }
  }

  void _showAddAssetDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Equity';
    String selectedCurrency = 'INR';
    final categories = ['Equity', 'Mutual Fund', 'Gold', 'Real Estate', 'PPF', 'Crypto', 'Cash', 'Other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Asset'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Asset Name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Amount'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedCurrency,
                      items: _currencies
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedCurrency = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => selectedCategory = v!),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _supabase.from('assets').insert({
                  'user_id': _supabase.auth.currentUser!.id,
                  'name': nameController.text,
                  'amount': double.parse(amountController.text),
                  'category': selectedCategory,
                  'currency': selectedCurrency,
                });
                if (mounted) Navigator.pop(context);
                _loadAssets();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _importCSV,
            tooltip: 'Import CSV',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAssetDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.green.shade50,
                  child: Text(
                    'Total Assets: ₹${_totalInINR.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ),
                Expanded(
                  child: _assets.isEmpty
                      ? const Center(child: Text('No assets yet. Tap + to add one.'))
                      : ListView.builder(
                          itemCount: _assets.length,
                          itemBuilder: (context, index) {
                            final asset = _assets[index];
                            final currency = asset['currency'] ?? 'INR';
                            return ListTile(
                              leading: const CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Icon(Icons.account_balance_wallet,
                                      color: Colors.white)),
                              title: Text(asset['name']),
                              subtitle: Text('${asset['category']} • $currency'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_symbolFor(currency)}${asset['amount']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteAsset(asset['id']),
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

  String _symbolFor(String currency) {
    switch (currency) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'INR': return '₹';
      default: return '$currency ';
    }
  }
}