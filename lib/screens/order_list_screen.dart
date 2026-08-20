import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/measurement.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import './customer_details_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  MeasurementStatus? _selectedStatus;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Elegant Header Section matching Dashboard
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF080C14), const Color(0xFF101726)]
                        : [const Color(0xFFFAF9F6), const Color(0xFFF0EDE4)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'GARMENT ORDERS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : theme.primaryColor,
                ),
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF101726) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECEAE2),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search orders by client or type...',
                    hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),
          ),

          // Horizontal Status Badges
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  _buildStatusChip(null, 'All Orders', theme, isDark),
                  ...MeasurementStatus.values.map((s) => _buildStatusChip(s, _getStatusLabel(s), theme, isDark)),
                ],
              ),
            ),
          ),

          // Orders List
          Consumer<CustomerProvider>(
            builder: (context, provider, child) {
              final measurements = provider.measurements.where((m) {
                final customer = provider.customers.firstWhere(
                  (c) => c.id == m.customerId,
                  orElse: () => Customer(name: 'Deleted Client', phone: ''),
                );
                final matchesSearch = customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                                     m.type.name.toLowerCase().contains(_searchQuery.toLowerCase());
                final matchesStatus = _selectedStatus == null || m.status == _selectedStatus;
                return matchesSearch && matchesStatus;
              }).toList();

              // Sort by date (descending)
              measurements.sort((a, b) => b.date.compareTo(a.date));

              if (measurements.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'No orders found',
                          style: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final measurement = measurements[index];
                      final customer = provider.customers.firstWhere(
                        (c) => c.id == measurement.customerId,
                        orElse: () => Customer(name: 'Deleted Customer', phone: ''),
                      );
                      return _buildOrderCard(context, provider, measurement, customer, isDark);
                    },
                    childCount: measurements.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(MeasurementStatus? status, String label, ThemeData theme, bool isDark) {
    final isSelected = _selectedStatus == status;
    final activeColor = isDark ? const Color(0xFFC5A880) : theme.primaryColor;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (val) => setState(() => _selectedStatus = status),
        backgroundColor: isDark ? const Color(0xFF101726) : Colors.white,
        selectedColor: activeColor.withValues(alpha: 0.15),
        checkmarkColor: activeColor,
        side: BorderSide(
          color: isSelected 
              ? activeColor 
              : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECEAE2)),
        ),
        labelStyle: TextStyle(
          color: isSelected ? activeColor : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context, 
    CustomerProvider provider, 
    Measurement measurement, 
    Customer customer, 
    bool isDark) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(measurement.status);
    final balance = measurement.totalPrice - measurement.paidAmount;
    final isOverdue = measurement.deliveryDate != null && 
                      measurement.deliveryDate!.isBefore(DateTime.now().add(const Duration(days: 1))) &&
                      measurement.status != MeasurementStatus.delivered;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101726) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECEAE2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailsScreen(customer: customer))),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Customer & Garment Type Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.style_rounded, size: 14, color: Color(0xFFC5A880)),
                              const SizedBox(width: 4),
                              Text(
                                measurement.type.name.toUpperCase(), 
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, 
                                  fontSize: 11, 
                                  letterSpacing: 0.8, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _getStatusLabel(measurement.status).toUpperCase(),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                // Visual Timeline Stepper
                Text(
                  'FABRICATION PROGRESS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatusTimeline(measurement.status, isDark, theme),

                const Divider(height: 32),
                
                // Delivery & Financial Balances
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DELIVERY DATE', 
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade500 : Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.event_available_rounded, 
                              size: 15, 
                              color: isOverdue ? Colors.red : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              measurement.deliveryDate != null 
                                  ? DateFormat.yMMMd().format(measurement.deliveryDate!) 
                                  : 'Pending',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isOverdue ? Colors.red : (isDark ? Colors.white : Colors.black87),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'OUTSTANDING', 
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade500 : Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          provider.formatPrice(balance),
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            color: balance > 0 ? (isDark ? const Color(0xFFC5A880) : theme.primaryColor) : Colors.green.shade400,
                            fontSize: 15,
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.history_rounded, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'Recorded ${DateFormat.yMMMd().format(measurement.date)}', 
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showStatusPicker(context, measurement, provider),
                      icon: Icon(Icons.edit_note_rounded, size: 16, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor),
                      label: Text(
                        'Update Status', 
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(MeasurementStatus status, bool isDark, ThemeData theme) {
    final steps = [
      MeasurementStatus.notStarted,
      MeasurementStatus.cutting,
      MeasurementStatus.stitching,
      MeasurementStatus.readyForTrial,
      MeasurementStatus.completed,
      MeasurementStatus.delivered,
    ];
    
    final currentStepIndex = steps.indexOf(status);
    
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStepIndex;
        final isCurrent = index == currentStepIndex;
        
        final stepColor = isActive
            ? (isCurrent 
                ? const Color(0xFFC5A880) 
                : (isDark ? const Color(0xFFC5A880).withValues(alpha: 0.6) : theme.primaryColor))
            : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200);
            
        return Expanded(
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stepColor,
                  border: isCurrent
                      ? Border.all(
                          color: isDark ? Colors.white : theme.primaryColor,
                          width: 2.5,
                        )
                      : null,
                ),
              ),
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: index < currentStepIndex
                        ? (isDark ? const Color(0xFFC5A880).withValues(alpha: 0.6) : theme.primaryColor)
                        : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade200),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _showStatusPicker(BuildContext context, Measurement measurement, CustomerProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customer = provider.customers.firstWhere(
      (c) => c.id == measurement.customerId,
      orElse: () => Customer(name: 'Client', phone: ''),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF101726) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Update Fabrication Status', 
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: MeasurementStatus.values.map((status) {
                      final isCurrent = measurement.status == status;
                      final statusColor = _getStatusColor(status);
                      return ListTile(
                        leading: Icon(
                          isCurrent ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                          color: isCurrent ? const Color(0xFFC5A880) : Colors.grey.shade400,
                        ),
                        title: Text(
                          _getStatusLabel(status),
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? (isDark ? Colors.white : theme.primaryColor) : null,
                          ),
                        ),
                        trailing: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor),
                        ),
                        onTap: () async {
                          try {
                            final oldBalance = measurement.totalPrice - measurement.paidAmount;
                            await provider.updateMeasurementStatus(measurement.id, status);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                              
                              String snackBarMsg = 'Status updated to: ${_getStatusLabel(status)}';
                              if (status == MeasurementStatus.delivered && oldBalance > 0) {
                                snackBarMsg = 'Status updated to: Delivered. Balance of ${provider.currencySymbol}${oldBalance.toStringAsFixed(0)} settled!';
                              }
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(snackBarMsg),
                                  backgroundColor: Colors.green,
                                ),
                              );

                              // Ask to send WhatsApp Order Ready notification
                              if (status == MeasurementStatus.completed && customer.phone.isNotEmpty) {
                                final sendMsg = await showDialog<bool>(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext dialogContext) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      title: Text(
                                        'Send "Order Ready" Message?',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : theme.primaryColor,
                                        ),
                                      ),
                                      content: Text(
                                        'Would you like to send an order ready notification to ${customer.name} on WhatsApp?',
                                        style: TextStyle(
                                          color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogContext, false),
                                          child: Text('Skip', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFC5A880),
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          ),
                                          onPressed: () => Navigator.pop(dialogContext, true),
                                          child: const Text('Send via WhatsApp', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    );
                                  },
                                ) ?? false;

                                if (sendMsg && context.mounted) {
                                  try {
                                    await provider.sendOrderReadyWhatsApp(customer, measurement);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Could not open WhatsApp: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              }
                            }
                          } catch (e) {
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStatusLabel(MeasurementStatus status) {
    switch (status) {
      case MeasurementStatus.notStarted: return 'Placed';
      case MeasurementStatus.cutting: return 'In Cutting';
      case MeasurementStatus.stitching: return 'Stitching';
      case MeasurementStatus.readyForTrial: return 'Ready for Trial';
      case MeasurementStatus.completed: return 'Completed';
      case MeasurementStatus.delivered: return 'Delivered';
    }
  }

  Color _getStatusColor(MeasurementStatus status) {
    switch (status) {
      case MeasurementStatus.notStarted: return Colors.amber.shade600;
      case MeasurementStatus.cutting: return Colors.blue.shade500;
      case MeasurementStatus.stitching: return Colors.indigo.shade500;
      case MeasurementStatus.readyForTrial: return Colors.purple.shade500;
      case MeasurementStatus.completed: return Colors.green.shade500;
      case MeasurementStatus.delivered: return Colors.grey.shade500;
    }
  }
}
