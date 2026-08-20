import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';
import './customer_details_screen.dart';
import './add_customer_screen.dart';
import './category_management_screen.dart';
import './create_order_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Top Luxury App Bar with settings/toggles
          SliverAppBar(
            expandedHeight: 120,
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
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Khandelwal BOUTIQUE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fashion Designer Tracker',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [

              // Backup & Restore Menu
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : theme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(
                    Icons.settings_backup_restore_rounded,
                    color: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                    size: 20,
                  ),
                  tooltip: 'Backup & Restore',
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (value) async {
                    if (value == 'export') {
                      try {
                        await provider.exportDatabase();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Backup exported successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Export failed: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } else if (value == 'import') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          title: const Text('Restore Database?', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
                          content: const Text('Warning: This will overwrite all your current clients and orders data with the backup file data. This cannot be undone. Proceed?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Restore / Overwrite', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ) ?? false;

                      if (confirm) {
                        try {
                           await provider.importDatabase();
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Text('Database restored successfully!'),
                                 backgroundColor: Colors.green,
                               ),
                             );
                           }
                         } catch (e) {
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(
                                 content: Text('Restore failed: $e'),
                                 backgroundColor: Colors.red,
                               ),
                             );
                           }
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'export',
                      child: Row(
                        children: [
                          Icon(Icons.upload_rounded, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor, size: 20),
                          const SizedBox(width: 12),
                          const Text('Backup Data (Export)', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                          Icon(Icons.download_rounded, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor, size: 20),
                          const SizedBox(width: 12),
                          const Text('Restore Data (Import)', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Theme Toggle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : theme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                    size: 20,
                  ),
                  tooltip: 'Toggle Theme',
                  onPressed: provider.toggleTheme,
                ),
              ),
            ],
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
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
                    hintText: 'Search atelier clients...',
                    hintStyle: TextStyle(color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            ),
          ),

          // Business Overview Dashboard Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ATELIER STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF101726) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark ? const Color(0xFFC5A880).withValues(alpha: 0.15) : const Color(0xFFECEAE2),
                        width: 1.2,
                      ),
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF101726), const Color(0xFF141D30)]
                            : [Colors.white, const Color(0xFFFAF8F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDashboardStatItem(
                          'Total Revenue',
                          provider.formatPrice(provider.totalRevenue),
                          isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                        ),
                        Container(width: 1.2, height: 40, color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFECEAE2)),
                        _buildDashboardStatItem(
                          'Outstanding',
                          provider.formatPrice(provider.outstandingBalance),
                          provider.outstandingBalance > 0 ? Colors.red.shade400 : Colors.green.shade400,
                        ),
                        Container(width: 1.2, height: 40, color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFECEAE2)),
                        _buildDashboardStatItem(
                          'Active Orders',
                          '${provider.activeOrdersCount}',
                          isDark ? Colors.white : theme.primaryColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Upcoming Deliveries Section
          if (provider.upcomingDeliveries.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'UPCOMING DELIVERIES (3 DAYS)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 125,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: provider.upcomingDeliveries.length,
                        itemBuilder: (context, index) {
                          final order = provider.upcomingDeliveries[index];
                          final customer = provider.customers.firstWhere(
                            (c) => c.id == order.customerId,
                            orElse: () => Customer(name: 'Unknown Client', phone: ''),
                          );
                          final daysLeft = order.deliveryDate!.difference(DateTime.now()).inDays + 1;
                          final isOverdue = daysLeft <= 0;

                          return Container(
                            width: 260,
                            margin: const EdgeInsets.only(right: 16, bottom: 4),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF141D30) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isOverdue 
                                    ? Colors.red.withValues(alpha: 0.3) 
                                    : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECEAE2)),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => CustomerDetailsScreen(customer: customer)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          customer.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isOverdue 
                                              ? Colors.red.withValues(alpha: 0.1) 
                                              : const Color(0xFFC5A880).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          isOverdue ? 'Overdue' : '$daysLeft days left',
                                          style: TextStyle(
                                            color: isOverdue ? Colors.red : const Color(0xFFC5A880),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        order.type.name.toUpperCase(),
                                        style: TextStyle(
                                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      Text(
                                        'Due: ${DateFormat.MMMd().format(order.deliveryDate!)}',
                                        style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Quick Action Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          'New Order',
                          'Create custom order',
                          Icons.shopping_bag_rounded,
                          isDark ? const Color(0xFF141D30) : Colors.white,
                          const Color(0xFFC5A880),
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateOrderScreen())),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildQuickActionCard(
                          context,
                          'Templates',
                          'Configure measurements',
                          Icons.rule_rounded,
                          isDark ? const Color(0xFF141D30) : Colors.white,
                          isDark ? Colors.white70 : theme.primaryColor,
                          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryManagementScreen())),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Clients Title
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 12),
            sliver: SliverToBoxAdapter(
              child: Text(
                'REGISTERED CLIENTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Color(0xFF8E8B82),
                ),
              ),
            ),
          ),

          // Registered Clients List
          Consumer<CustomerProvider>(
            builder: (context, provider, child) {
              final customers = provider.customers.where((c) {
                return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    c.phone.contains(_searchQuery);
              }).toList();

              if (customers.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        const Text(
                          'No boutique clients found.',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
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
                      final customer = customers[index];
                      return _buildCustomerItem(customer, isDark, theme);
                    },
                    childCount: customers.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddCustomerScreen())),
          icon: const Icon(Icons.person_add_rounded, color: Colors.white),
          label: const Text('Register Client', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: theme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildDashboardStatItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18, 
            fontWeight: FontWeight.w900, 
            color: valueColor,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color bg,
    Color iconColor,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECEAE2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerItem(Customer customer, bool isDark, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CustomerDetailsScreen(customer: customer)),
        ),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFFC5A880).withValues(alpha: 0.1) : theme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            image: customer.photoPath != null && File(customer.photoPath!).existsSync()
                ? DecorationImage(image: FileImage(File(customer.photoPath!)), fit: BoxFit.cover)
                : null,
          ),
          child: customer.photoPath == null || !File(customer.photoPath!).existsSync()
              ? Icon(
                  Icons.person_rounded, 
                  color: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                  size: 24,
                )
              : null,
        ),
        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            customer.phone, 
            style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade600, fontSize: 13),
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
      ),
    );
  }
}
