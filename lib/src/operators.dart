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
  MultCReal(this.x, this.y);
  CRealImpl x;
  CRealImpl y;

  @override
  BigInt approximate(int p) {
    final halfPrecision = (p >> 1) - 1;
    int msdX = x.msd(halfPrecision);
    int? msdY;
    if (msdX == intMinValue) {
      msdY = y.msd(halfPrecision);
      if (msdY == intMinValue) {
        return BigInt.zero;
      } else {
        final tmp = x;
        x = y;
        y = tmp;
        msdX = msdY;
      }
    }

    final precision2 = p - msdX - 3;

    final approximationY = y.getApproximation(precision2);
    if (approximationY == BigInt.zero) {
      return BigInt.zero;
    }

    msdY = y.knownMsd();
    final precision1 = p - msdY - 3;
    final approximationX = x.getApproximation(precision1);
    final scaleDigits = precision1 + precision2 - p;
    return CRealImpl.scale(approximationX * approximationY, scaleDigits);
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
