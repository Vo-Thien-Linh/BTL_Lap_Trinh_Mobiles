import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/service_locator.dart' as sl;
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await sl.setupServiceLocator();
  await initializeDateFormatting('vi_VN');
  runApp(const HospitalBookingApp());
}
