import 'package:computable_reals/computable_reals.dart';
import 'package:test/test.dart';

void main() {
  group('fromInt', () {
    const m = {
      15: "15",
      -15: "-15",
    };
    for (var s in m.entries) {
      test(s.key, () {
        var cr = CReal.fromInt(s.key);
        expect(cr.toStringPrecision(0), s.value);
      });
    }
  });
  group('fromString', () {
    const m = {
      '15': 0,
      '1.5': 1,
      '0.015': 3,
      '0.0015': 4,
      '0.0001512': 7,
    };
    for (var s in m.entries) {
      test(s.key, () {
        var cr = CReal.fromString(s.key);
        expect(cr.toStringPrecision(s.value), s.key);
      });
    }
  });
}
