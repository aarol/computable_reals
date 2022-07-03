import 'dart:io';

import 'package:computable_reals/computable_reals.dart';

void main() {
  var b = BigInt.from(-215);
  print(b.bitLength);
  print((-b).bitLength);

  // var c = a / b * CReal.pi;
  var c = CReal.from(-10);
  print(c.tan().toStringPrecision(1));
  exit(0);
  // Create a computable real from an integer
  CReal one = CReal.from(1);
  CReal three = CReal.parse('3'); // Works with doubles too!
  var result = one / three;
  print(result.toStringPrecision(5)); // 0.33333
  // Request more digits
  print(result.toStringPrecision(17)); // 0.33333333333333333

  // Regular floating point numbers eventually lose precision:
  print((1 / 3).toStringAsPrecision(17)); // 0.33333333333333331
}
