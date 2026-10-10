import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/menu_model.dart';
import '../models/booking_model.dart';
import '../models/expense_model.dart';
import '../models/notification_model.dart';

// Helper for IST dates
String getTodayString() => DateFormat('yyyy-MM-dd').format(DateTime.now());
String getTomorrowString() => DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 1)));

// 1. Student Menus State
class StudentMenuState {
  final bool isLoading;
  final DailyMealsModel? todayMeals;
  final DailyMealsModel? tomorrowMeals;
  final MealPricesModel prices;
  final String? errorMessage;

  StudentMenuState({
    this.isLoading = false,
    this.todayMeals,
    this.tomorrowMeals,
    MealPricesModel? prices,
    this.errorMessage,
  }) : prices = prices ?? MealPricesModel(breakfast: 40, lunch: 80, dinner: 70);
}

class StudentMenuNotifier extends StateNotifier<StudentMenuState> {
  StudentMenuNotifier() : super(StudentMenuState(isLoading: true)) {
    loadMenus();
  }

  Future<void> loadMenus() async {
    state = StudentMenuState(isLoading: true);
    try {
      final todayStr = getTodayString();
      final tomorrowStr = getTomorrowString();

      // Fetch today's menu
      final todayRes = await apiClient.dio.get('${ApiConstants.menusDaily}/$todayStr');
      final todayMeals = DailyMealsModel.fromJson(todayRes.data);

      // Fetch tomorrow's menu
      final tomorrowRes = await apiClient.dio.get('${ApiConstants.menusDaily}/$tomorrowStr');
      final tomorrowMeals = DailyMealsModel.fromJson(tomorrowRes.data);

      // Fetch prices
      final pricesRes = await apiClient.dio.get(ApiConstants.prices);
      final prices = MealPricesModel.fromJson(pricesRes.data);

      state = StudentMenuState(
        isLoading: false,
        todayMeals: todayMeals,
        tomorrowMeals: tomorrowMeals,
        prices: prices,
      );
    } catch (e) {
      state = StudentMenuState(
        isLoading: false,
        errorMessage: 'Unable to load menus. Please check network connection.',
      );
    }
  }
}

final studentMenuProvider = StateNotifierProvider<StudentMenuNotifier, StudentMenuState>((ref) {
  return StudentMenuNotifier();
});

// 2. Student Booking State
class StudentBookingState {
  final bool isLoading;
  final bool isSaving;
  final BookingModel? committedBooking;
  // Draft selections
  final bool draftBreakfast;
  final bool draftLunch;
  final bool draftDinner;
  final bool isLocked;
  final String? errorMessage;
  final String? successMessage;

  StudentBookingState({
    this.isLoading = false,
    this.isSaving = false,
    this.committedBooking,
    this.draftBreakfast = false,
    this.draftLunch = false,
    this.draftDinner = false,
    this.isLocked = false,
    this.errorMessage,
    this.successMessage,
  });

  bool get hasUnsavedChanges {
    if (committedBooking == null) {
      return draftBreakfast || draftLunch || draftDinner;
    }
    return draftBreakfast != committedBooking!.breakfastBooked ||
        draftLunch != committedBooking!.lunchBooked ||
        draftDinner != committedBooking!.dinnerBooked;
  }

  double calculateEstimatedCost(MealPricesModel prices) {
    double total = 0;
    if (draftBreakfast) total += prices.breakfast;
    if (draftLunch) total += prices.lunch;
    if (draftDinner) total += prices.dinner;
    return total;
  }
}

class StudentBookingNotifier extends StateNotifier<StudentBookingState> {
  StudentBookingNotifier() : super(StudentBookingState(isLoading: true)) {
    loadTomorrowBooking();
  }

  Future<void> loadTomorrowBooking() async {
    state = StudentBookingState(isLoading: true);
    try {
      final tomorrowStr = getTomorrowString();
      final response = await apiClient.dio.get('${ApiConstants.bookingForDate}/$tomorrowStr');

      if (response.statusCode == 200 && response.data != null) {
        final b = BookingModel.fromJson(response.data);
        state = StudentBookingState(
          isLoading: false,
          committedBooking: b,
          draftBreakfast: b.breakfastBooked,
          draftLunch: b.lunchBooked,
          draftDinner: b.dinnerBooked,
          isLocked: b.isLocked,
        );
      } else {
        state = StudentBookingState(isLoading: false);
      }
    } catch (e) {
      state = StudentBookingState(isLoading: false, errorMessage: 'Could not fetch booking.');
    }
  }

