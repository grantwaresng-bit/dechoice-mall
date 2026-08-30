import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_paystack_fork/flutter_paystack_fork.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/cart_provider.dart';
import '../services/payment_service.dart';
import '../widgets/responsive_wrapper.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String _deliveryType = 'pickup'; // 'pickup' or 'delivery'
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isProcessing = false;

  // Paystack plugin instance
  final plugin = PaystackPlugin();

  // Delivery location selection fields
  String? _selectedLocationId;
  String? _selectedLocationName;
  double _deliveryFee = 0.0;

  // Dynamic store hours fetched from database
  int _deliveryStartHour = 8;
  int _deliveryEndHour = 19;
  int _pickupEndHour = 21;
  bool _isLoadingHours = true;

  @override
  void initState() {
    super.initState();
    final publicKey = dotenv.env['PAYSTACK_PUBLIC_KEY'] ?? '';
    if (publicKey.isNotEmpty) {
      plugin.initialize(publicKey: publicKey);
    } else {
      debugPrint('Warning: PAYSTACK_PUBLIC_KEY not found in .env file');
    }
    _fetchStoreHours();
    _loadSavedCustomerDetails();
  }

  Future<void> _loadSavedCustomerDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;

      setState(() {
        _nameController.text = prefs.getString('saved_customer_name') ?? '';
        _phoneController.text = prefs.getString('saved_customer_phone') ?? '';
        _addressController.text = prefs.getString('saved_customer_address') ?? '';
      });
    } catch (e) {
      debugPrint('Error loading saved customer details: $e');
    }
  }

  Future<void> _saveCustomerDetailsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_customer_name', _nameController.text.trim());
      await prefs.setString('saved_customer_phone', _phoneController.text.trim());
      await prefs.setString('saved_customer_address', _addressController.text.trim());
    } catch (e) {
      debugPrint('Error saving customer details: $e');
    }
  }

  Future<void> _fetchStoreHours() async {
    try {
      final response = await Supabase.instance.client
          .from('store_settings')
          .select()
          .limit(1)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          _deliveryStartHour = response['delivery_start_hour'] ?? 8;
          _deliveryEndHour = response['delivery_end_hour'] ?? 19;
          _pickupEndHour = response['pickup_end_hour'] ?? 21;
          _isLoadingHours = false;
        });
      } else {
        setState(() => _isLoadingHours = false);
      }
    } catch (e) {
      debugPrint('Error fetching store hours: $e');
      setState(() => _isLoadingHours = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _isPastDeliveryWindow() {
    final now = DateTime.now();
    final currentHour = now.hour;
    return currentHour < _deliveryStartHour || currentHour >= _deliveryEndHour;
  }

  bool _isPastPickupWindow() {
    final now = DateTime.now();
    final currentHour = now.hour;
    return currentHour < _deliveryStartHour || currentHour >= _pickupEndHour;
  }

  void _showDeliveryClosedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text(
          'DELIVERY HOURS ENDED',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1.5,
            color: Color(0xFF1E1E1E),
          ),
        ),
        content: const Text(
          'It has passed our delivery time, please try pickup or tomorrow.',
          style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFF28C00),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPickupClosedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text(
          'PICKUP HOURS ENDED',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            letterSpacing: 1.5,
            color: Color(0xFF1E1E1E),
          ),
        ),
        content: Text(
          'It has passed our pickup time ($_pickupEndHour:00), please try again tomorrow.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFF28C00),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _getGrandTotal(CartProvider cart) {
    return cart.totalAmount + (_deliveryType == 'delivery' ? _deliveryFee : 0.0);
  }

  void _submitOrder() async {
    if (_formKey.currentState!.validate()) {
      if (_deliveryType == 'delivery') {
        if (_isPastDeliveryWindow()) {
          _showDeliveryClosedDialog();
          return;
        }
        if (_selectedLocationId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a delivery location'),
              backgroundColor: Color(0xFF1E1E1E),
            ),
          );
          return;
        }
      } else if (_deliveryType == 'pickup') {
        if (_isPastPickupWindow()) {
          _showPickupClosedDialog();
          return;
        }
      }

      await _saveCustomerDetailsLocally();

      if (!mounted) return;
      final cart = Provider.of<CartProvider>(context, listen: false);
      final grandTotal = _getGrandTotal(cart);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: const Text(
            'CONFIRM ORDER & PAY',
            style: TextStyle(
              fontSize: 13,
              letterSpacing: 1.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E1E1E),
            ),
          ),
          content: Text(
            'Type: ${_deliveryType.toUpperCase()}\n'
                'Name: ${_nameController.text}\n'
                'Phone: ${_phoneController.text}\n'
                '${_deliveryType == 'delivery' ? 'Area: $_selectedLocationName (₦$_deliveryFee)\nAddress: ${_addressController.text}\n' : ''}'
                'Items Total: ₦${cart.totalAmount.toStringAsFixed(2)}\n'
                'Grand Total: ₦${grandTotal.toStringAsFixed(2)}',
            style: const TextStyle(height: 1.6, fontSize: 13, color: Color(0xFF333333)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Color(0xFF666666), fontSize: 11, letterSpacing: 1),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF28C00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _showPaymentMethodSelector(cart);
              },
              child: const Text(
                'PROCEED TO PAYMENT',
                style: TextStyle(fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showPaymentMethodSelector(CartProvider cart) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'SELECT PAYMENT GATEWAY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Color(0xFF1E1E1E),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.payment, color: Color(0xFFF28C00), size: 20),
                title: const Text(
                  'Paystack',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E1E1E)),
                ),
                subtitle: const Text(
                  'Pay with Card, USSD, or Bank Transfer',
                  style: TextStyle(fontSize: 11, color: Color(0xFF666666)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _processActualPayment(cart, 'paystack');
                },
              ),
              const Divider(color: Color(0xFFDDDDDD), height: 1, thickness: 0.5),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFF28C00), size: 20),
                title: const Text(
                  'Flutterwave',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E1E1E)),
                ),
                subtitle: const Text(
                  'Pay with Cards, Bank, or Mobile Money',
                  style: TextStyle(fontSize: 11, color: Color(0xFF666666)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _processActualPayment(cart, 'flutterwave');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processActualPayment(CartProvider cart, String gateway) async {
    setState(() => _isProcessing = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final paymentService = PaymentService();

      // Only initializes + opens the payment page.
      // Returns the reference. Does NOT create any order.
      final String paymentRef = await paymentService.processPayment(
        cart: cart,
        name: _nameController.text,
        phone: _phoneController.text,
        address: _deliveryType == 'delivery' ? _addressController.text : null,
        deliveryType: _deliveryType,
        deliveryLocation: _deliveryType == 'delivery' ? _selectedLocationName : null,
        deliveryFee: _deliveryType == 'delivery' ? _deliveryFee : 0.0,
        gateway: gateway,
        context: context,
      );

      if (!mounted) return;

      // Important: We no longer save the order here.
      // Order will only be created after real payment confirmation (later).
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Payment page opened via ${gateway.toUpperCase()}.\n'
                'Complete the payment in the browser/app that opened.\n'
                'Reference: $paymentRef',
          ),
          backgroundColor: const Color(0xFF1E1E1E),
          duration: const Duration(seconds: 6),
        ),
      );

      // Stay on checkout so the user can still see their cart if they return without paying.
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Payment initialization failed: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final grandTotal = _getGrandTotal(cart);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CHECKOUT',
              style: TextStyle(
                color: Color(0xFF1E1E1E),
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFF28C00),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF1E1E1E)),
      ),
      body: ResponsiveLayoutWrapper(
        child: _isProcessing || _isLoadingHours
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFF28C00)))
            : isDesktop
            ? Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: _buildFormFields(cart),
                      ),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFDDDDDD)),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PRICE DETAILS',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                            const Divider(height: 24, color: Color(0xFFDDDDDD)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Items Subtotal', style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
                                Text(
                                  '₦${cart.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                              ],
                            ),
                            if (_deliveryType == 'delivery') ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Delivery Fee', style: TextStyle(color: Color(0xFF666666), fontSize: 13)),
                                  Text(
                                    '₦$_deliveryFee',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      color: Color(0xFF1E1E1E)  ,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Divider(height: 24, color: Color(0xFFDDDDDD), thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'GRAND TOTAL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    letterSpacing: 1.5,
                                    color: Color(0xFF1E1E1E),
                                  ),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '₦${grandTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          letterSpacing: 0.5,
                                          color: Color(0xFFF28C00),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF28C00),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  elevation: 0,
                                ),
                                onPressed: _submitOrder,
                                child: const Text(
                                  'PROCEED TO PAYMENT',
                                  style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                ..._buildFormFields(cart),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFDDDDDD), width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Items Subtotal', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                          Text(
                            '₦${cart.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                        ],
                      ),
                      if (_deliveryType == 'delivery') ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Fee', style: TextStyle(color: Color(0xFF666666), fontSize: 12)),
                            Text(
                              '₦$_deliveryFee',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: Color(0xFF1E1E1E),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 20, color: Color(0xFFDDDDDD), thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'GRAND TOTAL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1.5,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '₦${grandTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                    color: Color(0xFFF28C00),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF28C00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 0,
                    ),
                    onPressed: _submitOrder,
                    child: const Text(
                      'PROCEED TO PAYMENT',
                      style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormFields(CartProvider cart) {
    return [
      const Text(
        'FULFILLMENT METHOD',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          color: Color(0xFF1E1E1E),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: RadioListTile<String>(
              title: const Text(
                'Pick Up',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E1E1E)),
              ),
              value: 'pickup',
              groupValue: _deliveryType,
              activeColor: const Color(0xFFF28C00),
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                if (_isPastPickupWindow()) {
                  _showPickupClosedDialog();
                } else {
                  setState(() => _deliveryType = val!);
                }
              },
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: const Text(
                'Home Delivery',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E1E1E)),
              ),
              value: 'delivery',
              groupValue: _deliveryType,
              activeColor: const Color(0xFFF28C00),
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                if (_isPastDeliveryWindow()) {
                  _showDeliveryClosedDialog();
                  setState(() => _deliveryType = 'pickup');
                } else {
                  setState(() => _deliveryType = val!);
                }
              },
            ),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(
          'Pickup Hours: $_deliveryStartHour:00 AM – $_pickupEndHour:00 PM\n'
              'Delivery Hours: $_deliveryStartHour:00 AM – $_deliveryEndHour:00 PM',
          style: const TextStyle(fontSize: 11, color: Color(0xFF666666), height: 1.4),
        ),
      ),
      const SizedBox(height: 20),
      TextFormField(
        controller: _nameController,
        style: const TextStyle(color: Color(0xFF1E1E1E)),
        decoration: InputDecoration(
          labelText: 'Full Name',
          labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: Color(0xFFF28C00), width: 1.5),
          ),
        ),
        validator: (val) => val == null || val.isEmpty ? 'Please enter your name' : null,
      ),
      const SizedBox(height: 14),
      TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(color: Color(0xFF1E1E1E)),
        decoration: InputDecoration(
          labelText: 'Phone Number',
          labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            borderSide: BorderSide(color: Color(0xFFF28C00), width: 1.5),
          ),
        ),
        validator: (val) => val == null || val.isEmpty ? 'Please enter your phone number' : null,
      ),
      if (_deliveryType == 'delivery') ...[
        const SizedBox(height: 14),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: Supabase.instance.client.from('delivery_locations').select(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFF28C00)));
            }
            final locations = snapshot.data!;
            if (locations.isEmpty) {
              return const Text(
                'No delivery locations configured yet.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              );
            }

            return DropdownButtonFormField<String>(
              dropdownColor: Colors.white,
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E1E1E)),
              decoration: InputDecoration(
                labelText: 'Select Delivery Area',
                labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  borderSide: BorderSide(color: Color(0xFFF28C00), width: 1.5),
                ),
              ),
              value: _selectedLocationId,
              items: locations.map((loc) {
                return DropdownMenuItem<String>(
                  value: loc['id'].toString(),
                  child: Text(
                    '${loc['location_name']} (₦${loc['delivery_fee']})',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF1E1E1E)),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedLocationId = val;
                  final selectedLoc = locations.firstWhere((loc) => loc['id'].toString() == val);
                  _selectedLocationName = selectedLoc['location_name'];
                  _deliveryFee = double.tryParse(selectedLoc['delivery_fee'].toString()) ?? 0.0;
                });
              },
              validator: (val) => val == null ? 'Please select a delivery location' : null,
            );
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          style: const TextStyle(color: Color(0xFF1E1E1E)),
          decoration: InputDecoration(
            labelText: 'Specific Delivery Address / Street',
            labelStyle: const TextStyle(color: Color(0xFF666666), fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              borderSide: BorderSide(color: Color(0xFFF28C00), width: 1.5),
            ),
          ),
          validator: (val) => _deliveryType == 'delivery' && (val == null || val.isEmpty)
              ? 'Please enter delivery address'
              : null,
        ),
      ],
    ];
  }
}