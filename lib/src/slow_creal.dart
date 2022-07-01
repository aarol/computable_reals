import 'dart:math' as math;

import 'computable_reals_base.dart';
import 'functions.dart';

abstract class SlowCReal extends CReal {
  static const maxPrecision = -64;
  static const precisionIncr = 32;

  static final one = CReal.fromInt(1);

  @override
  BigInt getApproximation(int p) {
    CReal.checkPrecision(p);
    if (maxApproximation != null &&
        isApproximationValid &&
        (minimumPrecision != null && p >= minimumPrecision!)) {
      return CReal.scale(maxApproximation!, minimumPrecision! - p);
    } else {
      final evalPrecision = p >= maxPrecision
          ? maxPrecision
          : (p - precisionIncr + 1) & ~(precisionIncr - 1);
      final result = approximate(evalPrecision);
      minimumPrecision = evalPrecision;
      maxApproximation = result;
      isApproximationValid = true;
      return CReal.scale(result, evalPrecision - p);
    }
  }
}

class GLPiCReal extends SlowCReal {
  var bPrec = <int?>[null];
  var bVal = <BigInt?>[null];

  static final tolerance = BigInt.from(4);
  static final sqrtHalf = SqrtCReal(SlowCReal.one.shiftRight(1));

  @override
  BigInt approximate(int p) {
    final bPrec = this.bPrec;
    final bVal = this.bVal;
    if (p >= 0) {
      return CReal.scale(BigInt.from(3), -p);
    }
    final extraEvalPrecision = (math.log(-p) / math.log(2)).ceil() + 10;
    final evalPrecision = p - extraEvalPrecision;
    var a = BigInt.one << -evalPrecision;
    var b = sqrtHalf.getApproximation(evalPrecision);
    var t = BigInt.one << (-evalPrecision - 2);
    var n = 0;
    while (a - b - tolerance > BigInt.zero) {
      final nextA = (a + b) >> 1;
      BigInt nextB;
      final aDiff = a - nextA;
      final bProd = (a * b) >> -evalPrecision;
      final bProdAsCReal = CReal.fromBigInt(bProd).shiftRight(-evalPrecision);
      if (bPrec.length == n + 1) {
        final nextBasCReal = bProdAsCReal.sqrt();
        nextB = nextBasCReal.getApproximation(evalPrecision);
        final scaledNextB = CReal.scale(nextB, -extraEvalPrecision);
        bPrec.add(p);
        bVal.add(scaledNextB);
      } else {
        final nextBasCReal = SqrtCReal(bProdAsCReal, bPrec[n + 1], bVal[n + 1]);
        nextB = nextBasCReal.getApproximation(evalPrecision);
        bPrec[n + 1] = p;
        bVal[n + 1] = CReal.scale(nextB, -extraEvalPrecision);
      }
      final nextT = t - (aDiff * aDiff >> -n - evalPrecision);
      a = nextA;
      b = nextB;
      t = nextT;
      n += 1;
    }
    final sum = a + b;
    final r = (sum * sum) ~/ t;
    final result = r >> 2;
    return CReal.scale(result, -extraEvalPrecision);
  }
}
