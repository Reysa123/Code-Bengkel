// ================================================
// lib/core/constants/app_constants.dart
// ================================================

import 'package:flutter/material.dart';

class AppConstants async{
  final String response = await rootBundle.loadString('assets/images/apps.json');
    _config = json.decode(response);
   static const String appName= _config['name'];
    static const String appVersion = _config['version'];
  static const String companyName = _config['company_name'];
  static const String companyAddress = _config['address'];
  static const String companyPhone = _config['phone'];
  static const String logoPath = _config['logo_path'];
  // ==================== APP INFO ====================
 // static const String appName = 'Bengkel Manager Pro';
  // static const String appVersion = '1.0.0';
  // static const String companyName = 'Bengkel ABC';
  // static const String companyAddress = 'Jl. Raya Denpasar No. 123, Bali';
  // static const String companyPhone = '(0361) 123456';
  // static const String logoPath = 'images/logo.png';

  // ==================== DATABASE ====================
  static const String dbName = 'bengkel.db';
  static const int dbVersion = 1;

  // ==================== TABLE NAMES ====================
  static const String tableCustomers = 'customers';
  static const String tableVehicles = 'vehicles';
  static const String tableServices = 'services';
  static const String tableParts = 'parts';
  static const String tableMechanics = 'mechanics';
  static const String tableSuppliers = 'suppliers';
  static const String tableWorkOrders = 'work_orders';
  static const String tableWoItems = 'wo_items';
  static const String tablePurchases = 'purchases';
  static const String tablePurchaseItems = 'purchase_items';
  static const String tableExternalOrders = 'external_orders';
  static const String tablePayments = 'payments';

  // ==================== STATUS WORK ORDER ====================
  static const String statusPending = 'pending';
  static const String statusInProgress = 'on_progress';
  static const String statusCompleted = 'completed';
  static const String statusPaid = 'paid';
  static const String statusCancelled = 'cancelled';

  // ==================== ITEM TYPE ====================
  static const String itemTypeService = 'service';
  static const String itemTypePart = 'part';

  // ==================== COLORS ====================
  static const Color primaryColor = Color(0xFF3F51B5); // Indigo
  static const Color secondaryColor = Color(0xFF00BCD4); // Cyan
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFFC107);
  static const Color errorColor = Color(0xFFF44336);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  // ==================== TEXT STYLES ====================
  static const TextStyle headingStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  static const TextStyle titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );

  // ==================== CURRENCY FORMAT ====================
  static const String currencySymbol = 'Rp';
  static const String currencyLocale = 'id_ID';

  // ==================== DEFAULT VALUES ====================
  static const double defaultTax = 0.0; // pajak (bisa diubah nanti)
  static const int defaultQty = 1;
  static const double defaultHarga = 0.0;
}

class AppStrings {
  static const String noData = 'Belum ada data';
  static const String saveSuccess = 'Berhasil disimpan!';
  static const String saveFailed = 'Gagal menyimpan data';
  static const String deleteConfirm = 'Yakin ingin menghapus?';
  static const String requiredField = 'Field ini wajib diisi';
  static const String stokHabis = 'Stok part habis!';
}
