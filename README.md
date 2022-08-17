Computable reals, or constructive real numbers in Dart. Approximates real numbers to arbitrary precision. Ported from [creal.js](https://github.com/christianp/creal.js).

![tests](https://github.com/aarol/computable_reals/actions/workflows/tests.yml/badge.svg)

## Usage

```dart
import 'package:computable_reals/computable_reals.dart';

void main() {
  // Create a computable real from a number
  var one = CReal.from(1);
  // Or a string
  var three = CReal.parse('3.0');
  CReal result = one / three;

  // This evalues the result to 5 digits of precision
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
```

### Exceptions

If using user input, some edge cases should be considered.
* Approximation with `toString` and `toStringAsPrecision` may throw `ArithmeticException` (division by zero, etc.)
* Some slower computations like PI implement timeouts and will throw `TimeoutException` after 3 seconds.

### Why this package exists

Regular floating point numbers are not completely accurate when converted to human-readable base-10 numbers. This is why in dart, `print(0.1+0.2) == "0.30000000000000004"`. This is a problem when higher precision is needed.

Computable reals don't have this limitation, they are accurate for as many digits as needed. This is useful when calculations with higher precision are needed. Like the original `crcalc` java library, computable reals are especially useful when building calculator apps. This package tries to offer the same experience that the stock Android Calculator does. [video](https://aperiodical.com/wp-content/uploads/2022/03/MP4_20220302_141007-1.mp4) ([original post](https://aperiodical.com/2022/03/now-im-calculating-with-constructive-reals/))

### Supported operations

- Addition, substraction, division, multiplication
- Left/right shift
- Square root
- Sin, cos, tan, asin, acos, atan
- ln, log, exp, pow
- PI, E

## References

- Ported from creal.js: https://github.com/christianp/creal.js
- android/crcalc: https://android.googlesource.com/platform/external/crcalc/
