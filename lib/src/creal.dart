import 'package:computable_reals/src/slow_creal.dart';
import 'dart:math' as math;

import 'computable_reals_base.dart';
import 'functions.dart';
import 'operators.dart';
import 'values.dart';
import 'package:meta/meta.dart';

abstract class CReal {
  CReal();

  @internal
  int? minimumPrecision;
  @protected
  BigInt? maxApproximation;
  @protected
  bool isApproximationValid = false;

  factory CReal.fromInt(int i) {
    return IntCReal(BigInt.from(i));
  }

  @protected
  factory CReal.fromBigInt(BigInt i) {
    return IntCReal(i);
  }
  factory CReal.parse(String s) {
    s = s.trim();
    final len = s.length;
    var fraction = '0';
    var pointPosition = s.indexOf('.');
    if (pointPosition == -1) {
      pointPosition = len;
    } else {
      fraction = s.substring(pointPosition + 1);
    }
    final whole = s.substring(0, pointPosition);
    final scaledResult = BigInt.parse(whole + fraction);
    final divisor = BigInt.from(10).pow(fraction.length);
    return CReal.fromBigInt(scaledResult).divide(CReal.fromBigInt(divisor));
  }

  CReal? tryParse(String s) {
    try {
      return CReal.parse(s);
    } catch (e) {
      return null;
    }
  }

  CReal add(CReal x) {
    return AddCReal(this, x);
  }

  CReal operator +(CReal x) => add(x);

  CReal subtract(CReal x) {
    return AddCReal(this, x.negate());
  }

  CReal operator -(CReal x) => subtract(x);

  CReal multiply(CReal x) {
    return MultCReal(this, x);
  }

  CReal operator *(CReal x) => multiply(x);

  CReal divide(CReal other) {
    return MultCReal(this, other.inverse());
  }

  CReal operator /(CReal x) => divide(x);

  CReal inverse() {
    return InvCReal(this);
  }

  @protected
  CReal negate() {
    return NegCReal(this);
  }

  CReal operator -() => negate();

  CReal sqrt() {
    return SqrtCReal(this);
  }

  CReal shiftLeft(int n) {
    CReal.checkPrecision(n);
    return ShiftedCReal(this, n);
  }

  CReal operator <<(int n) => shiftLeft(n);

  CReal shiftRight(int n) {
    CReal.checkPrecision(n);
    return ShiftedCReal(this, -n);
  }

  CReal operator >>(int n) => shiftRight(n);

  CReal cos() {
    final halfPi = (this / CReal.PI).getApproximation(-1);
    if (halfPi.abs() >= BigInt.two) {
      final piMultiplies = CReal.scale(halfPi, -1);
      final adjustment = CReal.PI * CReal.fromBigInt(piMultiplies);
      if ((piMultiplies & BigInt.one) != BigInt.zero) {
        return (this - adjustment).cos().negate();
      } else {
        return (this - adjustment).cos();
      }
    } else if (getApproximation(-1).abs() >= BigInt.two) {
      final cosHalf = shiftRight(1).cos();
      return (cosHalf * cosHalf).shiftLeft(1) - CReal.fromInt(1);
    } else {
      return PrescaledCosCReal(this);
    }
  }

  CReal sin() {
    return (CReal._halfPi - this).cos();
  }

  BigInt getApproximation(int p) {
    CReal.checkPrecision(p);
    if (isApproximationValid && p >= minimumPrecision!) {
      return CReal.scale(maxApproximation!, minimumPrecision! - p);
    } else {
      final result = approximate(p);
      minimumPrecision = p;
      maxApproximation = result;
      isApproximationValid = true;
      return result;
    }
  }

  /// Throws an error if p is outside what can be safely represented with an integer.

  @protected
  static void checkPrecision(int p) {
    final high = p >> 28;
    final highShifted = p >> 29;
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

  BigInt approximate(int p);

  int knownMsd() {
    int? length;
    if (maxApproximation! >= BigInt.zero) {
      length = maxApproximation!.bitLength;
    } else {
      // negative numbers are stored differently
      length = maxApproximation!.bitLength + 1;
    }
    return minimumPrecision! + length - 1;
  }

  /// Returns the position of the most significant digit
  int msd(int? precision) {
    if (precision == null) {
      return iterateMsd(intMinValue);
    }
    // Approximation is between [-1, 1]
    if (!isApproximationValid ||
        maxApproximation! <= BigInt.one && maxApproximation! >= -BigInt.one) {
      getApproximation(precision - 1);
      if (maxApproximation!.abs() <= BigInt.one) {
        return intMinValue;
      }
    }
    return knownMsd();
  }

  int iterateMsd(int p) {
    for (var n = 0; n > p + 30; n = (n * 3) ~/ 2 - 16) {
      final msd = this.msd(n);
      if (msd != intMinValue) {
        return msd;
      }
      CReal.checkPrecision(n);
    }
    return msd(p);
  }

  String toStringPrecision(int precision, [int radix = 10]) {
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

  static int boundLog2(int n) {
    return (math.log(n.abs() + 1) / math.log(2)).ceil();
  }

  static final _halfPi = PI.shiftRight(1);
  static final PI = GLPiCReal();
}
