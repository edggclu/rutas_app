import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tzdata;

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones(); // horas en UTC, se muestran en America/Mexico_City
  await initializeDateFormatting('es_MX');
  runApp(const ProviderScope(child: TelyserApp()));
}
