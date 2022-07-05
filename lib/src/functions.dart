import 'dart:math';

import 'exception.dart';
import 'creal.dart';

class SqrtCReal extends CRealImpl {
  SqrtCReal(this.x, [int? minP, BigInt? maxAppr]) {
    if (minP != null) {
      minimumPrecision = minP;
      maxApproximation = maxAppr;
      isApproximationValid = true;
    }
  }
  final CRealImpl x;

  static const fpPrecision = 50;
  static const fpOperatorPrecision = 60;

  @override
  BigInt approximate(int p) {
    final maxOperatorPrecisionNeeded = 2 * p - 1;
    final msd = x.iterateMsd(maxOperatorPrecisionNeeded);
    if (msd <= maxOperatorPrecisionNeeded) {
      return BigInt.zero;
    }
    final resultMsd = (msd / 2.0).floor();
    final resultDigits = resultMsd - p;
    if (resultDigits > fpPrecision) {
      final apprDigits = (resultDigits / 2.0).floor() + 6;
      final apprPrecision = resultMsd - apprDigits;
      final productPrecision = 2 * apprPrecision;

      final operatorAppr = x.getApproximation(productPrecision);
      final lastAppr = getApproximation(apprPrecision);

      final productPrecisionScaledNumerator =
          lastAppr * lastAppr + operatorAppr;
      final scaledNumerator =
          CRealImpl.scale(productPrecisionScaledNumerator, apprPrecision - p);
      final shiftedResult = scaledNumerator ~/ lastAppr;
      return (shiftedResult + BigInt.one) >> 1;
    } else {
      final operatorPrecision = (msd - fpOperatorPrecision) & ~1;
      final workingPrecision = operatorPrecision - fpOperatorPrecision;
      final scaledAppr =
          (x.getApproximation(operatorPrecision) << fpOperatorPrecision)
              .toDouble();
      if (scaledAppr < 0) {
        throw ArithmeticException(this, 'sqrt', 'negative');
      }
      final scaledFpSqrt = sqrt(scaledAppr);
      final scaledSqrt = BigInt.from(scaledFpSqrt);
      final shiftCount = (workingPrecision / 2).floor() - p;
      return CRealImpl.shift(scaledSqrt, shiftCount);
    }
  }
}

/// Returns x if selector < 0, else y.
///
/// Assumes x = y if selector = 0.
class SelectCReal extends CRealImpl {
  SelectCReal(this.selector, this.x, this.y)
      : selectorSign = selector.getApproximation(-20).sign;
  final CRealImpl selector;
  final CRealImpl x;
  final CRealImpl y;
  int selectorSign;

  @override
  BigInt approximate(int p) {
    if (selectorSign < 0) {
      return x.getApproximation(p);
    } else if (selectorSign > 0) {
      return y.getApproximation(p);
    }
    final xAppr = x.getApproximation(p - 1);
    final yAppr = y.getApproximation(p - 1);
    final diff = (xAppr - yAppr).abs();
    if (diff <= BigInt.one) {
      return CRealImpl.scale(xAppr, -1);
    }
    //op1 and op2 are different; selector != 0.
    // Safe to get sign of selector.
    if (selector.signum(null) < 0) {
      selectorSign = -1;
      return CRealImpl.scale(xAppr, -1);
    } else {
      selectorSign = 0;
      return CRealImpl.scale(yAppr, -1);
    }
  }
}
