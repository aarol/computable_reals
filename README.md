Computable reals, or constructive real numbers in Dart. Ported from [creal.js](https://github.com/christianp/creal.js), this package approximates numbers to arbitrary precision.

![tests](https://github.com/aarol/computable_reals/actions/workflows/test.yml/badge.svg)

## Features


## Usage

```dart
import 'package:computable_reals/computable_reals.dart';

...

// Create a computable real from an integer
var one = CReal.fromInt(1);
var three = CReal.parse('3'); // Works with doubles too!
var result = one / three;
print(result.toStringPrecision(5)); // 0.33333
```

## Supported operations

* Addition, substraction, division, multiplication
* Left/right shift
* Square root
* Sin, cos
* PI

## References

* Ported from creal.js: https://github.com/christianp/creal.js
* android/calculator2: https://android-review.googlesource.com/c/platform/art/+/1012109