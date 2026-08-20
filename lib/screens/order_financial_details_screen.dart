import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/measurement.dart';
import '../providers/customer_provider.dart';

class OrderFinancialDetailsScreen extends StatefulWidget {
  const OrderFinancialDetailsScreen({
    super.key,
    required this.customer,
    required this.measurement,
  });
  final Customer customer;
  final Measurement measurement;

  @override
  State<OrderFinancialDetailsScreen> createState() => _OrderFinancialDetailsScreenState();
}

class _OrderFinancialDetailsScreenState extends State<OrderFinancialDetailsScreen> {
  late TextEditingController _totalPriceController;
  late TextEditingController _paidAmountController;
  late DateTime _selectedDeliveryDate;

  @override
  void initState() {
    super.initState();
    _totalPriceController = TextEditingController(
      text: widget.measurement.totalPrice > 0 ? widget.measurement.totalPrice.toStringAsFixed(0) : '',
    );
    _paidAmountController = TextEditingController(
      text: widget.measurement.paidAmount > 0 ? widget.measurement.paidAmount.toStringAsFixed(0) : '',
    );
    _selectedDeliveryDate = widget.measurement.deliveryDate ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _totalPriceController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDeliveryDate = picked);
    }
  }

  Future<void> _saveFinancialDetails() async {
    final totalPrice = double.tryParse(_totalPriceController.text) ?? 0.0;
    final paidAmount = double.tryParse(_paidAmountController.text) ?? 0.0;

    if (totalPrice < 0 || paidAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prices cannot be negative'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (paidAmount > totalPrice && totalPrice > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paid amount cannot exceed total price'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    widget.measurement.totalPrice = totalPrice;
    widget.measurement.paidAmount = paidAmount;
    widget.measurement.deliveryDate = _selectedDeliveryDate;

    try {
      await Provider.of<CustomerProvider>(context, listen: false)
          .updateMeasurement(widget.measurement);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final balanceDue = (double.tryParse(_totalPriceController.text) ?? 0.0) -
        (double.tryParse(_paidAmountController.text) ?? 0.0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Order Billing Details'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : theme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101726) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFFC5A880).withValues(alpha: 0.15) : const Color(0xFFECEAE2),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Customer: ${widget.customer.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.style_rounded, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Garment: ${widget.measurement.type.name.toUpperCase()}',
                        style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Delivery Date Section
            Text(
              'DELIVERY TARGET',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectDeliveryDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF101726) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECEAE2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat.yMMMd().format(_selectedDeliveryDate),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Icon(Icons.edit_calendar_rounded, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Total Price Section
            Text(
              'TOTAL PRICE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _totalPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Enter total price',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                prefixText: '${provider.currencySymbol} ',
                prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor, fontSize: 16),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 28),

            // Paid Amount Section
            Text(
              'ADVANCE AMOUNT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _paidAmountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Enter amount paid',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                prefixText: '${provider.currencySymbol} ',
                prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor, fontSize: 16),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Balance Due Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: balanceDue > 0 
                    ? Colors.orange.shade400.withValues(alpha: 0.08) 
                    : Colors.green.shade400.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: balanceDue > 0 
                      ? Colors.orange.shade400.withValues(alpha: 0.2) 
                      : Colors.green.shade400.withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Balance Due',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    provider.formatPrice(balanceDue),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: balanceDue > 0 ? Colors.orange : Colors.green,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveFinancialDetails,
                child: const Text('Save Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

