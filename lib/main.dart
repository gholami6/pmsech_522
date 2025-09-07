import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import './models/user_model.dart';
import './models/position_model.dart';
import './models/alert_notification.dart';
import './models/manager_alert.dart';
import './models/alert_reply.dart';
import './models/user_seen_status.dart';
import './models/production_data.dart';
import './models/stop_data.dart';
import './models/chat_message.dart';

import './models/shift_info.dart';
import './models/grade_data.dart';
import './models/equipment_location.dart';
import './services/auth_service.dart';
import './services/notification_service.dart';
import './services/grade_service.dart';
import './services/data_sync_service.dart';
import './services/simple_data_sync_service.dart';
import './services/alert_service.dart';
import './services/manager_alert_service.dart';
import './services/equipment_service.dart';
import './services/equipment_migration_service.dart';
import './services/encoding_service.dart';
import './services/server_notification_manager.dart';
import './providers/data_provider.dart';
import './screens/splash_screen.dart';
import './screens/login_screen.dart';
import './screens/register_screen.dart';
import './screens/main_dashboard_page.dart';
import './screens/new_alert_page.dart';
import './screens/new_manager_alert_page.dart';
import './screens/alerts_management_screen.dart';
import './screens/manager_alerts_screen.dart';
import './screens/grade_entry_screen.dart';
import './screens/production_screen.dart';
import './screens/stops_screen.dart';
import './screens/indicators_screen.dart';
import './screens/general_report_screen.dart';
import './screens/ai_assistant_page.dart';
import './screens/document_upload_screen.dart';
import './screens/equipment_location_screen.dart';
import './screens/grade_continuous_chart_screen.dart';
import 'package:flutter/services.dart';
import './services/grade_import_service.dart';
import './services/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // ثبت و باز کردن باکس‌های Hive
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(PositionModelAdapter());
  Hive.registerAdapter(AlertNotificationAdapter());
  Hive.registerAdapter(ManagerAlertAdapter());
  Hive.registerAdapter(AlertReplyAdapter());
  Hive.registerAdapter(UserSeenStatusAdapter());
  Hive.registerAdapter(ProductionDataAdapter());
  Hive.registerAdapter(StopDataAdapter());
  Hive.registerAdapter(ChatMessageAdapter());

  Hive.registerAdapter(ShiftInfoAdapter());
  Hive.registerAdapter(GradeDataAdapter());
  Hive.registerAdapter(EquipmentLocationAdapter());
  Hive.registerAdapter(RoleTypeAdapter());
  Hive.registerAdapter(StakeholderTypeAdapter());

  // بارگذاری تنبل (Lazy Loading) برای Hive Box‌ها
  // فقط باکس‌های ضروری در شروع بارگذاری می‌شوند
  await Hive.openBox<UserModel>('users');
  await Hive.openBox<String>('syncMeta');

  // سایر باکس‌ها هنگام نیاز بارگذاری می‌شوند
  print('ℹ️ بارگذاری تنبل Hive Box‌ها فعال شد');

  // اجرای مهاجرت نام تجهیزات در پس‌زمینه
  Future.microtask(() async {
    try {
      // پاک کردن نام‌های قدیمی برای اجرای مجدد مهاجرت
      await EquipmentMigrationService.clearEquipmentNames();
      print('🗑️ نام‌های قدیمی پاک شد');

      // اجرای مهاجرت
      await EquipmentMigrationService.migrateEquipmentNames();
      await EquipmentMigrationService.checkMigrationStatus();
      print('✅ مهاجرت نام تجهیزات تکمیل شد');

      // بررسی نهایی
      final equipmentNames =
          await EquipmentMigrationService.getAllEquipmentNames();
      print('📋 تعداد نام‌های تجهیزات نهایی: ${equipmentNames.length}');
      print('📋 نمونه نام‌ها: ${equipmentNames.entries.take(5).toList()}');

      // بررسی نتیجه مهاجرت
      await EquipmentMigrationService.checkMigrationResult();
    } catch (e) {
      print('⚠️ خطا در مهاجرت نام تجهیزات: $e');
    }
  });

  final authService = AuthService();
  await authService.init();
  await authService.resetToOnlyManagers();
  final dataSyncService = DataSyncService();
  await dataSyncService.init();
  final simpleDataSyncService = SimpleDataSyncService();
  await simpleDataSyncService.init();
  final equipmentService = EquipmentService();
  await equipmentService.init();
  final encodingService = EncodingService();
  final managerAlertService = ManagerAlertService(authService);

  // Initialize new services
  await NotificationService.initialize();
  await GradeService.initialize();

  // غیرفعال کردن سرویس نوتیفیکیشن سرور در حالت آفلاین
  print('🔧 سرویس نوتیفیکیشن سرور غیرفعال شده است');
  /*
  // راه‌اندازی سرویس نوتیفیکیشن سرور
  final serverNotificationManager =
      ServerNotificationManager.getInstance(authService);
  await serverNotificationManager.initialize();
  */

  // تلاش برای همگام‌سازی از سرور در شروع کار، و جلوگیری از seed مجدد
  final syncMeta = Hive.box<String>('syncMeta');
  final hasSeededBefore = syncMeta.get('grade_seeded_v2') == 'true';

  // غیرفعال کردن دانلود از سرور - استفاده از داده‌های محلی
  print('🔧 حالت آفلاین فعال - استفاده از داده‌های محلی');
  /*
  // ابتدا تلاش برای دانلود از سرور (با timeout)
  try {
    await GradeService.downloadGradesFromServer().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('⚠️ دانلود از سرور timeout شد، ادامه با داده‌های محلی');
        return false;
      },
    );
  } catch (e) {
    print('⚠️ خطا در دانلود از سرور: $e، ادامه با داده‌های محلی');
  }
  */

  var gradeCount = await GradeService.getTotalGradeRecords();
  if (gradeCount == 0 && !hasSeededBefore) {
    try {
      final csvString = await rootBundle.loadString('real_grades.csv');
      final result = await GradeImportService.importMultipleGradesPerShift(
        csvString: csvString,
        clearExisting: false,
      );
      // جلوگیری از seed در دفعات بعد
      await syncMeta.put('grade_seeded_v2', 'true');
      // ignore: avoid_print
      print('Initial seed result: $result');
    } catch (e) {
      // ignore: avoid_print
      print('Initial seed skipped/failed: $e');

      // اضافه کردن داده‌های تست برای نمودار
      try {
        await GradeService.addTestGradeDataForLast3Days();
        print('✅ داده‌های تست برای نمودار اضافه شد');
      } catch (testError) {
        print('⚠️ خطا در اضافه کردن داده‌های تست: $testError');
      }
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => authService),
        ChangeNotifierProvider(
          create: (_) =>
              AlertService(Provider.of<AuthService>(_, listen: false)),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              ManagerAlertService(Provider.of<AuthService>(_, listen: false)),
        ),
        ChangeNotifierProvider(create: (_) => dataSyncService),
        ChangeNotifierProvider(create: (_) => simpleDataSyncService),
        ChangeNotifierProvider(
          create: (_) => ServerNotificationManager.getInstance(
            Provider.of<AuthService>(_, listen: false),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => DataProvider(
            Provider.of<DataSyncService>(_, listen: false),
            Provider.of<SimpleDataSyncService>(_, listen: false),
          ),
        ),
        Provider(create: (_) => equipmentService),
        Provider(create: (_) => encodingService),
      ],
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: MaterialApp(
          navigatorKey: NavigationService.navigatorKey,
          title: 'سیستم مدیریت کارخانه',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFCFD8DC),
            cardTheme: const CardTheme(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
              margin: EdgeInsets.all(8),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              centerTitle: true,
              elevation: 0,
            ),
            navigationBarTheme: NavigationBarThemeData(
              backgroundColor: const Color(0xFF1E3A8A),
              indicatorColor: Colors.white.withOpacity(0.2),
              labelTextStyle: const MaterialStatePropertyAll(
                TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
              iconTheme: const MaterialStatePropertyAll(
                IconThemeData(color: Colors.white),
              ),
            ),
            fontFamily: 'Vazirmatn',
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
          ),
          initialRoute: '/splash',
          routes: {
            '/splash': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/dashboard': (_) => const MainDashboardPage(),
            '/new-alert': (_) => const NewAlertPage(),
            '/new-manager-alert': (_) => const NewManagerAlertPage(),
            '/alerts-management': (_) => const AlertsManagementScreen(),
            '/manager-alerts': (_) => const ManagerAlertsScreen(),
            '/grade-entry': (_) => const GradeEntryScreen(),
            '/production': (_) => const ProductionScreen(),
            '/stoppages': (_) => const StopsScreen(),
            '/indicators': (_) => const IndicatorsScreen(),
            '/reports': (_) => const GeneralReportScreen(),
            '/ai-assistant': (_) => const AIAssistantPage(),
            '/document-upload': (_) => const DocumentUploadScreen(),
            '/equipment-location': (_) => const EquipmentLocationScreen(),
            '/grade-continuous-chart': (_) =>
                const GradeContinuousChartScreen(),
          },
          onGenerateRoute: (settings) {
            return null;
          },
        ),
      ),
    ),
  );
}
