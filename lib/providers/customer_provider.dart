import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import '../utils/backup_helper.dart' as backup;
import '../main.dart';
import '../models/customer.dart';
import '../models/measurement.dart';
import '../models/measurement_category.dart';

class CustomerProvider with ChangeNotifier {
  static const String customerBoxName = 'customers';
  static const String measurementBoxName = 'measurements';
  static const String categoryBoxName = 'categories';

  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  final String _currencySymbol = '₹';
  String get currencySymbol => _currencySymbol;

  // Locked to INR only
  void setCurrency(String symbol) {
    // No-op
  }

  String formatPrice(double price) {
    return '$_currencySymbol${price.toStringAsFixed(0)}';
  }

  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  List<Measurement> _measurements = [];
  List<Measurement> get measurements => _measurements;

  List<MeasurementCategory> _categories = [];
  List<MeasurementCategory> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Stats for Dashboard
  double get totalRevenue => _measurements.fold(0.0, (sum, m) => sum + m.totalPrice);
  double get totalCollected => _measurements.fold(0.0, (sum, m) => sum + m.paidAmount);
  double get outstandingBalance => totalRevenue - totalCollected;
  int get activeOrdersCount => _measurements.where((m) => m.status != MeasurementStatus.delivered).length;
  
  List<Measurement> get upcomingDeliveries {
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));
    return _measurements.where((m) {
      if (m.deliveryDate == null || m.status == MeasurementStatus.delivered) return false;
      return m.deliveryDate!.isAfter(now.subtract(const Duration(days: 1))) && 
             m.deliveryDate!.isBefore(threeDaysFromNow);
    }).toList();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final customerBox = await Hive.openBox<Customer>(customerBoxName);
    final measurementBox = await Hive.openBox<Measurement>(measurementBoxName);
    final categoryBox = await Hive.openBox<MeasurementCategory>(categoryBoxName);

    _customers = customerBox.values.toList();
    _measurements = measurementBox.values.toList();
    _categories = categoryBox.values.toList();

    _isLoading = false;
    notifyListeners();
  }

  // --- Customer Methods ---
  Future<void> addCustomer(Customer customer) async {
    try {
      final box = await Hive.openBox<Customer>(customerBoxName);
      await box.put(customer.id, customer);
      _customers.add(customer);
      notifyListeners();
    } catch (e) {
      throw Exception('Error adding customer: $e');
    }
  }

  Future<void> updateCustomer(Customer customer) async {
    final box = await Hive.openBox<Customer>(customerBoxName);
    await box.put(customer.id, customer);
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(String id) async {
    final box = await Hive.openBox<Customer>(customerBoxName);
    await box.delete(id);
    _customers.removeWhere((c) => c.id == id);
    
    final mBox = await Hive.openBox<Measurement>(measurementBoxName);
    final measurementIdsToRemove = _measurements
        .where((m) => m.customerId == id)
        .map((m) => m.id)
        .toList();
    for (final mId in measurementIdsToRemove) {
      await mBox.delete(mId);
    }
    _measurements.removeWhere((m) => m.customerId == id);
    
    notifyListeners();
  }

  // --- Measurement Methods ---
  Future<void> addMeasurement(Measurement measurement) async {
    try {
      final box = await Hive.openBox<Measurement>(measurementBoxName);
      await box.put(measurement.id, measurement);
      _measurements.add(measurement);
      
      if (measurement.deliveryDate != null) {
        await scheduleDeliveryNotification(measurement);
      }
      
      notifyListeners();
    } catch (e) {
      throw Exception('Error adding measurement: $e');
    }
  }

  Future<void> updateMeasurement(Measurement measurement) async {
    try {
      final box = await Hive.openBox<Measurement>(measurementBoxName);
      if (measurement.status == MeasurementStatus.delivered) {
        measurement.paidAmount = measurement.totalPrice;
      }
      await box.put(measurement.id, measurement);
      final index = _measurements.indexWhere((m) => m.id == measurement.id);
      if (index != -1) {
        _measurements[index] = measurement;
        
        if (measurement.deliveryDate != null) {
          await scheduleDeliveryNotification(measurement);
        }
        
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Error updating measurement: $e');
    }
  }

  Future<void> updateMeasurementStatus(String id, MeasurementStatus status) async {
    try {
      final box = await Hive.openBox<Measurement>(measurementBoxName);
      final index = _measurements.indexWhere((m) => m.id == id);
      if (index != -1) {
        _measurements[index].status = status;
        if (status == MeasurementStatus.delivered) {
          _measurements[index].paidAmount = _measurements[index].totalPrice;
        }
        await box.put(id, _measurements[index]);
        notifyListeners();
      } else {
        throw Exception('Measurement not found');
      }
    } catch (e) {
      throw Exception('Error updating measurement status: $e');
    }
  }

  Future<void> updateMeasurementFinance(String id, double total, double paid) async {
    final box = await Hive.openBox<Measurement>(measurementBoxName);
    final index = _measurements.indexWhere((m) => m.id == id);
    if (index != -1) {
      _measurements[index].totalPrice = total;
      _measurements[index].paidAmount = paid;
      await box.put(id, _measurements[index]);
      notifyListeners();
    }
  }

  List<Measurement> getMeasurementsByCustomerId(String customerId) {
    return _measurements.where((m) => m.customerId == customerId).toList();
  }

  // --- Category Methods ---
  Future<void> addCategory(MeasurementCategory category) async {
    final box = await Hive.openBox<MeasurementCategory>(categoryBoxName);
    await box.put(category.id, category);
    _categories.add(category);
    notifyListeners();
  }

  // --- External Integrations ---
  Future<void> generateInovice(Customer customer, Measurement measurement) async {
    try {
      final pdf = pw.Document();

      // Load fonts dynamically with a robust offline fallback to Helvetica
      pw.Font regularFont;
      pw.Font boldFont;
      try {
        regularFont = await PdfGoogleFonts.outfitRegular();
        boldFont = await PdfGoogleFonts.outfitBold();
      } catch (e) {
        regularFont = pw.Font.helvetica();
        boldFont = pw.Font.helveticaBold();
      }

      // Design system colors based on AppTheme
      final primaryColor = PdfColor.fromHex('#0B132B'); // Luxury Deep Slate Navy
      final accentColor = PdfColor.fromHex('#C5A880');  // Champagne Gold
      final textColor = PdfColor.fromHex('#1C1C1E');    // Warm Dark Gray
      final subtextColor = PdfColor.fromHex('#6E788C'); // Slate Muted Gray
      final dividerColor = PdfColor.fromHex('#ECEAE2');
      final lightBgColor = PdfColor.fromHex('#FAF9F6');  // Soft Cream

      // Status Badge Widget Generator
      pw.Widget buildPdfStatusBadge(MeasurementStatus status) {
        String label = 'Not Started';
        PdfColor bgColor = PdfColor.fromHex('#F1F5F9');
        PdfColor fgColor = PdfColor.fromHex('#475569');

        switch (status) {
          case MeasurementStatus.notStarted:
            label = 'Not Started';
            bgColor = PdfColor.fromHex('#F1F5F9');
            fgColor = PdfColor.fromHex('#475569');
            break;
          case MeasurementStatus.cutting:
            label = 'Cutting';
            bgColor = PdfColor.fromHex('#FEF3C7');
            fgColor = PdfColor.fromHex('#D97706');
            break;
          case MeasurementStatus.stitching:
            label = 'Stitching';
            bgColor = PdfColor.fromHex('#E0F2FE');
            fgColor = PdfColor.fromHex('#0284C7');
            break;
          case MeasurementStatus.readyForTrial:
            label = 'Ready For Trial';
            bgColor = PdfColor.fromHex('#F3E8FF');
            fgColor = PdfColor.fromHex('#9333EA');
            break;
          case MeasurementStatus.completed:
            label = 'Completed';
            bgColor = PdfColor.fromHex('#DCFCE7');
            fgColor = PdfColor.fromHex('#16A34A');
            break;
          case MeasurementStatus.delivered:
            label = 'Delivered';
            bgColor = PdfColor.fromHex('#ECFDF5');
            fgColor = PdfColor.fromHex('#059669');
            break;
        }

        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: pw.BoxDecoration(
            color: bgColor,
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 8,
              font: boldFont,
              color: fgColor,
            ),
          ),
        );
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          theme: pw.ThemeData.withFont(
            base: regularFont,
            bold: boldFont,
          ),
          build: (pw.Context context) {
            final balance = measurement.totalPrice - measurement.paidAmount;
            final isBalanceDue = balance > 0;

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 1. BRANDING HEADER
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'KHANDELWAL BOUTIQUE',
                          style: pw.TextStyle(
                            font: boldFont,
                            fontSize: 22,
                            color: primaryColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'CRAFTING ELEGANCE, TAILORING PERFECT FIT',
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            font: regularFont,
                            color: accentColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: primaryColor,
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Text(
                            'INVOICE',
                            style: pw.TextStyle(
                              font: boldFont,
                              fontSize: 13,
                              color: PdfColors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          '#INV-${measurement.id.substring(0, 8).toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            font: boldFont,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(color: accentColor, thickness: 1.5),
                pw.SizedBox(height: 20),

                // 2. CLIENT & INVOICE DETAILS
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Client Details
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'BILL TO:',
                            style: pw.TextStyle(
                              fontSize: 9,
                              font: boldFont,
                              color: subtextColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            customer.name,
                            style: pw.TextStyle(
                              fontSize: 15,
                              font: boldFont,
                              color: primaryColor,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Phone: ${customer.phone}',
                            style: pw.TextStyle(
                              fontSize: 10.5,
                              color: textColor,
                            ),
                          ),
                          if (customer.email != null && customer.email!.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Email: ${customer.email}',
                              style: pw.TextStyle(
                                fontSize: 10.5,
                                color: textColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Invoice details
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text('Date: ', style: pw.TextStyle(font: boldFont, fontSize: 10.5, color: textColor)),
                              pw.Text(measurement.date.toString().substring(0, 10), style: const pw.TextStyle(fontSize: 10.5)),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text('Delivery Date: ', style: pw.TextStyle(font: boldFont, fontSize: 10.5, color: textColor)),
                              pw.Text(
                                measurement.deliveryDate != null
                                    ? measurement.deliveryDate!.toString().substring(0, 10)
                                    : 'N/A',
                                style: const pw.TextStyle(fontSize: 10.5),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Text('Status: ', style: pw.TextStyle(font: boldFont, fontSize: 10.5, color: textColor)),
                              pw.SizedBox(width: 4),
                              buildPdfStatusBadge(measurement.status),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 28),

                // 3. ORDER SUMMARY TABLE
                pw.Text(
                  'ORDER SUMMARY',
                  style: pw.TextStyle(
                    fontSize: 9,
                    font: boldFont,
                    color: subtextColor,
                    letterSpacing: 1.0,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: dividerColor, width: 0.8),
                    bottom: pw.BorderSide(color: primaryColor, width: 1.5),
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: primaryColor),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: pw.Text(
                            'GARMENT TYPE / DESCRIPTION',
                            style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: pw.Text(
                            'DELIVERY DATE',
                            style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: pw.Text(
                            'TOTAL PRICE',
                            style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.white),
                          ),
                        ),
                      ],
                    ),
                    // Table Item Row
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: lightBgColor),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                measurement.type == ClothingType.custom && measurement.customCategoryName != null
                                    ? measurement.customCategoryName!
                                    : measurement.type.name.toUpperCase(),
                                style: pw.TextStyle(font: boldFont, fontSize: 11, color: primaryColor),
                              ),
                              if (measurement.note != null && measurement.note!.isNotEmpty) ...[
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  measurement.note!,
                                  style: pw.TextStyle(fontSize: 8.5, color: subtextColor, font: regularFont),
                                ),
                              ],
                            ],
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: pw.Text(
                            measurement.deliveryDate != null
                                ? measurement.deliveryDate!.toString().substring(0, 10)
                                : 'N/A',
                            style: pw.TextStyle(fontSize: 10.5, color: textColor),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          child: pw.Text(
                            '$currencySymbol${measurement.totalPrice.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: boldFont, fontSize: 10.5, color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),

                // 4. MEASUREMENTS SPECIFICATION
                if (measurement.values.isNotEmpty) ...[
                  pw.Text(
                    'MEASUREMENTS SPECIFICATION',
                    style: pw.TextStyle(
                      fontSize: 9,
                      font: boldFont,
                      color: subtextColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: dividerColor, width: 1.0),
                      borderRadius: pw.BorderRadius.circular(8),
                      color: PdfColors.white,
                    ),
                    child: pw.Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: measurement.values.entries.map((entry) {
                        return pw.Container(
                          width: 80, // Nicely sized grid boxes
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                entry.key.toUpperCase(),
                                style: pw.TextStyle(
                                  fontSize: 7.5,
                                  font: boldFont,
                                  color: subtextColor,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                '${entry.value.toStringAsFixed(1)}"',
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  font: boldFont,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  pw.SizedBox(height: 24),
                ],

                // 5. TOTALS AND TERMS
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Terms or Notes
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'TERMS & INSTRUCTIONS:',
                            style: pw.TextStyle(
                              fontSize: 8,
                              font: boldFont,
                              color: subtextColor,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            '1. Standard alteration timeframe is 7 days from collection.\n'
                            '2. Please retain this invoice for trial and collection.\n'
                            '3. Double-check measurements before final handoff.',
                            style: pw.TextStyle(
                              fontSize: 7,
                              lineSpacing: 1.5,
                              color: subtextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 40),
                    // Totals
                    pw.Container(
                      width: 180,
                      child: pw.Column(
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 10, color: subtextColor)),
                              pw.Text('$currencySymbol${measurement.totalPrice.toStringAsFixed(2)}',
                                  style: pw.TextStyle(fontSize: 10, color: textColor)),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Amount Paid:', style: pw.TextStyle(fontSize: 10, color: subtextColor)),
                              pw.Text('$currencySymbol${measurement.paidAmount.toStringAsFixed(2)}',
                                  style: pw.TextStyle(fontSize: 10, color: textColor)),
                            ],
                          ),
                          pw.SizedBox(height: 8),
                          pw.Divider(color: dividerColor),
                          pw.SizedBox(height: 6),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: pw.BoxDecoration(
                              color: isBalanceDue ? PdfColor.fromHex('#FEF2F2') : PdfColor.fromHex('#F0FDF4'),
                              borderRadius: pw.BorderRadius.circular(6),
                            ),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Balance Due:',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    font: boldFont,
                                    color: isBalanceDue ? PdfColor.fromHex('#991B1B') : PdfColor.fromHex('#166534'),
                                  ),
                                ),
                                pw.Text(
                                  '$currencySymbol${balance.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    font: boldFont,
                                    color: isBalanceDue ? PdfColor.fromHex('#991B1B') : PdfColor.fromHex('#166534'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),
                pw.Divider(color: dividerColor),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      font: regularFont,
                      fontSize: 10.5,
                      color: primaryColor,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'Khandelwal Boutique | Elegance in Every Stitch',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      color: subtextColor,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'invoice_${customer.name}.pdf');
    } catch (e) {
      throw Exception('Error generating invoice: $e');
    }
  }

  Future<void> scheduleDeliveryNotification(Measurement measurement) async {
    try {
      if (measurement.deliveryDate == null) return;

      final customer = _customers.firstWhere(
        (c) => c.id == measurement.customerId,
        orElse: () => throw Exception('Customer not found'),
      );
      
      // Schedule notification 1 day before delivery at 9 AM
      final scheduledDate = measurement.deliveryDate!.subtract(const Duration(days: 1));
      final displayDate = tz.TZDateTime.from(
        DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day, 9, 0),
        tz.local,
      );

      if (displayDate.isBefore(tz.TZDateTime.now(tz.local))) return;

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'delivery_reminders',
        'Delivery Reminders',
        channelDescription: 'Notifications for upcoming garment deliveries',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: measurement.id.hashCode,
        title: 'Delivery Reminder',
        body: 'The ${measurement.type.name} for ${customer.name} is due tomorrow!',
        scheduledDate: displayDate,
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // Silently fail for notification scheduling - not critical
      debugPrint('Error scheduling delivery notification: $e');
    }
  }

  Future<void> _launchWhatsAppUrl(String url) async {
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

  Future<void> openWhatsApp(Customer customer, Measurement measurement) async {
    try {
      final balance = measurement.totalPrice - measurement.paidAmount;
      final text = 'Hello ${customer.name}, here are the details for your ${measurement.type.name.toUpperCase()} at Khandelwal Boutique.\n'
          'Delivery Date: ${measurement.deliveryDate?.toString().substring(0, 10) ?? 'N/A'}\n'
          'Balance Due: $currencySymbol${balance.toStringAsFixed(0)}\n'
          'Thank you for your business!';
      
      String cleanPhone = customer.phone.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.length == 10) {
        cleanPhone = '91$cleanPhone';
      }
      
      final url = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(text)}';
      await _launchWhatsAppUrl(url);
    } catch (e) {
      throw Exception('Error opening WhatsApp: $e');
    }
  }

  Future<void> sendWelcomeWhatsApp(Customer customer) async {
    try {
      final text = 'Hello ${customer.name},\n'
          'Thank you for visiting Khandelwal Boutique! We have successfully registered your client profile.\n'
          'We look forward to styling you soon! ✨';
      
      String cleanPhone = customer.phone.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.length == 10) {
        cleanPhone = '91$cleanPhone';
      }
      
      final url = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(text)}';
      await _launchWhatsAppUrl(url);
    } catch (e) {
      throw Exception('Error opening WhatsApp: $e');
    }
  }

  Future<void> sendOrderReadyWhatsApp(Customer customer, Measurement measurement) async {
    try {
      final balance = measurement.totalPrice - measurement.paidAmount;
      final text = 'Hello ${customer.name},\n'
          'Great news! Your order for ${measurement.type.name.toUpperCase()} is completed and ready for trial/collection at Khandelwal Boutique. 🎉\n'
          'Balance Due: $currencySymbol${balance.toStringAsFixed(0)}\n'
          'Please visit us soon!';
      
      String cleanPhone = customer.phone.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.length == 10) {
        cleanPhone = '91$cleanPhone';
      }
      
      final url = 'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(text)}';
      await _launchWhatsAppUrl(url);
    } catch (e) {
      throw Exception('Error opening WhatsApp: $e');
    }
  }

  List<Customer> searchCustomers(String query, {MeasurementStatus? status}) {
    List<Customer> filtered = _customers;
    if (query.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(query.toLowerCase()) ||
            c.phone.contains(query);
      }).toList();
    }
    
    if (status != null) {
      filtered = filtered.where((c) {
        final customerMeasurements = getMeasurementsByCustomerId(c.id);
        return customerMeasurements.any((m) => m.status == status);
      }).toList();
    }
    
    return filtered;
  }

  // --- Backup & Restore Methods ---
  String exportBackupJson() {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'customers': _customers.map((c) => {
        'id': c.id,
        'name': c.name,
        'phone': c.phone,
        'email': c.email,
        'createdAt': c.createdAt.toIso8601String(),
        'photoPath': c.photoPath,
        'birthday': c.birthday?.toIso8601String(),
        'notes': c.notes,
      }).toList(),
      'measurements': _measurements.map((m) => {
        'id': m.id,
        'customerId': m.customerId,
        'type': m.type.name,
        'values': m.values,
        'note': m.note,
        'date': m.date.toIso8601String(),
        'photos': m.photos,
        'deliveryDate': m.deliveryDate?.toIso8601String(),
        'status': m.status.name,
        'totalPrice': m.totalPrice,
        'paidAmount': m.paidAmount,
        'customCategoryName': m.customCategoryName,
      }).toList(),
      'categories': _categories.map((cat) => {
        'id': cat.id,
        'name': cat.name,
        'fields': cat.fields,
      }).toList(),
    };
    return jsonEncode(data);
  }

  Future<void> importBackupJson(String jsonStr) async {
    final Map<String, dynamic> data = jsonDecode(jsonStr);
    
    if (!data.containsKey('customers') || !data.containsKey('measurements')) {
      throw Exception('Invalid backup file structure.');
    }
    
    final customerBox = await Hive.openBox<Customer>(customerBoxName);
    final measurementBox = await Hive.openBox<Measurement>(measurementBoxName);
    final categoryBox = await Hive.openBox<MeasurementCategory>(categoryBoxName);
    
    await customerBox.clear();
    await measurementBox.clear();
    await categoryBox.clear();
    
    _customers.clear();
    _measurements.clear();
    _categories.clear();

    final List<dynamic> jsonCustomers = data['customers'] ?? [];
    for (var jc in jsonCustomers) {
      final customer = Customer(
        id: jc['id'],
        name: jc['name'],
        phone: jc['phone'],
        email: jc['email'],
        createdAt: jc['createdAt'] != null ? DateTime.parse(jc['createdAt']) : null,
        photoPath: jc['photoPath'],
        birthday: jc['birthday'] != null ? DateTime.parse(jc['birthday']) : null,
        notes: jc['notes'],
      );
      await customerBox.put(customer.id, customer);
      _customers.add(customer);
    }

    if (data.containsKey('categories')) {
      final List<dynamic> jsonCategories = data['categories'] ?? [];
      for (var jcat in jsonCategories) {
        final category = MeasurementCategory(
          id: jcat['id'],
          name: jcat['name'],
          fields: List<String>.from(jcat['fields'] ?? []),
        );
        await categoryBox.put(category.id, category);
        _categories.add(category);
      }
    }

    final List<dynamic> jsonMeasurements = data['measurements'] ?? [];
    for (var jm in jsonMeasurements) {
      final type = ClothingType.values.firstWhere(
        (t) => t.name == jm['type'],
        orElse: () => ClothingType.custom,
      );
      final status = MeasurementStatus.values.firstWhere(
        (s) => s.name == jm['status'],
        orElse: () => MeasurementStatus.notStarted,
      );
      final measurement = Measurement(
        id: jm['id'],
        customerId: jm['customerId'],
        type: type,
        values: Map<String, double>.from(
          (jm['values'] as Map<dynamic, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
          ),
        ),
        note: jm['note'],
        date: jm['date'] != null ? DateTime.parse(jm['date']) : null,
        photos: jm['photos'] != null ? List<String>.from(jm['photos']) : null,
        deliveryDate: jm['deliveryDate'] != null ? DateTime.parse(jm['deliveryDate']) : null,
        status: status,
        totalPrice: (jm['totalPrice'] as num? ?? 0.0).toDouble(),
        paidAmount: (jm['paidAmount'] as num? ?? 0.0).toDouble(),
        customCategoryName: jm['customCategoryName'],
      );
      await measurementBox.put(measurement.id, measurement);
      _measurements.add(measurement);
    }
    
    notifyListeners();
  }

  Future<void> exportDatabase() async {
    final jsonStr = exportBackupJson();
    await backup.saveBackupFile(jsonStr, 'khandelwal_boutique_backup.json');
  }

  Future<void> importDatabase() async {
    final jsonStr = await backup.pickBackupFile();
    if (jsonStr != null && jsonStr.isNotEmpty) {
      await importBackupJson(jsonStr);
    } else {
      throw Exception('No backup file selected.');
    }
  }
}
