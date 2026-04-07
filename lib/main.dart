// ================================================
// 1. lib/main.dart
// ================================================
import 'package:bengkel/presentation/blocs/customer_cubit.dart';
import 'package:bengkel/presentation/blocs/external_order_cubit.dart';
import 'package:bengkel/presentation/blocs/purchase_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/database/database_helper.dart';
import 'presentation/blocs/vehicle_cubit.dart';
import 'presentation/blocs/mechanic_cubit.dart';
import 'presentation/blocs/service_cubit.dart';
import 'presentation/blocs/part_cubit.dart';
import 'presentation/blocs/suppliers_cubit.dart';
import 'presentation/blocs/work_order_cubit.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting();
  Intl.defaultLocale = 'id';
  databaseFactory = databaseFactoryFfi;
  // Inisialisasi Database
  await DatabaseHelper.instance.database;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => VehicleCubit()..loadAll()),
        BlocProvider(create: (_) => MechanicCubit()..loadAll()),
        BlocProvider(create: (_) => ServiceCubit()..loadAll()),
        BlocProvider(create: (_) => PartCubit()..loadAll()),
        BlocProvider(create: (_) => SupplierCubit()..loadAll()),
        BlocProvider(create: (_) => WorkOrderCubit()..loadAll()),
        BlocProvider(create: (_) => CustomerCubit()..loadAll()),
        BlocProvider(create: (_) => PurchaseCubit()..loadAllPurchases()),
        BlocProvider(create: (_) => ExternalOrderBloc()),
      ],
      child: MaterialApp(
        title: 'Bengkel Manager Pro',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          fontFamily: 'Poppins',
        ),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
        home: const LoginScreen(),
      ),
    );
  }
}
