Computable reals, or constructive real numbers in Dart. Ported from [creal.js](https://github.com/christianp/creal.js), this package approximates numbers to arbitrary precision.

![tests](https://github.com/aarol/computable_reals/actions/workflows/tests.yml/badge.svg)

## Features

## Usage

```dart
import 'package:computable_reals/computable_reals.dart';

...
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
```

## Supported operations

- Addition, substraction, division, multiplication
- Left/right shift
- Square root
- Sin, cos, tan
- ln
- PI, E

!! Timeouts for some operations (tan) are not yet implemented.

## References

- Ported from creal.js: https://github.com/christianp/creal.js
- android/calculator2: https://android-review.googlesource.com/c/platform/art/+/1012109
