import 'package:computable_reals/src/creal.dart';

class ArithmeticException implements Exception {
  final CReal? value;
  final String operation;
  final String reason;

  ArithmeticException(this.value, this.operation, this.reason);

  @override
  String toString() {
    var valueString = '';
    if (value != null) {
      try {
        // approximating value might fail
        // in that case, another error would happen inside this error
        valueString = ' on value ' + value!.toStringAsPrecision(5);
      } catch (e) {
        // do nothing
      }
    }
    return 'ArithmeticException: operation $operation failed$valueString: $reason';
  }
}

class TimeoutException implements Exception {
  @override
  String toString() => 'TimeoutException: operation took too long';
}
