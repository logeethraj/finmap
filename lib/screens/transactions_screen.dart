import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final data = await _supabase
        .from('transactions')
        .select()
        .order('date', ascending: false);
    setState(() {
      _transactions = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  Future<void> _deleteTransaction(String id) async {
    await _supabase.from('transactions').delete().eq('id', id);
    _loadTransactions();
  }

  void _showAddDialog(String type) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = type == 'income' ? 'Salary' : 'Groceries';

    final incomeCategories = ['Salary', 'Freelance', 'Rent', 'Business', 'Other'];
    final expenseCategories = ['Groceries', 'EMI', 'Utilities', 'Transport', 'Food', 'Other'];
    final categories = type == 'income' ? incomeCategories : expenseCategories;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add ${type == 'income' ? 'Income' : 'Expense'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setDialogState(() => selectedCategory = v!),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _supabase.from('transactions').insert({
                  'user_id': _supabase.auth.currentUser!.id,
                  'type': type,
                  'amount': double.parse(amountController.text),
                  'category': selectedCategory,
                  'note': noteController.text,
                });
                if (mounted) Navigator.pop(context);
                _loadTransactions();
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
    final income = _transactions
        .where((t) => t['type'] == 'income')
        .fold(0.0, (sum, t) => sum + (t['amount'] as num));
    final expenses = _transactions
        .where((t) => t['type'] == 'expense')
        .fold(0.0, (sum, t) => sum + (t['amount'] as num));
    final savings = income - expenses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statCard('Income', '₹${income.toStringAsFixed(0)}', Colors.green),
                _statCard('Expenses', '₹${expenses.toStringAsFixed(0)}', Colors.red),
                _statCard('Savings', '₹${savings.toStringAsFixed(0)}', Colors.blue),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddDialog('income'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Income'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddDialog('expense'),
                    icon: const Icon(Icons.remove),
                    label: const Text('Add Expense'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _transactions.isEmpty
                    ? const Center(child: Text('No transactions yet.'))
                    : ListView.builder(
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final t = _transactions[index];
                          final isIncome = t['type'] == 'income';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isIncome ? Colors.green : Colors.red,
                              child: Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.white),
                            ),
                            title: Text(t['category']),
                            subtitle: Text(t['note'] ?? t['date']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'}₹${t['amount']}',
                                  style: TextStyle(
                                    color: isIncome ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteTransaction(t['id']),
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

  Widget _statCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: color, fontSize: 12)),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}