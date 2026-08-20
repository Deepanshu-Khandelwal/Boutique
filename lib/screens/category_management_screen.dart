import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../models/measurement_category.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _nameController = TextEditingController();
  final List<TextEditingController> _fieldControllers = [TextEditingController()];

  @override
  void dispose() {
    _nameController.dispose();
    for (var c in _fieldControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addField() {
    setState(() {
      _fieldControllers.add(TextEditingController());
    });
  }

  void _removeField(int index) {
    setState(() {
      _fieldControllers[index].dispose();
      _fieldControllers.removeAt(index);
    });
  }

  Future<void> _saveCategory() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template name'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    final fields = _fieldControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();
    if (fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one measurement field'), backgroundColor: Colors.orange),
      );
      return;
    }

    final category = MeasurementCategory(
      name: _nameController.text.trim(),
      fields: fields,
    );

    final provider = Provider.of<CustomerProvider>(context, listen: false);
    await provider.addCategory(category);
    
    setState(() {
      _nameController.clear();
      for (var c in _fieldControllers) {
        c.dispose();
      }
      _fieldControllers.clear();
      _fieldControllers.add(TextEditingController());
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Measurement template saved successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _deleteCategory(MeasurementCategory category) async {
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    await category.delete(); // Delete directly from Hive
    await provider.init(); // Reload provider lists
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template deleted!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Measurement Templates'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : theme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create Section
            Text(
              'NEW CUSTOM TEMPLATE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Template Name (e.g., Kaftan, Waistcoat)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Measurement Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _fieldControllers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _fieldControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Field ${index + 1} (e.g., Chest, Arm Hole)',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                              ),
                            ),
                            if (_fieldControllers.length > 1) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _removeField(index),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _addField,
                    icon: Icon(Icons.add_circle_outline_rounded, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor),
                    label: Text(
                      'Add Size Field', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveCategory,
                      child: const Text('Save Custom Template'),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Existing Custom Templates Section
            Text(
              'EXISTING TEMPLATES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
              ),
            ),
            const SizedBox(height: 12),

            if (provider.categories.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF101726) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECEAE2)),
                ),
                child: Text(
                  'No custom templates created yet.',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.categories.length,
                itemBuilder: (context, index) {
                  final cat = provider.categories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF101726) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECEAE2),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        cat.name.toUpperCase(), 
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: cat.fields.map((f) => Chip(
                            label: Text(f, style: const TextStyle(fontSize: 10)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          )).toList(),
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                        onPressed: () => _deleteCategory(cat),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
