import 'package:computable_reals/computable_reals.dart';

void main() {
  // Create a computable real from an integer
  var one = CReal.from(1);
  var three = CReal.parse('3.0');
  CReal result = one / three;

  print(result.toStringAsPrecision(5));
  // -> 0.33333

  // Doubles eventually lose precision:
  print((1.0 / 3.0).toStringAsPrecision(17));
  // -> 0.33333333333333331

  // CReals have as many digits as you need:
  print(result.toStringAsPrecision(30));
  // -> 0.333333333333333333333333333333

  print(CReal.pi.toStringAsPrecision(64));
  // -> 3.1415926535897932384626433832795028841971693993751058209749445923
}
