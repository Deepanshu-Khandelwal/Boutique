import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../models/measurement.dart';
import '../models/measurement_category.dart';
import '../providers/customer_provider.dart';
import './order_financial_details_screen.dart';

class AddMeasurementScreen extends StatefulWidget {
  const AddMeasurementScreen({
    super.key,
    required this.customer,
    this.measurement,
  });
  final Customer customer;
  final Measurement? measurement;

  @override
  State<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends State<AddMeasurementScreen> {
  String _selectedCategoryKey = 'outfit';
  ClothingType _selectedType = ClothingType.outfit;
  String? _selectedCustomCategoryName;

  final Map<String, TextEditingController> _controllers = {};
  final _noteController = TextEditingController();
  final List<File> _images = [];
  final _picker = ImagePicker();

  // Hardcoded default templates
  final Map<ClothingType, List<String>> _defaultTemplates = {
    ClothingType.outfit: ['Length', 'Shoulder', 'Chest', 'Waist', 'Sleeve', 'Cuff', 'Round Neck', 'Arm Hole', 'Bottom'],
    ClothingType.shirt: ['Length', 'Shoulder', 'Chest', 'Waist', 'Sleeve', 'Neck', 'Arm Hole'],
    ClothingType.trouser: ['Length', 'Waist', 'Seat/Hip', 'Thigh', 'Knee', 'Bottom', 'Inseam'],
    ClothingType.dress: ['Full Length', 'Shoulder', 'Bust', 'Waist', 'Hip', 'Sleeve', 'Arm Hole', 'Front Neck', 'Back Neck'],
    ClothingType.blouse: ['Length', 'Shoulder', 'Bust', 'Under Bust', 'Sleeve', 'Cuff', 'Front Neck', 'Back Neck'],
    ClothingType.skirt: ['Length', 'Waist', 'Hip', 'Flare'],
    ClothingType.custom: [],
  };

  late Map<ClothingType, List<String>> _templates;

  @override
  void initState() {
    super.initState();
    _templates = Map.from(_defaultTemplates);

    if (widget.measurement != null) {
      _selectedType = widget.measurement!.type;
      _selectedCustomCategoryName = widget.measurement!.customCategoryName;
      _selectedCategoryKey = _selectedType == ClothingType.custom 
          ? 'custom:$_selectedCustomCategoryName' 
          : _selectedType.name;
      _noteController.text = widget.measurement!.note ?? '';
      _updateControllers();
      _fillFromMeasurement(widget.measurement!);
      if (widget.measurement!.photos != null) {
        _images.addAll(widget.measurement!.photos!.map((p) => File(p)));
      }
    } else {
      _updateControllers();
    }
  }



  void _fillFromMeasurement(Measurement m) {
    m.values.forEach((key, value) {
      if (_controllers.containsKey(key)) {
        _controllers[key]!.text = value.toString();
      }
    });
  }

  void _updateControllers() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    
    List<String> fields = [];
    if (_selectedType == ClothingType.custom && _selectedCustomCategoryName != null) {
      final provider = Provider.of<CustomerProvider>(context, listen: false);
      final customCat = provider.categories.firstWhere(
        (c) => c.name == _selectedCustomCategoryName,
        orElse: () => MeasurementCategory(name: '', fields: []),
      );
      fields = customCat.fields;
    } else {
      fields = _templates[_selectedType] ?? [];
    }

    for (var field in fields) {
      _controllers[field] = TextEditingController();
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((pf) => File(pf.path)));
      });
    }
  }

  Future<void> _saveMeasurement() async {
    final values = <String, double>{};
    _controllers.forEach((key, controller) {
      final val = double.tryParse(controller.text) ?? 0.0;
      values[key] = val;
    });

    final provider = Provider.of<CustomerProvider>(context, listen: false);

    if (widget.measurement != null) {
      final updatedMeasurement = Measurement(
        id: widget.measurement!.id,
        customerId: widget.customer.id,
        type: _selectedType,
        customCategoryName: _selectedType == ClothingType.custom ? _selectedCustomCategoryName : null,
        values: values,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        photos: _images.isNotEmpty ? _images.map((f) => f.path).toList() : widget.measurement!.photos,
        deliveryDate: widget.measurement!.deliveryDate,
        date: widget.measurement!.date,
        status: widget.measurement!.status,
        totalPrice: widget.measurement!.totalPrice,
        paidAmount: widget.measurement!.paidAmount,
      );
      await provider.updateMeasurement(updatedMeasurement);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Measurement updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } else {
      final measurement = Measurement(
        customerId: widget.customer.id,
        type: _selectedType,
        customCategoryName: _selectedType == ClothingType.custom ? _selectedCustomCategoryName : null,
        values: values,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        photos: _images.map((f) => f.path).toList(),
      );
      await provider.addMeasurement(measurement);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderFinancialDetailsScreen(
              customer: widget.customer,
              measurement: measurement,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.measurement != null;
    final provider = Provider.of<CustomerProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Garment Details' : 'New Garment Record'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : theme.primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clothing Category Header
            Text(
              'GARMENT CATEGORY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101726) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECEAE2),
                  width: 1.2,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryKey,
                  decoration: const InputDecoration(border: InputBorder.none, filled: false, contentPadding: EdgeInsets.zero),
                  dropdownColor: isDark ? const Color(0xFF101726) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                  items: [
                    ...ClothingType.values
                        .where((t) => t != ClothingType.custom)
                        .map((t) => DropdownMenuItem(value: t.name, child: Text(t.name.toUpperCase()))),
                    ...provider.categories.map((c) => DropdownMenuItem(
                        value: 'custom:${c.name}', 
                        child: Text('${c.name.toUpperCase()} (TEMPLATE)'))),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategoryKey = value;
                        if (value.startsWith('custom:')) {
                          _selectedType = ClothingType.custom;
                          _selectedCustomCategoryName = value.replaceFirst('custom:', '');
                        } else {
                          _selectedType = ClothingType.values.firstWhere((t) => t.name == value);
                          _selectedCustomCategoryName = null;
                        }
                        _updateControllers();
                      });
                    }
                  },
                ),
              ),
            ),
             const SizedBox(height: 16),
             _buildReviewCard(theme, isDark, _getLatestMeasurement()),
 
             // Dimensions Fields Section
            Text(
              'GARMENT DIMENSIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
              ),
            ),
             const SizedBox(height: 8),
             
             if (_controllers.isEmpty)
               Container(
                 padding: const EdgeInsets.all(24),
                 alignment: Alignment.center,
                 child: Text('This template has no dimensions fields configured.', style: TextStyle(color: Colors.grey.shade500)),
               )
             else
               GridView.builder(
                 shrinkWrap: true,
                 physics: const NeverScrollableScrollPhysics(),
                 gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                   crossAxisCount: 2,
                   childAspectRatio: 2.2,
                   crossAxisSpacing: 12,
                   mainAxisSpacing: 12,
                 ),
                 itemCount: _controllers.length,
                itemBuilder: (context, index) {
                  final field = _controllers.keys.elementAt(index);
                  return TextFormField(
                    controller: _controllers[field],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: field,
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                       contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                     ),
                   );
                 },
               ),
             const SizedBox(height: 16),
 
             // Reference Photos Section
             Text(
               'REFERENCE IMAGES',
               style: TextStyle(
                 fontSize: 11,
                 fontWeight: FontWeight.bold,
                 letterSpacing: 1.5,
                 color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
               ),
             ),
             const SizedBox(height: 8),
             SizedBox(
               height: 90,
               child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._images.map(
                    (file) => Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECEAE2)),
                        image: file.existsSync()
                            ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                            : null,
                        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.05),
                      ),
                      child: file.existsSync()
                          ? Align(
                              alignment: Alignment.topRight,
                              child: GestureDetector(
                                onTap: () => setState(() => _images.remove(file)),
                                child: const CircleAvatar(
                                  radius: 11,
                                  backgroundColor: Colors.red,
                                  child: Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            )
                          : Center(
                              child: Icon(Icons.image_not_supported_rounded, color: Colors.grey.shade400, size: 18),
                            ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImages,
                    child: Container(
                      width: 90,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF101726) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFECEAE2),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Icon(
                        Icons.add_a_photo_rounded, 
                        color: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
             ),
             const SizedBox(height: 16),
 
             // Additional Notes Section
             Text(
               'SPECIAL INSTRUCTIONS',
               style: TextStyle(
                 fontSize: 11,
                 fontWeight: FontWeight.bold,
                 letterSpacing: 1.5,
                 color: isDark ? const Color(0xFFC5A880) : const Color(0xFF8E8B82),
               ),
             ),
             const SizedBox(height: 8),
             TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter custom cutting, stitching, or styling requirements...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              ),
             ),
             const SizedBox(height: 24),
 
             // Action Button
             SizedBox(
               width: double.infinity,
               child: ElevatedButton(
                 onPressed: _saveMeasurement,
                 child: Text(isEditing ? 'Update Garment Details' : 'Continue to Billing'),
               ),
             ),
             const SizedBox(height: 24),
           ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  Measurement? _getLatestMeasurement() {
    final provider = Provider.of<CustomerProvider>(context, listen: false);
    final previousMeasurements = provider.getMeasurementsByCustomerId(widget.customer.id);
    if (previousMeasurements.isEmpty) return null;
    
    final sameType = previousMeasurements.where((m) {
      if (_selectedType == ClothingType.custom) {
        return m.type == ClothingType.custom && m.customCategoryName == _selectedCustomCategoryName;
      }
      return m.type == _selectedType;
    }).toList();
    
    return sameType.isNotEmpty ? sameType.last : null;
  }

  Widget _buildReviewCard(ThemeData theme, bool isDark, Measurement? latest) {
    if (latest == null) return const SizedBox.shrink();
    
    final dateStr = DateFormat.yMMMd().format(latest.date);
    final valuesList = latest.values.entries.map((e) => '${e.key}: ${e.value}').toList();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFFC5A880).withValues(alpha: 0.08) 
            : theme.primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark 
              ? const Color(0xFFC5A880).withValues(alpha: 0.2) 
              : theme.primaryColor.withValues(alpha: 0.1),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.history_rounded, 
                      color: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Last Record Review ($dateStr)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      setState(() {
                        _fillFromMeasurement(latest);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Previous measurements loaded!'),
                          duration: Duration(seconds: 1),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: Icon(Icons.copy_rounded, size: 14, color: isDark ? const Color(0xFFC5A880) : theme.primaryColor),
                    label: Text(
                      'Use These', 
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: isDark ? const Color(0xFFC5A880) : theme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      setState(() {
                        _controllers.forEach((key, controller) {
                          controller.clear();
                        });
                      });
                    },
                    icon: const Icon(Icons.clear_all_rounded, size: 14, color: Colors.red),
                    label: const Text(
                      'Clear', 
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: valuesList.map((val) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFECEAE2),
                ),
              ),
              child: Text(
                val,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}


