import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Hardcoded production Supabase URL
  static String get supabaseUrl => 'https://lyvenufljhemhoaifgts.supabase.co';

  // Hardcoded production Supabase Publishable / Anon Key
  static String get supabaseKey => 'sb_publishable_N-W9nLi-AqZcmFkZFhYqnw_4VeIulZn';

  // Flutterwave Public Key
  static String get flutterwaveKey => kIsWeb
      ? const String.fromEnvironment('FLUTTERWAVE_PUBLIC_KEY')
      : (dotenv.env['FLUTTERWAVE_PUBLIC_KEY'] ?? '');

  // Paystack Public Key
  static String get paystackKey => kIsWeb
      ? const String.fromEnvironment('PAYSTACK_PUBLIC_KEY')
      : (dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '');
}