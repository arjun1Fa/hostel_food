import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../auth/models/user_model.dart';
import '../../student/models/menu_model.dart';
import '../models/admin_models.dart';

String getTodayStr() => DateFormat('yyyy-MM-dd').format(DateTime.now());
String getTomorrowStr() => DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));

// 1. Admin Dashboard State
class AdminDashboardState {
  final bool isLoading;
  final int totalStudents;
  final int todayBreakfastPortions;
  final int todayLunchPortions;
  final int todayDinnerPortions;
  final int tomorrowBreakfastPortions;
  final int tomorrowLunchPortions;
  final int tomorrowDinnerPortions;
  final double todayRevenue;
  final MealPricesModel prices;
  final DailyMealsModel? todayMeals;
  final DailyMealsModel? tomorrowMeals;
  final String? errorMessage;

  AdminDashboardState({
    this.isLoading = false,
    this.totalStudents = 0,
    this.todayBreakfastPortions = 0,
    this.todayLunchPortions = 0,
    this.todayDinnerPortions = 0,
    this.tomorrowBreakfastPortions = 0,
    this.tomorrowLunchPortions = 0,
    this.tomorrowDinnerPortions = 0,
    this.todayRevenue = 0.0,
    MealPricesModel? prices,
    this.todayMeals,
    this.tomorrowMeals,
    this.errorMessage,
  }) : prices = prices ?? MealPricesModel(breakfast: 40, lunch: 80, dinner: 70);
}

class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  AdminDashboardNotifier() : super(AdminDashboardState(isLoading: true)) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    state = AdminDashboardState(isLoading: true);
    try {
      final todayStr = getTodayStr();
      final tomorrowStr = getTomorrowStr();

      // Fetch students
      final studentsRes = await apiClient.dio.get(ApiConstants.users);
      final studentCount = (studentsRes.data as List<dynamic>).length;

      // Fetch prices
      final pricesRes = await apiClient.dio.get(ApiConstants.prices);
      final prices = MealPricesModel.fromJson(pricesRes.data);

      // Fetch today's summary
      final todaySumRes = await apiClient.dio.get('${ApiConstants.adminBookingSummary}/$todayStr');
      final todaySum = todaySumRes.data;

      // Fetch tomorrow's summary
      final tomorrowSumRes = await apiClient.dio.get('${ApiConstants.adminBookingSummary}/$tomorrowStr');
      final tomorrowSum = tomorrowSumRes.data;

      // Fetch today's menus
      final todayMenuRes = await apiClient.dio.get('${ApiConstants.menusDaily}/$todayStr');
      final todayMeals = DailyMealsModel.fromJson(todayMenuRes.data);

      // Fetch tomorrow's menus
      final tomorrowMenuRes = await apiClient.dio.get('${ApiConstants.menusDaily}/$tomorrowStr');
      final tomorrowMeals = DailyMealsModel.fromJson(tomorrowMenuRes.data);

      // Fetch daily revenue report
      final repRes = await apiClient.dio.get('${ApiConstants.dailyReport}/$todayStr');
      final totalRevenue = (repRes.data['total_day_charges'] as num?)?.toDouble() ?? 0.0;

      state = AdminDashboardState(
        isLoading: false,
        totalStudents: studentCount,
        todayBreakfastPortions: todaySum['breakfast_count'] ?? 0,
        todayLunchPortions: todaySum['lunch_count'] ?? 0,
        todayDinnerPortions: todaySum['dinner_count'] ?? 0,
        tomorrowBreakfastPortions: tomorrowSum['breakfast_count'] ?? 0,
        tomorrowLunchPortions: tomorrowSum['lunch_count'] ?? 0,
        tomorrowDinnerPortions: tomorrowSum['dinner_count'] ?? 0,
        todayRevenue: totalRevenue,
        prices: prices,
        todayMeals: todayMeals,
        tomorrowMeals: tomorrowMeals,
      );
    } catch (e) {
      state = AdminDashboardState(isLoading: false, errorMessage: 'Failed to load dashboard metrics.');
    }
  }
}

final adminDashboardProvider = StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>((ref) {
  return AdminDashboardNotifier();
});

// 2. Admin Menus State
class AdminMenuNotifier extends StateNotifier<AsyncValue<DailyMealsModel>> {
  final String date;

  AdminMenuNotifier(this.date) : super(const AsyncValue.loading()) {
    loadDateMenu();
  }

