import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/cart_provider.dart';

class PaymentService {
  final _supabase = Supabase.instance.client;

  /// Initializes the payment gateway and opens the checkout page.
  /// Returns the payment reference if the page was launched successfully.
  /// Does NOT create any order in Supabase.
  Future<String> processPayment({
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
    final double grandTotal =
        cart.totalAmount + (deliveryType == 'delivery' ? deliveryFee : 0.0);
    final String uniqueRef = 'DM-${DateTime.now().millisecondsSinceEpoch}';
    const String customerEmail = 'customer@dechoicemall.com';

    // Web uses your live domain, mobile uses deep link
    final String callbackUrl = kIsWeb
        ? 'https://dechoicemall.com'
        : 'dechoicemall://payment-callback';

    if (gateway == 'paystack') {
      final String paystackSecretKey = dotenv.env['PAYSTACK_SECRET_KEY'] ??
          const String.fromEnvironment('PAYSTACK_SECRET_KEY');

      if (paystackSecretKey.isEmpty) {
        throw Exception(
            'Paystack secret key is missing from environment variables.');
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
            return uniqueRef; // Success – only return reference
          } else {
            throw Exception('Could not launch Paystack checkout page.');
          }
        } else {
          throw Exception(
              data['message'] ?? 'Failed to initialize Paystack transaction');
        }
      } else {
        throw Exception('Paystack API error: ${response.body}');
      }
    }

    if (gateway == 'flutterwave') {
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
          final Map<String, dynamic> resData =
          data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);

          if (resData['status'] == 'success') {
            final String checkoutUrl = resData['data']['link'];
            final Uri uri = Uri.parse(checkoutUrl);

            if (await canLaunchUrl(uri)) {
              await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
                browserConfiguration:
                const BrowserConfiguration(showTitle: true),
              );
              return uniqueRef; // Success – only return reference
            } else {
              throw Exception('Could not launch Flutterwave checkout page.');
            }
          } else {
            throw Exception(resData['message'] ??
                'Failed to initialize Flutterwave transaction');
          }
        } else {
          throw Exception('Edge function error: ${response.data}');
        }
      } catch (e) {
        throw Exception('Flutterwave initialization error: $e');
      }
    }

    throw Exception('Unknown payment gateway: $gateway');
  }
}