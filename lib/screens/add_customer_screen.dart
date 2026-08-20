import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import '../models/customer.dart';
import '../providers/customer_provider.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedBirthday;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      try {
        final customer = Customer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          birthday: _selectedBirthday,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

        final provider = Provider.of<CustomerProvider>(context, listen: false);
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        await provider.addCustomer(customer);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client registered successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Ask to send welcome message via WhatsApp
          final sendMsg = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: Text(
                  'Send Welcome Message?',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : theme.primaryColor,
                  ),
                ),
                content: Text(
                  'Would you like to send a welcome message to ${customer.name} on WhatsApp?',
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

          if (sendMsg && mounted) {
            try {
              await provider.sendWelcomeWhatsApp(customer);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not open WhatsApp: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }

          if (mounted) {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error registering client: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickFromContacts() async {
    try {
      final picker = FlutterNativeContactPicker();
      final contact = await picker.selectContact();
      if (contact != null) {
        setState(() {
          if (contact.fullName != null && contact.fullName!.isNotEmpty) {
            _nameController.text = contact.fullName!;
          }
          if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
            String rawPhone = contact.phoneNumbers!.first;
            String cleanPhone = rawPhone.replaceAll(RegExp(r'[\s\-()]+'), '');
            _phoneController.text = cleanPhone;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contact details imported!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick contact: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goldColor = isDark ? const Color(0xFFC5A880) : const Color(0xFFB8860B);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: isDark ? Colors.white : theme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Register Client', 
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  letterSpacing: 1.5,
                  color: isDark ? Colors.white : theme.primaryColor,
                  fontFamily: 'Outfit',
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF080C14), const Color(0xFF141D30)]
                        : [const Color(0xFFFAF9F6), const Color(0xFFE5D8C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.person_add_rounded, 
                    size: 80, 
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CONTACT INFORMATION', 
                            style: TextStyle(
                              fontSize: 11, 
                              fontWeight: FontWeight.bold, 
                              letterSpacing: 1.5,
                              color: goldColor,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: goldColor,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            icon: const Icon(Icons.import_contacts_rounded, size: 16),
                            label: const Text('Import Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            onPressed: _pickFromContacts,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          labelText: 'Full Name', 
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter full name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          labelText: 'Phone Number', 
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter phone number' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          labelText: 'Email Address (Optional)', 
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'ATELIER DETAILS', 
                        style: TextStyle(
                          fontSize: 11, 
                          fontWeight: FontWeight.bold, 
                          letterSpacing: 1.5,
                          color: goldColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF101726) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECEAE2),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          title: const Text('Birthday (Optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              _selectedBirthday == null 
                                  ? 'Not Configured' 
                                  : DateFormat.yMMMd().format(_selectedBirthday!),
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: _selectedBirthday == null ? Colors.grey : goldColor,
                              ),
                            ),
                          ),
                          trailing: Icon(Icons.cake_outlined, color: goldColor),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context, 
                              initialDate: DateTime.now().subtract(const Duration(days: 365 * 25)), 
                              firstDate: DateTime(1900), 
                              lastDate: DateTime.now(),
                            );
                            if (date != null) setState(() => _selectedBirthday = date);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Internal Notes', 
                          prefixIcon: Icon(Icons.note_alt_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saveCustomer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC5A880),
                            foregroundColor: const Color(0xFF0B132B),
                          ),
                          child: const Text('Save Client Profile'),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
