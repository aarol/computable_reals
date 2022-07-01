TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

![tests](https://github.com/aarol/computable_reals/actions/workflows/test/badge.svg)

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

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