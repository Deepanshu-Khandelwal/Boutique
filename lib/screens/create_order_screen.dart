import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import './add_customer_screen.dart';
import './add_measurement_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  String _searchQuery = '';
  Customer? _selectedCustomer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create New Order'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : theme.primaryColor,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select Customer Header Search Box
          Container(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF080C14), const Color(0xFF101726)]
                    : [const Color(0xFFFAF9F6), const Color(0xFFF0EDE4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECT CLIENT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF141D30) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECEAE2),
                      width: 1.2,
                    ),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search by client name or phone...',
                      hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                      fillColor: Colors.transparent,
                      filled: true,
                      prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Client List Section
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, provider, child) {
                final customers = provider.searchCustomers(_searchQuery);
                
                if (customers.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          'No registered client found.',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
                            );
                          },
                          icon: const Icon(Icons.person_add, color: Colors.white),
                          label: const Text('Add New Client', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC5A880),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: customers.length + 1,
                  itemBuilder: (context, index) {
                    if (index == customers.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
                            );
                          },
                          icon: Icon(Icons.person_add_rounded, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor),
                          label: Text(
                            'Register New Client',
                            style: TextStyle(color: isDark ? Colors.white : theme.primaryColor),
                          ),
                        ),
                      );
                    }

                    final customer = customers[index];
                    final isSelected = _selectedCustomer?.id == customer.id;
                    final activeColor = isDark ? const Color(0xFFC5A880) : theme.primaryColor;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF101726) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected 
                              ? activeColor 
                              : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECEAE2)),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.015),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () => setState(() => _selectedCustomer = customer),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        leading: CircleAvatar(
                          backgroundColor: activeColor.withValues(alpha: 0.1),
                          foregroundColor: activeColor,
                          child: Text(customer.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: Text(customer.phone, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                        trailing: isSelected 
                          ? Icon(Icons.check_circle_rounded, color: activeColor)
                          : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Selection Action Button
          if (_selectedCustomer != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddMeasurementScreen(customer: _selectedCustomer!),
                      ),
                    );
                  },
                  child: const Text(
                    'Continue to Measurements',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
