import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static Map<String, double> _rates = {};
  static DateTime? _lastFetched;

  static Future<Map<String, double>> getRates() async {
    if (_rates.isNotEmpty &&
        _lastFetched != null &&
        DateTime.now().difference(_lastFetched!).inHours < 6) {
      return _rates;
    }

    try {
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/INR'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _rates = Map<String, double>.from(
          (data['rates'] as Map).map((k, v) => MapEntry(k, (v as num).toDouble())),
        );
        _lastFetched = DateTime.now();
      }
    } catch (e) {
      // Fallback rates if API fails (1 INR in other currencies)
      _rates = {
        'INR': 1.0,
        'USD': 0.012,
        'EUR': 0.011,
        'GBP': 0.0095,
        'AED': 0.044,
        'SGD': 0.016,
      };
    }
    return _rates;
  }

  // Convert amount from one currency to INR (base currency)
  static Future<double> convertToINR(double amount, String fromCurrency) async {
    if (fromCurrency == 'INR') return amount;
    final rates = await getRates();
    final rate = rates[fromCurrency] ?? 1.0;
    return amount / rate;
  }
  static Future<double> convertFromINR(double amountInINR, String toCurrency) async {
    if (toCurrency == 'INR') return amountInINR;
    final rates = await getRates();
    final rate = rates[toCurrency] ?? 1.0;
    return amountInINR * rate;
  }

  static String symbolFor(String currency) {
    switch (currency) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'AED': return 'AED ';
      case 'SGD': return 'S\$';
      default: return '₹';
    }
  }
}