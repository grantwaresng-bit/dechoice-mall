import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Supabase URL
  static String get supabaseUrl => kIsWeb
      ? const String.fromEnvironment('SUPABASE_URL')
      : (dotenv.env['SUPABASE_URL'] ?? '');

  // Supabase Publishable Key
  static String get supabaseKey => kIsWeb
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

  // Flutterwave Public Key
  static String get flutterwaveKey => kIsWeb
      ? const String.fromEnvironment('FLUTTERWAVE_PUBLIC_KEY')
      : (dotenv.env['FLUTTERWAVE_PUBLIC_KEY'] ?? '');

  // Paystack Public Key
  static String get paystackKey => kIsWeb
      ? const String.fromEnvironment('PAYSTACK_PUBLIC_KEY')
      : (dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '');
}