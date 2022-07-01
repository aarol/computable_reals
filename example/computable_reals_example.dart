import 'package:computable_reals/computable_reals.dart';

void main() {
  (CReal.fromInt(1) / CReal.fromInt(100)).toStringPrecision(15);
  // Create a computable real from an integer
  CReal one = CReal.fromInt(1);
  CReal three = CReal.parse('3'); // Works with doubles too!
  var result = one / three;
  print(result.toStringPrecision(5)); // 0.33333
  // Request more digits
  print(result.toStringPrecision(17)); // 0.33333333333333333

  // Regular floating point numbers eventually lose precision:
  print((1 / 3).toStringAsPrecision(17)); // 0.33333333333333331
}
