import 'creal.dart';

class IntCReal extends CRealImpl {
  IntCReal(this.value);
  final BigInt value;

  @override
  BigInt approximate(int p) {
    return CRealImpl.scale(value, -p);
  }
}
