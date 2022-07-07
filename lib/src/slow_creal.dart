import 'dart:math' as math;

import 'creal.dart';
import 'functions.dart';

abstract class SlowCReal extends CRealImpl {
  static int maxPrecision = -64;
  static int precIncr = 32;

  @override
  BigInt getApproximation(int p) {
    CRealImpl.checkPrecision(p);
    if (isApproximationValid && (p >= minimumPrecision!)) {
      return CRealImpl.scale(maxApproximation!, minimumPrecision! - p);
    } else {
      final evalPrecision = p >= maxPrecision
          ? maxPrecision
          : (p - precIncr + 1) & ~(precIncr - 1);
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
  static final sqrtHalf = SqrtCReal(CRealImpl.one.shiftRight(1));

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
      // Left shift with negative amount <=> Right shift with positive amount
      final nextT = t - (aDiff * aDiff >> -(n + evalPrecision));
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
  PrescaledCosCReal(this.op);
  final CRealImpl op;

  @override
  BigInt approximate(int p) {
    if (p >= 1) {
      return BigInt.zero;
    }
    final iterationsNeeded = (-p / 2 + 4).floor();
    // conservative estimate > 0.
    //  Claim: each intermediate term is accurate
    //  to 2*2^calc_precision.
    //  Total rounding error in series computation is
    //  2*iterations_needed*2^calc_precision,
    //  exclusive of error in op.
    final calcPrecision = p - CRealImpl.boundLog2(2 * iterationsNeeded) - 4;
    final opPrecision = p - 2;
    final opApproximation = op.getApproximation(opPrecision);
    final maxTruncError = BigInt.one << (p - 4 - calcPrecision);
    var n = BigInt.zero;
    var currentTerm = BigInt.one << (-calcPrecision);
    var currentSum = currentTerm;
    while (currentTerm.abs() >= maxTruncError) {
      n += BigInt.two;
      currentTerm = CRealImpl.scale(currentTerm * opApproximation, opPrecision);
      currentTerm = CRealImpl.scale(currentTerm * opApproximation, opPrecision);
      final divisor = -n * (n - BigInt.one);
      currentTerm ~/= divisor;
      currentSum += currentTerm;
    }
    return CRealImpl.scale(currentSum, calcPrecision - p);
  }
}

/// Representation for ln(1+op)
class PrescaledLnCReal extends SlowCReal {
  PrescaledLnCReal(this.x);
  final CRealImpl x;

  // Compute an approximation of ln(1+x) to precision
  // prec. This assumes |x| < 1/2.
  // It uses a Taylor series expansion.
  // Unfortunately there appears to be no way to take
  // advantage of old information.
  // Note: this is known to be a bad algorithm for
  // floating point.  Unfortunately, other alternatives
  // appear to require precomputed tabular information.
  @override
  BigInt approximate(int p) {
    if (p >= 0) {
      BigInt.zero;
    }
    final iterNeeded = -p;
    // Claim: each intermediate term is accurate
    // to 2*2^calc_precision.  Total error is
    // 2*iterations_needed*2^calc_precision
    // exclusive of error in op.
    final calcPrecision = p - CRealImpl.boundLog2(2 * iterNeeded);
    final opPrec = p - 3;
    final opAppr = x.getApproximation(opPrec);
    var xNth = CRealImpl.scale(opAppr, opPrec - calcPrecision);
    var currentTerm = xNth;
    var currentSum = currentTerm;
    var n = BigInt.one;
    var currentSign = BigInt.one;
    final maxTruncError = BigInt.one << (p - 4 - calcPrecision);
    while (currentTerm.abs() >= maxTruncError) {
      n += BigInt.one;
      currentSign = -currentSign;
      xNth = CRealImpl.scale(xNth * opAppr, opPrec);
      currentTerm = xNth ~/ (n * currentSign);
      currentSum += currentTerm;
    }
    return CRealImpl.scale(currentSum, calcPrecision - p);
  }
}

/// Representation of the exponential of a constructive real.  Private.
/// Uses a Taylor series expansion.  Assumes |x| < 1/2.
/// Note: this is known to be a bad algorithm for
/// floating point.  Unfortunately, other alternatives
/// appear to require precomputed information.
class PrescaledExpCReal extends CRealImpl {
  PrescaledExpCReal(this.x);
  final CRealImpl x;

  @override
  BigInt approximate(int p) {
    if (p >= 1) return BigInt.zero;
    final iterNeeded = -p ~/ 2 + 2;
    // Claim: each intermediate term is accurate
    // to 2*2^calc_precision.
    // Total rounding error in series computation is
    // 2*iterations_needed*2^calc_precision,
    // exclusive of error in op.
    final calcPrecision = p - CRealImpl.boundLog2(2 * iterNeeded) - 4;
    final opPrecison = p - 3;
    final opAppr = x.getApproximation(opPrecison);

    final scaled1 = BigInt.one << -calcPrecision;
    var currentTerm = scaled1;
    var currentSum = scaled1;
    var n = 0;
    final maxTruncError = BigInt.one << (p - 4 - calcPrecision);
    while (currentTerm.abs() >= maxTruncError) {
      n += 1;
      currentTerm = CRealImpl.scale(currentTerm * opAppr, opPrecison);
      currentTerm ~/= BigInt.from(n);
      currentSum += currentTerm;
    }
    return CRealImpl.scale(currentSum, calcPrecision - p);
  }
}

/// Representation of the arcsine of a constructive real.  Private.
/// Uses a Taylor series expansion.  Assumes |x| < (1/2)^(1/3).
class PrescaledAsinCReal extends SlowCReal {
  PrescaledAsinCReal(this.x);
  final CRealImpl x;

  @override
  BigInt approximate(int p) {
    // The Taylor series is the sum of x^(2n+1) * (2n)!/(4^n n!^2 (2n+1))
    // Note that (2n)!/(4^n n!^2) is always less than one.
    // (The denominator is effectively 2n*2n*(2n-2)*(2n-2)*...*2*2
    // which is clearly > (2n)!)
    // Thus all terms are bounded by x^(2n+1).
    // Unfortunately, there's no easy way to prescale the argument
    // to less than 1/sqrt(2), and we can only approximate that.
    // Thus the worst case iteration count is fairly high.
    // But it doesn't make much difference.
    if (p >= 2) return BigInt.zero; // Never bigger than 4.
    final iterNeeded = -3 * p ~/ 2 + 4;
    // conservative estimate > 0.
    // Follows from assumed bound on x and
    // the fact that only every other Taylor
    // Series term is present.

    //  Claim: each intermediate term is accurate
    //  to 2*2^calc_precision.
    //  Total rounding error in series computation is
    //  2*iterations_needed*2^calc_precision,
    //  exclusive of error in op.
    final calcPrecision = p - CRealImpl.boundLog2(2 * iterNeeded) - 4;
    final opPrecision = p - 3;
    final opAppr = x.getApproximation(opPrecision);
    // Error in argument results in error of < 1/4 ulp.
    // (Derivative is bounded by 2 in the specified range and we use
    // 3 extra digits.)
    // Ignoring the argument error, each term has an error of
    // < 3ulps relative to calc_precision, which is more precise than p.
    // Cumulative arithmetic rounding error is < 3/16 ulp (relative to p).
    // Series truncation error < 2/16 ulp.  (Each computed term
    // is at most 2/3 of last one, so some of remaining series <
    // 3/2 * current term.)
    // Final rounding error is <= 1/2 ulp.
    // Thus final error is < 1 ulp (relative to p).
    final maxLastTerm = BigInt.one << (p - 4 - calcPrecision);
    var exp = 1;
    var currentTerm = opAppr << (opPrecision - calcPrecision);
    var currentFactor = currentTerm;
    // Current scaled Taylor series term
    // before division by the exponent.
    // Accurate to 3 ulp at calc_precision.
    var currentSum = currentTerm;
    while (currentTerm.abs() >= maxLastTerm) {
      exp += 2;
      currentFactor *= BigInt.from(exp - 2);
      currentFactor = CRealImpl.scale(currentFactor * opAppr, opPrecision + 2);
      currentFactor *= opAppr;
      final divisor = BigInt.from(exp - 1);
      currentFactor ~/= divisor;
      // Remove extra 2 bits.  1/2 ulp rounding error.
      // Current_factor has original 3 ulp rounding error, which we
      // reduced by 1, plus < 1 ulp new rounding error.
      currentFactor = CRealImpl.scale(currentFactor, opPrecision - 2);
      // Contributes 1 ulp error to sum plus at most 3 ulp
      // from current_factor.
      currentTerm = currentFactor ~/ BigInt.from(exp);
      currentSum += currentTerm;
    }
    return CRealImpl.scale(currentSum, calcPrecision - p);
  }
}
