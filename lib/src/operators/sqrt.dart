import 'dart:math';

import '../computable_reals_base.dart';

class SqrtCReal extends CReal {
  SqrtCReal(this.x);
  final CReal x;

  static const fpPrecision = 50;
  static const fpOperatorPrecision = 60;

  @override
  BigInt approximate(int precision) {
    final maxOperatorPrecisionNeeded = 2 * precision - 1;
    final msd = x.iterateMsd(maxOperatorPrecisionNeeded);
    if (msd <= maxOperatorPrecisionNeeded) {
      return BigInt.zero;
    }
    final resultMsd = (msd / 2.0).floor();
    final resultDigits = resultMsd - precision;
    if (resultDigits > fpPrecision) {
      final apprDigits = (resultDigits / 2.0).floor() + 6;
      final apprPrecision = resultMsd - apprDigits;
      final productPrecision = 2 * apprPrecision;

      final operatorAppr = x.getApproximation(productPrecision);
      final lastAppr = getApproximation(apprPrecision);

      final productPrecisionScaledNumerator =
          lastAppr * lastAppr + operatorAppr;
      final scaledNumerator = CReal.scale(
          productPrecisionScaledNumerator, apprPrecision - precision);
      final shiftedResult = BigInt.from(scaledNumerator / lastAppr);
      return (shiftedResult + BigInt.one) >> 1;
    } else {
      final operatorPrecision = (msd - fpOperatorPrecision) & ~1;
      final workingPrecision = operatorPrecision - fpOperatorPrecision;
      final scaledAppr =
          (x.getApproximation(operatorPrecision) << fpOperatorPrecision)
              .toDouble();
      if (scaledAppr < 0) {
        throw Exception('sqrt(negative)');
      }
      final scaledFpSqrt = sqrt(scaledAppr);
      final scaledSqrt = BigInt.from(scaledFpSqrt);
      final shiftCount = (workingPrecision / 2).floor() - precision;
      return CReal.shift(scaledSqrt, shiftCount);
    }
  }
}
