import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api/v1';
    }
    // For Windows desktop or web
    return 'http://127.0.0.1:8000/api/v1';
  }

  // Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';

  static const String menusDaily = '/menus/daily';
  static const String menus = '/menus/';

  static const String prices = '/prices/';
  static const String priceHistory = '/prices/history';

  static const String myBookings = '/bookings/my';
  static const String bookings = '/bookings/';
  static const String bookingForDate = '/bookings/for-date';
  static const String adminBookingOverride = '/bookings/admin-override';
  static const String adminBookingSummary = '/bookings/admin/summary';

  static const String recordConsumption = '/consumption/record';
  static const String batchConsumption = '/consumption/batch-record';
  static const String consumptionSummary = '/consumption/summary';
  static const String studentExpenses = '/consumption/student-expenses';

  static const String kitchenPrep = '/reports/kitchen-prep';
  static const String dailyReport = '/reports/daily';
  static const String monthlyReport = '/reports/monthly';
  static const String exportCsv = '/reports/export-csv';

  static const String notifications = '/notifications/';
  static const String triggerReminders = '/notifications/trigger-reminders';

  static const String users = '/users/';
}
