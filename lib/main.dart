import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/service_locator.dart' as sl;
import 'app/app.dart';
import 'app/routes/app_routes.dart';
import 'app/settings/app_settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  await Firebase.initializeApp();

  await sl.setupServiceLocator();

  // CHIẾN LƯỢC: ĐƯA NGƯỜI DÙNG VÀO TRANG CHỦ BÁC SĨ ĐỂ KIỂM THỬ CHỨC NĂNG
  const initialRoute = AppRoutes.doctorHome;

  final settingsController = AppSettingsController(
    sharedPreferences: sl.getIt(),
  );
  await settingsController.load();

  if (!sl.getIt.isRegistered<AppSettingsController>()) {
    sl.getIt.registerSingleton<AppSettingsController>(settingsController);
  }

  runApp(
    HospitalBookingApp(
      initialRoute: initialRoute,
      settingsController: settingsController,
    ),
  );
}
