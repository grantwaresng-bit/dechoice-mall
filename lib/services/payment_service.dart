import 'dart:convert';
import 'package:flutter/foundation.dart'; // Required for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';

class PaymentService {
  final _supabase = Supabase.instance.client;

  Future<void> processPayment({
    required CartProvider cart,
    required String name,
    required String phone,
    String? address,
    required String deliveryType,
    String? deliveryLocation,
    double deliveryFee = 0.0,
    required String gateway,
    required BuildContext context,
  }) async {
    final double grandTotal = cart.totalAmount + (deliveryType == 'delivery' ? deliveryFee : 0.0);
    final String uniqueRef = 'DM-${DateTime.now().millisecondsSinceEpoch}';
    const String customerEmail = 'customer@dechoicemall.com';

    bool isPaymentSuccessful = false;

    // Dynamically set callback/redirect URL: Web users stay on web, mobile app users trigger deep links
    final String callbackUrl = kIsWeb
        ? 'https://dechoicemall.com'
        : 'dechoicemall://payment-callback';

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
          'callback_url': callbackUrl,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == true) {
          final String authorizationUrl = data['data']['authorization_url'];
          final Uri uri = Uri.parse(authorizationUrl);

          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
              browserConfiguration: const BrowserConfiguration(showTitle: true),
            );
            isPaymentSuccessful = true;
          } else {
            throw Exception('Could not launch Paystack checkout page.');
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to initialize Paystack transaction');
        }
      } else {
        throw Exception('Paystack API error: ${response.body}');
      }
    } else if (gateway == 'flutterwave') {
      // Calls the Supabase Edge Function to bypass browser CORS blocks on Flutter Web
      try {
        final response = await _supabase.functions.invoke(
          'initialize-flutterwave',
          body: {
            'tx_ref': uniqueRef,
            'amount': grandTotal.toString(),
            'currency': 'NGN',
            'redirect_url': callbackUrl,
            'customer': {
              'email': customerEmail,
              'phonenumber': phone,
              'name': name,
            },
            'customizations': {
              'title': 'Dechoice Mall',
              'description': 'Payment for items in cart + delivery',
            },
          },
        );

        if (response.status == 200) {
          final data = response.data;
          // Handle case where Supabase functions.invoke returns map or parsed JSON directly
          final Map<String, dynamic> resData = data is String ? jsonDecode(data) : data;

          if (resData['status'] == 'success') {
            final String checkoutUrl = resData['data']['link'];
            final Uri uri = Uri.parse(checkoutUrl);

            if (await canLaunchUrl(uri)) {
              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
                browserConfiguration: const BrowserConfiguration(showTitle: true),
              );
              isPaymentSuccessful = true;
            } else {
              throw Exception('Could not launch Flutterwave checkout page.');
            }
          } else {
            throw Exception(resData['message'] ?? 'Failed to initialize Flutterwave transaction');
          }
        } else {
          throw Exception('Edge function error: ${response.data}');
        }
      } catch (e) {
        throw Exception('Flutterwave initialization error: $e');
      }
    }

    // Save order data to Supabase only if payment initializes and launches successfully
    if (isPaymentSuccessful) {
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
}