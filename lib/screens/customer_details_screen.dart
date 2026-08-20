import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../models/measurement.dart';
import '../providers/customer_provider.dart';
import './add_measurement_screen.dart';

class CustomerDetailsScreen extends StatelessWidget {
  const CustomerDetailsScreen({super.key, required this.customer});
  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final clientMeasurements = provider.getMeasurementsByCustomerId(customer.id);
    final clientOutstanding = clientMeasurements.fold(0.0, (sum, m) => sum + (m.totalPrice - m.paidAmount));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Luxury App Bar with Custom Background
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: isDark ? Colors.white : theme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                customer.name.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 2,
                  color: isDark ? Colors.white : theme.primaryColor,
                  shadows: [
                    Shadow(
                      color: isDark ? Colors.black54 : Colors.white70,
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    )
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (customer.photoPath != null && File(customer.photoPath!).existsSync())
                    Opacity(
                      opacity: 0.2,
                      child: Image.file(
                        File(customer.photoPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF080C14), const Color(0xFF141D30)]
                              : [const Color(0xFFFAF9F6), const Color(0xFFE2DFD5)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  Center(
                    child: Hero(
                      tag: 'avatar_${customer.id}',
                      child: Container(
                        width: 90,
                        height: 90,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                            width: 2.5,
                          ),
                          color: isDark ? const Color(0xFF101726) : Colors.white,
                          image: customer.photoPath != null && File(customer.photoPath!).existsSync()
                              ? DecorationImage(image: FileImage(File(customer.photoPath!)), fit: BoxFit.cover)
                              : null,
                        ),
                        child: customer.photoPath == null || !File(customer.photoPath!).existsSync()
                            ? Icon(
                                Icons.person_rounded, 
                                size: 48, 
                                color: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete Profile',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: isDark ? const Color(0xFF101726) : Colors.white,
                      title: const Text('Delete Client?'),
                      content: Text('Are you sure you want to remove ${customer.name} and all associated orders?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await provider.deleteCustomer(customer.id);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  }
                },
              ),
            ],
          ),

          // Main Profile Contents
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Contact Actions Bar
                _buildContactActions(context, customer, clientMeasurements.isNotEmpty ? clientMeasurements.first : null),
                const SizedBox(height: 24),

                // Financial Summary Card
                _buildFinanceSummary(provider, clientOutstanding, clientMeasurements.length),
                const SizedBox(height: 24),

                // Client Details Info Card
                _buildInfoCard(context, isDark, theme),
                const SizedBox(height: 32),

                // Measurements History Title and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'GARMENT RECORDS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddMeasurementScreen(customer: customer),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC5A880),
                        foregroundColor: const Color(0xFF0B132B),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      icon: const Icon(Icons.straighten_rounded, size: 16),
                      label: const Text('Measure'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // History List
                _buildMeasurementsList(provider, isDark, theme),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactActions(BuildContext context, Customer customer, Measurement? latestMeasurement) {
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildCircularActionButton(
          Icons.phone_rounded, 
          'Call',
          () async {
            final uri = Uri.parse('tel:${customer.phone}');
            try {
              bool launched = await launchUrl(uri);
              if (!launched) {
                throw Exception('Could not launch phone dialer.');
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not make call: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          isDark,
          theme,
        ),
        const SizedBox(width: 20),
        _buildCircularActionButton(
          Icons.chat_bubble_rounded, 
          'WhatsApp',
          () async {
            try {
              if (latestMeasurement != null) {
                await provider.openWhatsApp(customer, latestMeasurement);
              } else {
                final text = 'Hello ${customer.name}, greeting from Khandelwal Boutique!';
                String cleanPhone = customer.phone.replaceAll(RegExp(r'\D'), '');
                if (cleanPhone.length == 10) {
                  cleanPhone = '91$cleanPhone';
                }
                final url = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(text)}';
                final uri = Uri.parse(url);
                bool launched = false;
                try {
                  launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
                } catch (_) {
                  try {
                    launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
                  } catch (e) {
                    throw Exception('Could not launch WhatsApp: $e');
                  }
                }
                if (!launched) {
                  throw Exception('Could not launch WhatsApp. Please ensure WhatsApp is installed.');
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not open WhatsApp: ${e.toString().replaceAll('Exception: ', '')}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          isDark,
          theme,
        ),
        if (customer.email != null) ...[
          const SizedBox(width: 20),
          _buildCircularActionButton(
            Icons.email_rounded, 
            'Email',
            () async {
              final uri = Uri.parse('mailto:${customer.email}');
              try {
                bool launched = await launchUrl(uri);
                if (!launched) {
                  throw Exception('Could not launch email app.');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not send email: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            isDark,
            theme,
          ),
        ],
      ],
    );
  }

  Widget _buildCircularActionButton(IconData icon, String tooltip, VoidCallback onTap, bool isDark, ThemeData theme) {
    final activeColor = isDark ? const Color(0xFFC5A880) : theme.primaryColor;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? const Color(0xFF101726) : Colors.white,
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECEAE2),
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
          child: Icon(icon, color: activeColor, size: 22),
        ),
      ),
    );
  }

  Widget _buildFinanceSummary(CustomerProvider provider, double outstanding, int totalOrders) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: outstanding > 0 ? Colors.red.shade400.withValues(alpha: 0.08) : Colors.green.shade400.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: outstanding > 0 ? Colors.red.shade400.withValues(alpha: 0.2) : Colors.green.shade400.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OUTSTANDING BALANCE', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(
                provider.formatPrice(outstanding),
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.w900, 
                  color: outstanding > 0 ? Colors.red.shade400 : Colors.green.shade400,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('TOTAL ORDERS', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(
                '$totalOrders garments',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101726) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECEAE2),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, Icons.phone_rounded, 'Phone', customer.phone),
          if (customer.email != null) ...[
            const Divider(height: 24),
            _buildInfoRow(context, Icons.email_rounded, 'Email', customer.email!),
          ],
          const Divider(height: 24),
          _buildInfoRow(context, Icons.calendar_today_rounded, 'Joined Client', DateFormat.yMMMd().format(customer.createdAt)),
          if (customer.birthday != null) ...[
            const Divider(height: 24),
            _buildInfoRow(context, Icons.cake_rounded, 'Birthday', DateFormat.yMMMd().format(customer.birthday!)),
          ],
          if (customer.notes != null) ...[
            const Divider(height: 24),
            _buildInfoRow(context, Icons.note_alt_rounded, 'Notes', customer.notes!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFFC5A880).withValues(alpha: 0.1) : theme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementsList(CustomerProvider provider, bool isDark, ThemeData theme) {
    final measurements = provider.getMeasurementsByCustomerId(customer.id);
    
    if (measurements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101726) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECEAE2)),
        ),
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No registered garments for this client.', 
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }
    
    // Sort descending
    measurements.sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: measurements.length,
      itemBuilder: (context, index) {
        final measurement = measurements[index];
        final balance = measurement.totalPrice - measurement.paidAmount;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF101726) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECEAE2),
              width: 1.2,
            ),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(
              measurement.type.name.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                color: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                letterSpacing: 1,
              ),
            ),
            subtitle: Text(
              'Recorded on ${DateFormat.yMMMd().format(measurement.date)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            leading: Icon(
              Icons.style_rounded, 
              color: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
              size: 24,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            shape: const RoundedRectangleBorder(side: BorderSide.none),
            children: [
              // Financial Summary details for this garment
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Value: ${provider.formatPrice(measurement.totalPrice)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: balance > 0 
                          ? Colors.orange.withValues(alpha: 0.1) 
                          : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      balance > 0 ? 'Bal: ${provider.formatPrice(balance)}' : 'Fully Paid',
                      style: TextStyle(
                        fontSize: 11, 
                        fontWeight: FontWeight.bold,
                        color: balance > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              
              // Reference Photos horizontal gallery (No SliverList Crash!)
              if (measurement.photos != null && measurement.photos!.isNotEmpty) ...[
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: measurement.photos!.length,
                    itemBuilder: (context, pIndex) {
                      final photoPath = measurement.photos![pIndex];
                      final fileExists = File(photoPath).existsSync();
                      return Container(
                        margin: const EdgeInsets.only(right: 8, bottom: 8),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECEAE2),
                          ),
                          image: fileExists
                              ? DecorationImage(
                                  image: FileImage(File(photoPath)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.1),
                        ),
                        child: !fileExists
                            ? Center(
                                child: Icon(
                                  Icons.image_not_supported_rounded, 
                                  color: Colors.grey.shade400, 
                                  size: 20,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Dimensions values grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: measurement.values.length,
                itemBuilder: (context, vIndex) {
                  final entry = measurement.values.entries.elementAt(vIndex);
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF141D30) : const Color(0xFFF6F5F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECEAE2),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 9, 
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, 
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${entry.value}',
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 13, 
                            color: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              if (measurement.note != null && measurement.note!.isNotEmpty) ...[
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Notes: ${measurement.note}',
                    style: TextStyle(
                      fontSize: 12, 
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
              
              // Share Invoice & Details Row
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => provider.generateInovice(customer, measurement),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('Invoice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddMeasurementScreen(customer: customer, measurement: measurement),
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
