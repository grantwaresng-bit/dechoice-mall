import 'package:flutter/material.dart';
import '../widgets/responsive_wrapper.dart'; // Import ResponsiveLayoutWrapper

class PaymentMethodScreen extends StatelessWidget {
  final double totalAmount;
  final Function(String selectedGateway) onPaymentSelected;

  const PaymentMethodScreen({
    super.key,
    required this.totalAmount,
    required this.onPaymentSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    Widget content = Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                const Text(
                  'TOTAL TO PAY',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₦${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFFF28C00),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          const Text(
            'AVAILABLE GATEWAYS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Color(0xFF1E1E1E),
            ),
          ),
          const SizedBox(height: 12),

          // Paystack Option
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(Icons.payment, color: Color(0xFFF28C00), size: 20),
              title: const Text(
                'Paystack',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.3, color: Color(0xFF1E1E1E)),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  'Secure card, bank transfer, or USSD',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF666666)),
              onTap: () {
                Navigator.pop(context);
                onPaymentSelected('paystack');
              },
            ),
          ),
          const SizedBox(height: 10),

          // Flutterwave Option
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(Icons.account_balance_wallet, color: Color(0xFFF28C00), size: 20),
              title: const Text(
                'Flutterwave',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.3, color: Color(0xFF1E1E1E)),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: Text(
                  'Cards, mobile money, and international',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF666666)),
              onTap: () {
                Navigator.pop(context);
                onPaymentSelected('flutterwave');
              },
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SELECT PAYMENT METHOD',
              style: TextStyle(
                color: Color(0xFF1E1E1E),
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFFF28C00),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1E1E1E)),
      ),
      body: ResponsiveLayoutWrapper(
        child: isDesktop
            ? Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: content,
          ),
        )
            : content,
      ),
    );
  }
}