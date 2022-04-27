import 'precision_vm.dart' if (dart.library.html) 'precision_js.dart'
    as platform;

const intMinValue = platform.intMinValue;

abstract class CReal {
  CReal();

  int? minimumPrecision;
  BigInt? maxApproximation;
  bool isApproximationValid = false;

  factory CReal.fromInt(int i) {
    return IntCReal(BigInt.from(i));
  }

  factory CReal._fromBigInt(BigInt i) {
    return IntCReal(i);
  }

  factory CReal.fromString(String s) {
    s = s.trim();
    final len = s.length;
    var fraction = '0';
    var dotPosition = s.indexOf('.');
    if (dotPosition == -1) {
      dotPosition = len;
    } else {
      fraction = s.substring(dotPosition + 1);
    }
    final whole = s.substring(0, dotPosition);
    final scaledResult = BigInt.from(int.parse(whole + fraction));
    print(scaledResult.toString());
    final divisor = BigInt.from(10).pow(fraction.length);
    return CReal._fromBigInt(scaledResult).divide(CReal._fromBigInt(divisor));
  }

  CReal multiply(CReal x) {
    return MultCReal(this, x);
  }

  CReal divide(CReal other) {
    return MultCReal(this, other.inverse());
  }

  CReal inverse() {
    return InvCReal(this);
  }

  CReal negate() {
    return NegCReal(this);
  }

  BigInt getApproximation(int precision) {
    CReal._checkPrecision(precision);
    if (maxApproximation != null &&
        isApproximationValid &&
        precision >= (minimumPrecision ?? 0)) {
      return CReal.scale(
          maxApproximation!, (minimumPrecision ?? 0) - precision);
    } else {
      final result = approximate(precision);
      minimumPrecision = precision;
      maxApproximation = result;
      isApproximationValid = true;
      return result;
    }
  }

  /// Throws an error if the requested precision is outside what can be safely represented with an integer.
  static _checkPrecision(int precision) {
    final high = precision >> 28;
    final highShifted = precision >> 29;
    if (0 != (high ^ highShifted)) {
      throw Exception('precision overflow');
    }
  }

  /// Multiply k by 2**n.
  static BigInt shift(BigInt k, int n) {
    if (n == 0) {
      return k;
    } else if (n.isNegative) {
      return k >> -n;
    } else {
      return k << n;
    }
  }

  static BigInt scale(BigInt k, int n) {
    if (n >= 0) {
      return k << n;
    } else {
      final adjustedK = CReal.shift(k, n + 1) + BigInt.one;
      return adjustedK >> 1;
    }
  }

  BigInt approximate(int precision);

  int knownMsd() {
    int? length;
    if (maxApproximation! >= BigInt.zero) {
      length = maxApproximation!.bitLength;
    } else {
      length = -maxApproximation!.bitLength;
    }
    return minimumPrecision! + length - 1;
  }

  /// Returns the position of the most significant digit
  int msd(int precision) {
    if (!isApproximationValid ||
        (maxApproximation != null && maxApproximation! < BigInt.one) &&
            (-BigInt.one + maxApproximation!) >= BigInt.zero) {
      getApproximation(precision - 1);
      if (maxApproximation!.abs() <= BigInt.one) {
        return intMinValue;
      }
    }
    return knownMsd();
  }

  int iterateMsd(int precision) {
    for (var p = 0; p > precision + 30; p = (p * 3) ~/ 2 - 16) {
      final msd = this.msd(p);
      if (msd != intMinValue) {
        return msd;
      }
      CReal._checkPrecision(precision);
    }
    return msd(precision);
  }

  String toStringPrecision(int precision, [int? radix]) {
    radix ??= 10;
    final scaleFactor = BigInt.from(radix).pow(precision);
    final scaledCReal = multiply(IntCReal(scaleFactor));
    final scaledInt = scaledCReal.getApproximation(0);

    if (scaledInt < BigInt.zero) {
      return '-${negate().toStringPrecision(precision, radix)}';
    }
    String scaledString = scaledInt.toRadixString(radix);
    String result = "";
    if (precision == 0) {
      result = scaledString;
    } else {
      int len = scaledString.length;
      if (len <= precision) {
        scaledString = '0' * (precision + 1 - len) + scaledString;
        len = precision + 1;
      }
      final whole = scaledString.substring(0, len - precision);
      final fraction = scaledString.substring(len - precision);
      result = whole + '.' + fraction;
    }
    return result;
  }
}

class IntCReal extends CReal {
  IntCReal(this.value);
  final BigInt value;

  @override
  BigInt approximate(int precision) {
    return CReal.scale(value, -precision);
  }
}

class InvCReal extends CReal {
  InvCReal(this.x);
  final CReal x;

  @override
  BigInt approximate(int precision) {
    final msd = x.iterateMsd(intMinValue);
    final inverseMsd = 1 - msd;
    final digitsNeeded = inverseMsd - precision + 3;

    final precisionNeeded = msd - digitsNeeded;
    final logScaleFactor = -precision - precisionNeeded;
    if (logScaleFactor < 0) {
      return BigInt.zero;
    }
    final dividend = BigInt.one << logScaleFactor;
    final scaledDivisor = x.getApproximation(precisionNeeded).abs();
    final adjustedDividend = dividend + (scaledDivisor >> 1);
    final result = adjustedDividend ~/ scaledDivisor;
    if (scaledDivisor < BigInt.zero) {
      return -result;
    } else {
      return result;
    }
  }
}

class MultCReal extends CReal {
  MultCReal(this.x, this.y);
  CReal x;
  CReal y;

  @override
  BigInt approximate(int precision) {
    final halfPrecision = (precision >> 1) - 1;
    int msdX = x.msd(halfPrecision);
    int? msdY;
    if (msdX == intMinValue) {
      msdY = y.msd(halfPrecision);
      if (msdY == intMinValue) {
        return BigInt.zero;
      } else {
        final tmp = x;
        x = y;
        y = tmp;
        msdX = msdY;
      }
    }

    final precision2 = precision - msdX - 3;

    final approximationY = y.getApproximation(precision2);
    if (approximationY == BigInt.zero) {
      return BigInt.zero;
    }

    msdY = y.knownMsd();
    final precision1 = precision - msdY - 3;
    final approximationX = x.getApproximation(precision1);
    final scaleDigits = precision1 + precision2 - precision;
    return CReal.scale(approximationX * approximationY, scaleDigits);
  }
}

class NegCReal extends CReal {
  NegCReal(this.x);
  final CReal x;

  @override
  CReal negate() {
    return x;
  }

  @override
  BigInt approximate(int precision) {
    return -x.getApproximation(precision);
  }
}