  Future<void> loadDateMenu() async {
    state = const AsyncValue.loading();
    try {
      final res = await apiClient.dio.get('${ApiConstants.menusDaily}/$date');
      state = AsyncValue.data(DailyMealsModel.fromJson(res.data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> saveMenu({
    required String mealType,
    required String title,
    String? description,
    String? dietaryTags,
    required bool isPublished,
    required List<Map<String, dynamic>> dishes,
  }) async {
    try {
      await apiClient.dio.post(
        ApiConstants.menus,
        data: {
          'date': date,
          'meal_type': mealType,
          'title': title,
          'description': description,
          'dietary_tags': dietaryTags,
          'is_published': isPublished,
          'dishes': dishes,
        },
      );
      loadDateMenu();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> togglePublish(int menuId, bool isPublished) async {
    try {
      await apiClient.dio.patch('${ApiConstants.menus}$menuId/publish?is_published=$isPublished');
      loadDateMenu();
    } catch (_) {}
  }
}

final adminMenuDateProvider = StateNotifierProvider.family<AdminMenuNotifier, AsyncValue<DailyMealsModel>, String>((ref, date) {
  return AdminMenuNotifier(date);
});

// 3. Admin Prices State
class AdminPricesNotifier extends StateNotifier<AsyncValue<MealPricesModel>> {
  AdminPricesNotifier() : super(const AsyncValue.loading()) {
    loadPrices();
  }

  Future<void> loadPrices() async {
    state = const AsyncValue.loading();
    try {
      final res = await apiClient.dio.get(ApiConstants.prices);
      state = AsyncValue.data(MealPricesModel.fromJson(res.data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> updatePrices(double b, double l, double d) async {
    try {
      final res = await apiClient.dio.put(
        ApiConstants.prices,
        data: {'breakfast': b, 'lunch': l, 'dinner': d},
      );
      state = AsyncValue.data(MealPricesModel.fromJson(res.data));
      return true;
    } catch (_) {
      return false;
    }
  }
}

final adminPricesProvider = StateNotifierProvider<AdminPricesNotifier, AsyncValue<MealPricesModel>>((ref) {
  return AdminPricesNotifier();
});

// Price History Provider
final priceHistoryProvider = FutureProvider<List<PriceHistoryItemModel>>((ref) async {
  final res = await apiClient.dio.get(ApiConstants.priceHistory);
  return (res.data as List<dynamic>)
      .map((item) => PriceHistoryItemModel.fromJson(item as Map<String, dynamic>))
      .toList();
});

// 4. Admin Students State
final adminStudentsProvider = FutureProvider<List<UserModel>>((ref) async {
  final res = await apiClient.dio.get(ApiConstants.users);
  return (res.data as List<dynamic>)
      .map((item) => UserModel.fromJson(item as Map<String, dynamic>))
      .toList();
});

// 5. Admin Bookings for Date Provider
final adminBookingsForDateProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, date) async {
  final res = await apiClient.dio.get('${ApiConstants.adminBookingSummary}/$date');
  return res.data as Map<String, dynamic>;
});

// 6. Admin Consumption for Date Provider
class AdminConsumptionNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  final String date;

  AdminConsumptionNotifier(this.date) : super(const AsyncValue.loading()) {
    loadConsumption();
  }

  Future<void> loadConsumption() async {
    state = const AsyncValue.loading();
    try {
      final res = await apiClient.dio.get('${ApiConstants.consumptionSummary}/$date');
      state = AsyncValue.data(res.data as Map<String, dynamic>);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> recordSingle({
    required int userId,
    required String mealType,
    required bool consumed,
    String? reason,
  }) async {
    try {
      await apiClient.dio.post(
        ApiConstants.recordConsumption,
        data: {
          'user_id': userId,
          'date': date,
          'meal_type': mealType,
          'consumed': consumed,
          'correction_reason': reason,
        },
      );
      loadConsumption();
      return true;
    } catch (_) {
      return false;
    }
  }
}

final adminConsumptionProvider = StateNotifierProvider.family<AdminConsumptionNotifier, AsyncValue<Map<String, dynamic>>, String>((ref, date) {
  return AdminConsumptionNotifier(date);
});

// 7. Kitchen Prep Sheet Provider
final kitchenPrepSheetProvider = FutureProvider.family<KitchenPrepSheetModel, String>((ref, date) async {
  final res = await apiClient.dio.get('${ApiConstants.kitchenPrep}/$date');
  return KitchenPrepSheetModel.fromJson(res.data as Map<String, dynamic>);
});
