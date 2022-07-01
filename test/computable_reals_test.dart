import 'package:computable_reals/computable_reals.dart';
import 'package:test/test.dart';

void main() {
  CReal cr(int v) => CReal.fromInt(v);
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
      // Exact input/output : Precision
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
        var cr = CReal.parse(e.key);
        expect(cr.toStringPrecision(e.value), e.key);
      });
    }
  });

  group('floating point errors', () {
    final m = {
      CReal.parse('0.1') + CReal.parse('0.2'): '0.30000000000000000000'
    };
    for (var e in m.entries) {
      test(e.key.toStringPrecision(5), () {
        expect(e.key.toStringPrecision(20, 10, true), e.value);
      });
    }
  });

  group('operators', () {
    group('sqrt', () {
      test('throws when negative', () {
        var cr = CReal.fromInt(-9).sqrt();
        expect(() => cr.toStringPrecision(0), throwsException);
      });
      const ints = {
        9: "3",
        1: "1",
        25: "5",
      };
      for (var e in ints.entries) {
        test('int ${e.key}', () {
          var cr = CReal.fromInt(e.key);
          expect(cr.sqrt().toStringPrecision(0), e.value);
        });
      }
      const doubles = {
        2: "1.41421",
        3: "1.73205",
        100000 * 1000000: "316227.76602",
      };
      for (var e in doubles.entries) {
        test('double ${e.key}', () {
          var cr = CReal.fromInt(e.key).sqrt();
          expect(cr.toStringPrecision(5), e.value);
        });
      }
    });
  });

  group('SlowCReal', () {
    group('pi', () {
      test('15 digits', () {
        var cr = CReal.pi;
        var expected = "3.141592653589793";
        expect(cr.toStringPrecision(15), expected);
      });
      test('300 digits', () {
        var cr = CReal.pi;
        var expected =
            "3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067982148086513282306647093844609550582231725359408128481117450284102701938521105559644622948954930381964428810975665933446128475648233786783165271201909145648566923460348610454326648213393607260249141274";
        expect(cr.toStringPrecision(300), expected);
      });
      test('1/(Pi*1000)', () {
        var cr = CReal.fromInt(1) / (CReal.pi * CReal.fromInt(1000));
        var expected =
            "0.0003183098861837906715377675267450287240689192914809128974953347";
        expect(cr.toStringPrecision(64), expected);
      });
    });
    group('cos', () {
      // integer precision
      final m = {
        CReal.fromInt(0): '1',
        CReal.pi: '-1',
        CReal.fromInt(2) * CReal.pi: '1',
      };
      for (var e in m.entries) {
        test(e.key.toStringPrecision(5), () {
          expect(e.key.cos().toStringPrecision(0), e.value);
        });
      }

      // arbitrary precision
      final a = {
        CReal.fromInt(1): '0.54030230586813971740',
        CReal.fromInt(5): '0.28366218546322626447',
      };
      for (var e in a.entries) {
        test(e.key.toStringPrecision(5), () {
          expect(e.key.cos().toStringPrecision(20, 10, true), e.value);
        });
      }
    });
    group('sin', () {
      // integer precision
      final m = {
        cr(0): '0',
        CReal.pi: '0',
        // sin(2pi+1/2pi)
        cr(2) * CReal.pi + cr(1) / cr(2) * CReal.pi: '1',
      };
      for (var e in m.entries) {
        test(e.key.toStringPrecision(5), () {
          expect(e.key.sin().toStringPrecision(0), e.value);
        });
      }

      // arbitrary precision
      final a = {
        cr(531): '-0.07078230485740781010',
        CReal.parse('0.4321'): '0.41877870990075814929'
      };
      for (var e in a.entries) {
        test(e.key.toStringPrecision(5), () {
          expect(e.key.sin().toStringPrecision(20, 10, true), e.value);
        });
      }
    });
  });
}
