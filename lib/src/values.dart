import 'creal.dart';

class IntCReal extends CRealImpl {
  IntCReal(this.value);
  final BigInt value;

  @override
  BigInt approximate(int p) {
    return CRealImpl.scale(value, -p);
  }
}

class InvCReal extends CRealImpl {
  InvCReal(this.x);
  final CRealImpl x;

  @override
  BigInt approximate(int p) {
    final msd = x.msd(null);
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

class NegCReal extends CRealImpl {
  NegCReal(this.x);
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
