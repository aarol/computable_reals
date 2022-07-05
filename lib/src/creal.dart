import 'dart:typed_data';

import 'dart:math' as math;

import 'computable_reals_base.dart';
import 'functions.dart';
import 'operators.dart';
import 'slow_creal.dart';
import 'values.dart';

/// Constructive real numbers, also known as recursive, or computable reals.
///
/// Each recursive real number is represented as an object that provides an
/// approximation function for the real number.
///
/// The approximation function guarantees that the generated approximation
/// is accurate to the specified precision.
/// Arithmetic operations on constructive reals produce new such objects;
/// they typically do not perform any real computation.
/// In this sense, arithmetic computations are exact: They produce
/// a description which describes the exact answer, and can be used to
/// later approximate it to arbitrary precision.
///
/// Calling toStringPrecision(20) will compute the CReal recursively for up to
/// 20 digits of accuracy.
abstract class CReal {
  /// Create a CReal from `num` i.
  /// Constructing from a double is faster than using `.parse()`,
  /// but will not be as accurate.
  factory CReal.from(num i) = CRealImpl.from;

  factory CReal.fromBigInt(BigInt i) = CRealImpl.fromBigInt;

  /// Parse a number
  factory CReal.parse(String s) = CRealImpl.parse;
  CReal? tryParse(String s);

  CReal operator +(CReal x);
  CReal operator -(CReal x);
  CReal operator *(CReal x);
  CReal operator /(CReal x);

  /// Unary minus (negate)
  CReal operator -();

  CReal operator <<(int n);
  CReal operator >>(int n);

  CReal abs();

  CReal sqrt();
  CReal ln();

  CReal sin();
  CReal cos();
  CReal tan();

  /// Returns a string accurate to `precision` places right of the decimal point.
  /// by default, trailing zeroes after the decimal point are removed, eg.
  ///
  ///     print(CReal.parse('1.5').toStringAsPrecision(10)); // '1.5'
  ///     print(CReal.parse('1.5').toStringAsPrecision(10, 10, true)); // '1.5000000000'
  String toStringAsPrecision(int precision,
      [int radix = 10, bool trailingZeroes = false]);

  /// Approximates the value to 10 digits of precision by calling `toStringAsPrecision,
  /// with trailing zeroes after decimal point removed.
  @override
  String toString() {
    return toStringAsPrecision(10);
  }

  static CReal pi = CRealImpl._pi;
}

abstract class CRealImpl implements CReal {
  CRealImpl();

  int? minimumPrecision;
  BigInt? maxApproximation;
  bool isApproximationValid = false;

  factory CRealImpl.from(num input) {
    if (input is double) {
      if (input.isNaN || input.isInfinite) {
        throw ArgumentError.value(input, 'input');
      }
      // We need to access the floating point representation
      var bd = ByteData(8);
      bd.setFloat64(0, input.abs());
      var bits = bd.getInt64(0);
      var mantissa = (bits & 0xfffffffffffff);
      var biasedExp = bits >> 52;
      var exp = biasedExp - 1075;
      if (biasedExp != 0) {
        mantissa += (1 << 52);
      } else {
        mantissa <<= 1;
      }
      var result = IntCReal(BigInt.from(mantissa)).shiftLeft(exp);
      return input.isNegative ? result.negate() : result;
    } else {
      return IntCReal(BigInt.from(input));
    }
  }

  factory CRealImpl.fromBigInt(BigInt i) {
    return IntCReal(i);
  }
  factory CRealImpl.parse(String s) {
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
    return CRealImpl.fromBigInt(scaledResult) / (CRealImpl.fromBigInt(divisor));
  }

  @override
  CRealImpl? tryParse(String s) {
    try {
      return CRealImpl.parse(s);
    } catch (e) {
      return null;
    }
  }

  @override
  CRealImpl operator +(covariant CRealImpl x) => AddCReal(this, x);

  @override
  CRealImpl operator -(covariant CRealImpl x) => AddCReal(this, x.negate());

  @override
  CRealImpl operator *(covariant CRealImpl x) => MultCReal(this, x);

  @override
  CRealImpl operator /(covariant CRealImpl x) => MultCReal(this, x.inverse());

  CRealImpl inverse() => InverseCReal(this);

  CRealImpl negate() => NegativeCReal(this);

  @override
  CRealImpl operator -() => negate();

  @override
  CRealImpl sqrt() => SqrtCReal(this);

  CRealImpl shiftLeft(int n) {
    CRealImpl.checkPrecision(n);
    return ShiftedCReal(this, n);
  }

  @override
  CRealImpl operator <<(int n) => shiftLeft(n);

  CRealImpl shiftRight(int n) {
    CRealImpl.checkPrecision(n);
    return ShiftedCReal(this, -n);
  }

  @override
  CRealImpl operator >>(int n) => shiftRight(n);

  @override
  CRealImpl cos() {
    final halfPiMultiplies = (this / CRealImpl._pi).getApproximation(-1);
    final halfPiMultipliesAbs = halfPiMultiplies.abs();
    if (halfPiMultipliesAbs >= BigInt.two) {
      final piMultiplies = scale(halfPiMultiplies, -1);
      final adjustment = CRealImpl._pi * (CRealImpl.fromBigInt(piMultiplies));
      if ((piMultiplies & BigInt.one) != BigInt.zero) {
        return (this - adjustment).cos().negate();
      } else {
        return (this - adjustment).cos();
      }
    } else if (getApproximation(-1).abs() >= BigInt.two) {
      final cosHalf = shiftRight(1).cos();
      return (cosHalf * cosHalf).shiftLeft(1) - CRealImpl.from(1);
    } else {
      return PrescaledCosCReal(this);
    }
  }

