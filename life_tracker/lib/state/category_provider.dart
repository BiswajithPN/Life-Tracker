import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import 'shared_prefs_provider.dart';
import 'user_provider.dart';

final categoryProvider = NotifierProvider<CategoryNotifier, List<CategoryModel>>(() {
  return CategoryNotifier();
});

class CategoryNotifier extends Notifier<List<CategoryModel>> {
  String get _key {
    final user = ref.read(userProvider);
    return 'categories_data_${user?.username ?? 'guest'}';
  }

  @override
  List<CategoryModel> build() {
    ref.watch(userProvider); // Watch to trigger rebuild on user change

    final prefs = ref.watch(sharedPrefsProvider);
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final List<CategoryModel> validList = [];
        for (var e in decoded) {
          try {
            validList.add(CategoryModel.fromJson(e));
          } catch (_) {}
        }
        if (validList.isNotEmpty) {
          return validList;
        }
      } catch (e) {
        // Fallback to default
      }
    }
    
    // Default categories the user starts with
    return [
      CategoryModel(id: '1', name: 'Food', type: 'expense'),
      CategoryModel(id: '2', name: 'Transport', type: 'expense'),
      CategoryModel(id: '3', name: 'Shopping', type: 'expense'),
      CategoryModel(id: '4', name: 'Bills', type: 'expense'),
      CategoryModel(id: '5', name: 'Entertainment', type: 'expense'),
      CategoryModel(id: '9', name: 'Others', type: 'expense'),
      CategoryModel(id: '6', name: 'Salary', type: 'income'),
      CategoryModel(id: '7', name: 'Freelance', type: 'income'),
      CategoryModel(id: '8', name: 'Investment', type: 'income'),
      CategoryModel(id: '10', name: 'Others', type: 'income'),
    ];
  }

  void _save(List<CategoryModel> newState) {
    state = newState;
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setString(_key, jsonEncode(newState.map((e) => e.toJson()).toList()));
  }

  void addCategory(String name, String type) {
    if (name.trim().isEmpty) return;
    final newCat = CategoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      type: type,
    );
    _save([...state, newCat]);
  }

  void removeCategory(String id) {
    _save(state.where((c) => c.id != id).toList());
  }

  List<CategoryModel> getByType(String type) {
    return state.where((c) => c.type == type).toList();
  }
}
