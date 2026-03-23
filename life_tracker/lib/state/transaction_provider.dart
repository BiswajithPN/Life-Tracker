import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import 'shared_prefs_provider.dart';
import 'user_provider.dart';

final transactionProvider = NotifierProvider<TransactionNotifier, List<TransactionModel>>(() {
  return TransactionNotifier();
});

class TransactionNotifier extends Notifier<List<TransactionModel>> {
  String get _key {
    final user = ref.read(userProvider);
    return 'transactions_data_${user?.username ?? 'guest'}';
  }

  @override
  List<TransactionModel> build() {
    ref.watch(userProvider); // Watch to trigger rebuild on user change

    final prefs = ref.watch(sharedPrefsProvider);
    final jsonStr = prefs.getString(_key);
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final List<TransactionModel> validList = [];
        for (var e in decoded) {
          try {
            validList.add(TransactionModel.fromJson(e));
          } catch (_) {
            // Skip invalid offline models
          }
        }
        return validList;
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  void _save(List<TransactionModel> newState) {
    state = newState;
    final prefs = ref.read(sharedPrefsProvider);
    prefs.setString(_key, jsonEncode(newState.map((e) => e.toJson()).toList()));
  }

  void addTransaction(TransactionModel transaction) {
    _save([transaction, ...state]);
  }

  void updateTransaction(TransactionModel updated) {
    _save(state.map((t) => t.id == updated.id ? updated : t).toList());
  }

  void deleteTransaction(String id) {
    _save(state.where((t) => t.id != id).toList());
  }

  double get totalBalance {
    return state.fold(0.0, (sum, item) =>
        item.type == 'income' ? sum + item.amount : sum - item.amount);
  }

  double get totalIncome {
    return state
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double get totalExpense {
    return state
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, item) => sum + item.amount);
  }
}
