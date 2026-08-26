import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';

class PaymentService {
  final _supabase = Supabase.instance.client;

  /// Returns the Paystack authorization URL if gateway is 'paystack',
  /// or returns null for other gateways.
  Future<String?> initializePayment({
    required CartProvider cart,
    required String name,
    required String phone,
    String? address,
    required String deliveryType,
    String? deliveryLocation,
    double deliveryFee = 0.0,
    required String gateway,
    required String uniqueRef,
  }) async {
    final double grandTotal = cart.totalAmount + (deliveryType == 'delivery' ? deliveryFee : 0.0);
    const String customerEmail = 'customer@dechoicemall.com';

    if (gateway == 'paystack') {
      final String paystackSecretKey = dotenv.env['PAYSTACK_SECRET_KEY'] ?? '';
      if (paystackSecretKey.isEmpty) {
        throw Exception('Paystack secret key is missing from environment variables.');
      }

      final int amountInKobo = (grandTotal * 100).toInt();

      final url = Uri.parse('https://api.paystack.co/transaction/initialize');
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $paystackSecretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': customerEmail,
          'amount': amountInKobo.toString(),
          'reference': uniqueRef,
          'currency': 'NGN',
          'callback_url': 'dechoicemall://payment-callback',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          return data['data']['authorization_url'];
        } else {
          throw Exception(data['message'] ?? 'Failed to initialize Paystack transaction');
        }
      } else {
        throw Exception('Paystack API error: ${response.body}');
      }
    }
    return null;
  }

  /// Saves the order to Supabase after a successful transaction verification.
  Future<void> recordSuccessfulOrder({
    required CartProvider cart,
    required String name,
    required String phone,
    String? address,
    required String deliveryType,
    String? deliveryLocation,
    double deliveryFee = 0.0,
    required String gateway,
    required String uniqueRef,
  }) async {
    final double grandTotal = cart.totalAmount + (deliveryType == 'delivery' ? deliveryFee : 0.5);

    List<Map<String, dynamic>> orderItems = cart.items.values.map((item) {
      return {
        'name': item.name,
        'price': item.price,
        'quantity': item.quantity,
        'image_url': item.imageUrl,
      };
    }).toList();

    await _supabase.from('orders').insert({
      'customer_name': name,
      'phone_number': phone,
      'delivery_type': deliveryType,
      'delivery_address': address,
      'delivery_location': deliveryLocation,
      'delivery_fee': deliveryFee,
      'items_total': cart.totalAmount,
      'total_amount': grandTotal,
      'payment_gateway': gateway,
      'payment_reference': uniqueRef,
      'items_json': orderItems,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}