  @override
  CRealImpl sin() {
    return (CRealImpl._halfPi - this).cos();
  }

  @override
  CReal tan() => sin() / cos();

  int signum(int? a) {
    if (a == null) {
      for (var i = -20;; i *= 2) {
        CRealImpl.checkPrecision(i);
        final result = signum(i);
        if (result != 0) {
          return result;
        }
      }
    } else {
      if (isApproximationValid) {
        if (maxApproximation != BigInt.zero) {
          return maxApproximation! > BigInt.zero ? 1 : -1;
        }
      }
      final thisAprr = getApproximation(a - 1);
      return thisAprr.sign;
    }
  }

  CRealImpl select(CRealImpl x, CRealImpl y) => SelectCReal(this, x, y);

  @override
  CReal abs() => select(-this, this);

  CRealImpl simpleLn() => PrescaledLnCReal(this - CRealImpl.from(1));

  static final _lowLnLimit = BigInt.from(8);
  static final _highLnLimit = BigInt.from(16 + 8);
  static final _scaled4 = BigInt.from(4 * 16);

  /// Natural log of 2.
  ///
  /// `ln(2) = 7*ln(10/9) - 2*ln(25/24) + 3*ln(81/80)`.
  ///
  /// @type {CReal}
  ///
  CRealImpl get _ln2 {
    var a =
        CRealImpl.from(7) * (CRealImpl.from(10) / CRealImpl.from(9)).simpleLn();
    var b = CRealImpl.from(2) *
        (CRealImpl.from(25) / CRealImpl.from(24)).simpleLn();
    var c = CRealImpl.from(3) *
        (CRealImpl.from(81) / CRealImpl.from(80)).simpleLn();

    return a - b + c;
  }

  @override
  CRealImpl ln() {
    final lowPrec = -4;
    final roughAppr = getApproximation(lowPrec);
    if (roughAppr.isNegative) {
      throw Exception("ln(negative)");
    }
    if (roughAppr <= CRealImpl._lowLnLimit) {
      return inverse().ln().negate();
    }
    if (roughAppr >= CRealImpl._highLnLimit) {
      if (roughAppr <= CRealImpl._scaled4) {
        final quarter = sqrt().sqrt().ln();
        return quarter.shiftLeft(2);
      } else {
        final extraBits = roughAppr.bitLength - 3;
        final scaledResult = shiftRight(extraBits).ln();
        return scaledResult + (CRealImpl.from(extraBits) * _ln2);
      }
    }
    return simpleLn();
  }

  BigInt getApproximation(int p) {
    CRealImpl.checkPrecision(p);
    if (isApproximationValid && p >= minimumPrecision!) {
      return CRealImpl.scale(maxApproximation!, minimumPrecision! - p);
    } else {
      final result = approximate(p);
      minimumPrecision = p;
      maxApproximation = result;
      isApproximationValid = true;
      return result;
    }
  }

  /// Throws an error if p is outside what can be safely represented with an integer.
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
      final adjustedK = CRealImpl.shift(k, n + 1) + BigInt.one;
      return adjustedK >> 1;
    }
  }

  BigInt approximate(int p);

  ///Return the position of the most significant digit (msd).
  /// If `x.msd() == n` then `2**(n-1) < abs(x) < 2**(n+1)`
  /// This initial version assumes that `max_appr` is valid and sufficiently removed from zero that the msd is determined.
  int knownMsd() {
    int length;
    if (maxApproximation! >= BigInt.zero) {
      length = maxApproximation!.bitLength;
    } else {
      // negative numbers are stored differently
      length = maxApproximation!.bitLength;
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

  int iterateMsd(int n) {
    for (var prec = 0; prec > n + 30; prec = (prec * 3) ~/ 2 - 16) {
      final msd = this.msd(prec);
      if (msd != intMinValue) {
        return msd;
      }
      CRealImpl.checkPrecision(prec);
    }
    return msd(n);
  }

  @override
  String toStringAsPrecision(int precision,
      [int radix = 10, bool trailingZeroes = false]) {
    final scaleFactor = BigInt.from(radix).pow(precision);
    final scaledCReal = this * IntCReal(scaleFactor);
    final scaledInt = scaledCReal.getApproximation(0);

    if (scaledInt < BigInt.zero) {
      return '-${negate().toStringAsPrecision(precision, radix, trailingZeroes)}';
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
      var fraction = scaledString.substring(len - precision);
      if (!trailingZeroes) {
        var last = fraction.length;
        for (var i = fraction.length - 1; i >= 0; i--) {
          if (fraction[i] != "0") break;
          last = i;
        }

        fraction = fraction.substring(0, last);
      }
      if (fraction == "") {
        result = whole;
      } else {
        result = whole + '.' + fraction;
      }
    }
    return result;
  }

  @override
  String toString() => toStringAsPrecision(10);

  static int boundLog2(int n) {
    return (math.log(n.abs() + 1) / math.log(2)).ceil();
  }

  static final _halfPi = _pi.shiftRight(1);
  static final _pi = GLPiCReal();
}
