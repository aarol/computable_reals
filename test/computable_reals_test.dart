import 'package:computable_reals/computable_reals.dart';
import 'package:test/test.dart';

void main() {
  group('fromInt', () {
    final m = {
      15: "15",
      -15: "-15",
      0: "0",
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
      '-15': 0,
      '-1.51234': 5,
      '1.5': 1,
      '0.015': 3,
      '0.0015': 4,
      '0.0001512': 7,
      '100000000000': 0,
    };
    for (var e in m.entries) {
      test(e.key, () {
        var cr = CReal.fromString(e.key);
        expect(cr.toStringPrecision(e.value), e.key);
      });
    }
  });

  group('operators', () {
    const sqrts = {9: "3", 1: "1", 25: "5"};
    for (var e in sqrts.entries) {
      test('int sqrt(${e.key})', () {
        var cr = CReal.fromInt(e.key);
        expect(cr.sqrt().toStringPrecision(0), e.value);
      });
    }
    test('sqrt throws when negative', () {
      var cr = CReal.fromInt(-9).sqrt();
      expect(() => cr.toStringPrecision(0), throwsException);
    });
    const m = {
      2: "1.41421",
      3: "1.73205",
      100000 * 1000000: "316227.76602",
    };
    for (var e in m.entries) {
      test('double sqrt(${e.key})', () {
        var cr = CReal.fromInt(e.key).sqrt();
        expect(cr.toStringPrecision(5), e.value);
      });
    }
  });
}
