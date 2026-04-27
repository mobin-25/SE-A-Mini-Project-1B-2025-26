import 'package:flutter_riverpod/flutter_riverpod.dart';

class TransactionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void _start() {
    state = state + 1;
  }

  void _finish() {
    if (state > 0) {
      state = state - 1;
    }
  }

  Future<T> guard<T>(Future<T> Function() action) async {
    _start();
    try {
      return await action();
    } finally {
      _finish();
    }
  }
}

final transactionCounterProvider =
    NotifierProvider<TransactionNotifier, int>(TransactionNotifier.new);

final isTransactionInProgressProvider = Provider<bool>((ref) {
  return ref.watch(transactionCounterProvider) > 0;
});
