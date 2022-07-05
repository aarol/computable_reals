import 'package:computable_reals/src/creal.dart';

class ArithmeticException implements Exception {
  final String operation;
  final CReal? value;
  final String reason;

  ArithmeticException(this.value, this.operation, this.reason);

  @override
  String toString() {
    var valueString = '';
    if (value != null) {
      valueString = 'on value' + value!.toStringAsPrecision(5);
    }
    return 'ArithmeticException: operation $operation failed $valueString: $reason';
  }
}
