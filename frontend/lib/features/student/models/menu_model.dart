class DishModel {
  final int id;
  final String name;
  final String? category;
  final bool isVegetarian;

  DishModel({
    required this.id,
    required this.name,
    this.category,
    this.isVegetarian = true,
  });

  factory DishModel.fromJson(Map<String, dynamic> json) {
    return DishModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      category: json['category'] as String?,
      isVegetarian: json['is_vegetarian'] as bool? ?? true,
    );
  }
}

class MenuModel {
  final int id;
  final String date;
  final String mealType; // 'BREAKFAST', 'LUNCH', 'DINNER'
  final String title;
  final String? description;
  final String? imageUrl;
  final String? dietaryTags;
  final bool isPublished;
  final List<DishModel> dishes;

  MenuModel({
    required this.id,
    required this.date,
    required this.mealType,
    required this.title,
    this.description,
    this.imageUrl,
    this.dietaryTags,
    this.isPublished = false,
    this.dishes = const [],
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: json['id'] as int? ?? 0,
      date: json['date'] as String? ?? '',
      mealType: json['meal_type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      dietaryTags: json['dietary_tags'] as String?,
      isPublished: json['is_published'] as bool? ?? false,
      dishes: (json['dishes'] as List<dynamic>?)
              ?.map((d) => DishModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DailyMealsModel {
  final String date;
  final MenuModel? breakfast;
  final MenuModel? lunch;
  final MenuModel? dinner;

  DailyMealsModel({
    required this.date,
    this.breakfast,
    this.lunch,
    this.dinner,
  });

  factory DailyMealsModel.fromJson(Map<String, dynamic> json) {
    return DailyMealsModel(
      date: json['date'] as String? ?? '',
      breakfast: json['breakfast'] != null
          ? MenuModel.fromJson(json['breakfast'] as Map<String, dynamic>)
          : null,
      lunch: json['lunch'] != null
          ? MenuModel.fromJson(json['lunch'] as Map<String, dynamic>)
          : null,
      dinner: json['dinner'] != null
          ? MenuModel.fromJson(json['dinner'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MealPricesModel {
  final double breakfast;
  final double lunch;
  final double dinner;

  MealPricesModel({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  factory MealPricesModel.fromJson(Map<String, dynamic> json) {
    return MealPricesModel(
      breakfast: (json['breakfast'] as num?)?.toDouble() ?? 40.0,
      lunch: (json['lunch'] as num?)?.toDouble() ?? 80.0,
      dinner: (json['dinner'] as num?)?.toDouble() ?? 70.0,
    );
  }
}
