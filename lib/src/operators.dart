import 'computable_reals_base.dart';
import 'creal.dart';

class AddCReal extends CRealImpl {
  AddCReal(this.x, this.y);
  final CRealImpl x;
  final CRealImpl y;

  @override
  BigInt approximate(int p) {
    return CRealImpl.scale(
        x.getApproximation(p - 2) + y.getApproximation(p - 2), -2);
  }
}

class MultCReal extends CRealImpl {
  MultCReal(this.op1, this.op2);
  CRealImpl op1;
  CRealImpl op2;

  @override
  BigInt approximate(int p) {
    final halfPrecision = (p >> 1) - 1;
    int msd1 = op1.msd(halfPrecision);
    int? msd2;
    if (msd1 == intMinValue) {
      msd2 = op2.msd(halfPrecision);
      if (msd2 == intMinValue) {
        return BigInt.zero;
      } else {
        final tmp = op1;
        op1 = op2;
        op2 = tmp;
        msd1 = msd2;
      }
    }

    final precision2 = p - msd1 - 3;

    final appr2 = op2.getApproximation(precision2);
    if (appr2 == BigInt.zero) {
      return BigInt.zero;
    }

    msd2 = op2.knownMsd();
    final precision1 = p - msd2 - 3;
    final appr1 = op1.getApproximation(precision1);
    final scaleDigits = precision1 + precision2 - p;
    return CRealImpl.scale(appr1 * appr2, scaleDigits);
  }
}

class ShiftedCReal extends CRealImpl {
  ShiftedCReal(this.x, this.count);
  final CRealImpl x;
  final int count;

  @override
  BigInt approximate(int p) {
    return x.getApproximation(p - count);
  }
}

class NegativeCReal extends CRealImpl {
  NegativeCReal(this.x);
  final CRealImpl x;

  @override
  CRealImpl negate() {
    return x;
  }

  @override
  BigInt approximate(int p) {
    return -x.getApproximation(p);
  }
}

class InverseCReal extends CRealImpl {
  InverseCReal(this.op);
  final CRealImpl op;

  @override
  BigInt approximate(int p) {
    final msd = op.msd(null);
    final invMsd = 1 - msd;
    final digitsNeeded = invMsd - p + 3;
    // Number of SIGNIFICANT digits needed for
    // argument, excl. msd position, which may
    // be fictitious, since msd routine can be
    // off by 1.  Roughly 1 extra digit is
    // needed since the relative error is the
    // same in the argument and result, but
    // this isn't quite the same as the number
    // of significant digits.  Another digit
    // is needed to compensate for slop in the
    // calculation.
    // One further bit is required, since the
    // final rounding introduces a 0.5 ulp
    // error.
    final precNeeded = msd - digitsNeeded;
    final logScaleFactor = -p - precNeeded;
    if (logScaleFactor < 0) return BigInt.zero;

    final dividend = BigInt.one << logScaleFactor;
    final scaledDivisor = op.getApproximation(precNeeded);
    final absScaledDivisor = scaledDivisor.abs();
    final adjustedDividend = dividend + (absScaledDivisor >> 1);
    final result = adjustedDividend ~/ absScaledDivisor;
    if (scaledDivisor < BigInt.zero) {
      return -result;
    } else {
      return result;
    }
  }
}
