class CReal {
  CReal();
  factory CReal.fromInt(int i) {
    return IntCReal(BigInt.from(i));
  }

  factory CReal._fromBigInt(BigInt i) {
    return IntCReal(i);
  }

  factory CReal.fromString(String s) {
    s = s.trim();
    final len = s.length;
    var fraction = '0';
    var dotPosition = s.indexOf('.');
    if (dotPosition == -1) {
      dotPosition = len;
    } else {
      fraction = s.substring(dotPosition + 1);
    }
    final whole = s.substring(0, dotPosition);
    final scaledResult = BigInt.from(int.parse(whole) + int.parse(fraction));
    final divisor = BigInt.from(10).pow(fraction.length);
    return CReal._fromBigInt(scaledResult).divide(CReal._fromBigInt(divisor));
  }

  CReal divide(CReal other) {
    return MultCReal(this, other.inverse());
  }

  CReal inverse() {
    return InvCReal(this);
  }

  String toStringPrecision(int precision, int? radix) {
    radix ??= 10;
    final scale_factor = BigInt.from(radix).pow(precision);
  }
}

class IntCReal extends CReal {
  IntCReal(this.value);
  final BigInt value;
}

class InvCReal extends CReal {
  InvCReal(this.x);
  final CReal x;
}

class MultCReal extends CReal {
  MultCReal(this.x, this.y);
  final CReal x;
  final CReal y;
}
