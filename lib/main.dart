import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/cart_provider.dart';
import 'screens/home_screen.dart';
import 'screens/web_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load local .env asset for mobile/local testing
  if (!kIsWeb) {
    await dotenv.load(fileName: ".env");
  }

  // Get Supabase credentials: Use Vercel build args on web, or .env locally
  final supabaseUrl = kIsWeb
      ? const String.fromEnvironment('SUPABASE_URL')
      : (dotenv.env['SUPABASE_URL'] ?? '');

  final supabaseKey = kIsWeb
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey, // Updated from anonKey to publishableKey
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const DechoiceMallApp(),
    ),
  );
}

// Custom scroll behavior to allow mouse drag scrolling smoothly on web/desktop viewports
class WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
  };
}

class DechoiceMallApp extends StatelessWidget {
  const DechoiceMallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dechoice Mall',
      debugShowCheckedModeBanner: false,
      scrollBehavior: WebScrollBehavior(),
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black, size: 20),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade100,
          thickness: 1,
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Colors.black12,
          selectionHandleColor: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: kIsWeb ? const WebHomeScreen() : const HomeScreen(),
    );
  }
}