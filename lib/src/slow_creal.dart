import 'dart:math' as math;

import 'creal.dart';
import 'functions.dart';

abstract class SlowCReal extends CRealImpl {
  static const maxPrecision = -64;
  static const precisionIncr = 32;

  static final one = CRealImpl.fromInt(1);

  @override
  BigInt getApproximation(int p) {
    CRealImpl.checkPrecision(p);
    if (maxApproximation != null &&
        isApproximationValid &&
        (minimumPrecision != null && p >= minimumPrecision!)) {
      return CRealImpl.scale(maxApproximation!, minimumPrecision! - p);
    } else {
      final evalPrecision = p >= maxPrecision
          ? maxPrecision
          : (p - precisionIncr + 1) & ~(precisionIncr - 1);
      final result = approximate(evalPrecision);
      minimumPrecision = evalPrecision;
      maxApproximation = result;
      isApproximationValid = true;
      return CRealImpl.scale(result, evalPrecision - p);
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
      return CRealImpl.scale(BigInt.from(3), -p);
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
      final bProdAsCReal =
          CRealImpl.fromBigInt(bProd).shiftRight(-evalPrecision);
      if (bPrec.length == n + 1) {
        final nextBasCReal = bProdAsCReal.sqrt();
        nextB = nextBasCReal.getApproximation(evalPrecision);
        final scaledNextB = CRealImpl.scale(nextB, -extraEvalPrecision);
        bPrec.add(p);
        bVal.add(scaledNextB);
      } else {
        final nextBasCReal = SqrtCReal(bProdAsCReal, bPrec[n + 1], bVal[n + 1]);
        nextB = nextBasCReal.getApproximation(evalPrecision);
        bPrec[n + 1] = p;
        bVal[n + 1] = CRealImpl.scale(nextB, -extraEvalPrecision);
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
    return CRealImpl.scale(result, -extraEvalPrecision);
  }
}

class PrescaledCosCReal extends SlowCReal {
  PrescaledCosCReal(this.x);
  final CRealImpl x;

  @override
  BigInt approximate(int p) {
    if (p >= 1) {
      return BigInt.zero;
    }
    final iterationsNeeded = (-p / 2 + 4).floor();
    final calcPrecision = p - CRealImpl.boundLog2(2 * iterationsNeeded) - 4;
    final xPrecision = p - 2;
    final xApproximation = x.getApproximation(xPrecision);
    final maxTruncError = BigInt.one << (p - 4 - calcPrecision);
    var n = BigInt.zero;
    var currentTerm = BigInt.one << -calcPrecision;
    var currentSum = currentTerm;
    while (currentTerm.abs() >= maxTruncError) {
      n += BigInt.two;
      currentTerm = CRealImpl.scale(currentTerm * xApproximation, xPrecision);
      currentTerm = CRealImpl.scale(currentTerm * xApproximation, xPrecision);
      final divisor = -n * (n - BigInt.one);
      currentTerm ~/= divisor;
      currentSum += currentTerm;
    }
    return CRealImpl.scale(currentSum, calcPrecision - p);
  }
}