  void toggleBreakfast() {
    if (state.isLocked) return;
    state = StudentBookingState(
      committedBooking: state.committedBooking,
      draftBreakfast: !state.draftBreakfast,
      draftLunch: state.draftLunch,
      draftDinner: state.draftDinner,
      isLocked: state.isLocked,
    );
  }

  void toggleLunch() {
    if (state.isLocked) return;
    state = StudentBookingState(
      committedBooking: state.committedBooking,
      draftBreakfast: state.draftBreakfast,
      draftLunch: !state.draftLunch,
      draftDinner: state.draftDinner,
      isLocked: state.isLocked,
    );
  }

  void toggleDinner() {
    if (state.isLocked) return;
    state = StudentBookingState(
      committedBooking: state.committedBooking,
      draftBreakfast: state.draftBreakfast,
      draftLunch: state.draftLunch,
      draftDinner: !state.draftDinner,
      isLocked: state.isLocked,
    );
  }

  Future<bool> saveBooking() async {
    if (state.isLocked) return false;
    state = StudentBookingState(
      isSaving: true,
      committedBooking: state.committedBooking,
      draftBreakfast: state.draftBreakfast,
      draftLunch: state.draftLunch,
      draftDinner: state.draftDinner,
      isLocked: state.isLocked,
    );

    try {
      final tomorrowStr = getTomorrowString();
      final response = await apiClient.dio.post(
        ApiConstants.bookings,
        data: {
          'date': tomorrowStr,
          'breakfast_booked': state.draftBreakfast,
          'lunch_booked': state.draftLunch,
          'dinner_booked': state.draftDinner,
        },
      );

      if (response.statusCode == 200) {
        final b = BookingModel.fromJson(response.data);
        state = StudentBookingState(
          isSaving: false,
          committedBooking: b,
          draftBreakfast: b.breakfastBooked,
          draftLunch: b.lunchBooked,
          draftDinner: b.dinnerBooked,
          isLocked: b.isLocked,
          successMessage: 'Meal booking for tomorrow saved successfully!',
        );
        return true;
      }
      return false;
    } catch (e) {
      state = StudentBookingState(
        isSaving: false,
        committedBooking: state.committedBooking,
        draftBreakfast: state.draftBreakfast,
        draftLunch: state.draftLunch,
        draftDinner: state.draftDinner,
        isLocked: state.isLocked,
        errorMessage: 'Failed to save booking. Midnight cutoff may have passed.',
      );
      return false;
    }
  }
}

final studentBookingProvider = StateNotifierProvider<StudentBookingNotifier, StudentBookingState>((ref) {
  return StudentBookingNotifier();
});

// 3. Student Expenses State
class StudentExpensesNotifier extends StateNotifier<AsyncValue<StudentExpenseSummaryModel>> {
  StudentExpensesNotifier() : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final response = await apiClient.dio.get(ApiConstants.studentExpenses);
      final model = StudentExpenseSummaryModel.fromJson(response.data);
      state = AsyncValue.data(model);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final studentExpensesProvider = StateNotifierProvider<StudentExpensesNotifier, AsyncValue<StudentExpenseSummaryModel>>((ref) {
  return StudentExpensesNotifier();
});

// 4. Student Notifications State
class StudentNotificationsNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  StudentNotificationsNotifier() : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final response = await apiClient.dio.get(ApiConstants.notifications);
      final list = (response.data as List<dynamic>)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await apiClient.dio.patch('${ApiConstants.notifications}$id/read');
      loadNotifications();
    } catch (_) {}
  }
}

final studentNotificationsProvider = StateNotifierProvider<StudentNotificationsNotifier, AsyncValue<List<NotificationModel>>>((ref) {
  return StudentNotificationsNotifier();
});
