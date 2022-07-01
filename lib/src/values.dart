import 'computable_reals_base.dart';

class IntCReal extends CReal {
  IntCReal(this.value);
  final BigInt value;

  @override
  BigInt approximate(int p) {
    return CReal.scale(value, -p);
  }
}

class InvCReal extends CReal {
  InvCReal(this.x);
  final CReal x;

  @override
  BigInt approximate(int p) {
    final msd = x.msd(intMinValue);
    final inverseMsd = 1 - msd;
    final digitsNeeded = inverseMsd - p + 3;

    final precisionNeeded = msd - digitsNeeded;
    final logScaleFactor = -p - precisionNeeded;
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

class NegCReal extends CReal {
  NegCReal(this.x);
  final CReal x;

  @override
  CReal negate() {
    return x;
  }

  @override
  BigInt approximate(int p) {
    return -x.getApproximation(p);
  }
}
