import 'package:computable_reals/computable_reals.dart';
import 'package:test/test.dart';

void main() {
  CReal cr(num v) => CReal.from(v);
  group('from', () {
    final m = {
      15: "15",
      -15: "-15",
      0: "0",
      1.5: "1.5",
      0.0: "0",
      1416346.12315715000: "1416346.12315715",
    };
    for (var s in m.entries) {
      test(s.key, () {
        var cr = CReal.from(s.key);
        expect(cr.toStringAsPrecision(8), s.value);
      });
    }
    test('cannot parse NaN or Infinity', () {
      expect(() => CReal.from(double.nan), throwsArgumentError);
      expect(() => CReal.from(double.infinity), throwsArgumentError);
      expect(() => CReal.from(double.negativeInfinity), throwsArgumentError);
    });
  });
  group('parse', () {
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
        expect(cr.toStringAsPrecision(e.value), e.key);
      });
    }
    test('fails when invalid string', () {
      expect(() => CReal.parse('adsfg'), throwsFormatException);
      expect(() => CReal.parse('1234fff'), throwsFormatException);
      expect(() => CReal.parse('2aa13.3100ff'), throwsFormatException);
    });
  });

  group('graph', () {
    final m = {
      cr(76) / cr(3) * cr(9): '228',
      cr(1) / cr(5) - (-cr(8) / cr(10)): '1',
      (cr(1) / cr(100)).sqrt(): '0.1'
    };
    for (var e in m.entries) {
      test(e.key.toString(), () {
        expect(e.key.toStringAsPrecision(2), e.value);
      });
    }
  });

  group('floating point errors', () {
    final m = {
      CReal.parse('0.1') + CReal.parse('0.2'): '0.30000000000000000000',
    };
    for (var e in m.entries) {
      test(e.key.toString(), () {
        expect(e.key.toStringAsPrecision(20, 10, true), e.value);
      });
    }
    test('from double is still inaccurate', () {
      var cr = CReal.from(0.1) + CReal.from(0.2);

      expect(cr.toStringAsPrecision(20, 10, true),
          isNot('0.30000000000000000000'));
    });
  });

  group('operators', () {
    group('sqrt', () {
      test('throws when negative', () {
        var cr = CReal.from(-9).sqrt();
        expect(() => cr.toStringAsPrecision(0),
            throwsA(isA<ArithmeticException>()));
      });
      const ints = {
        9: "3",
        1: "1",
        25: "5",
      };
      for (var e in ints.entries) {
        test('int ${e.key}', () {
          var cr = CReal.from(e.key);
          expect(cr.sqrt().toStringAsPrecision(0), e.value);
        });
      }
      const doubles = {
        2: "1.41421",
        3: "1.73205",
        100000 * 1000000: "316227.76602",
      };
      for (var e in doubles.entries) {
        test('double ${e.key}', () {
          var cr = CReal.from(e.key).sqrt();
          expect(cr.toStringAsPrecision(5), e.value);
        });
      }
    });
    group('abs', () {
      var expected = cr(100);
      test('with negative', () {
        var cr = CReal.from(-100);
        expect(cr.abs().toString(), expected.toString());
      });
      test('with positive', () {
        var cr = CReal.from(100);
        expect(cr.abs().toString(), expected.toString());
      });
    });
    group('exp', () {
      final m = {
        cr(0): '1',
        cr(1): '2.71828182845904523536',
        cr(-1): '0.36787944117144232159',
        cr(-10): '0.00004539992976248485',
      };

      for (var e in m.entries) {
        test(e.key.toString(), () {
          expect(e.key.exp().toStringAsPrecision(20), e.value);
        });
      }

      test('e', () {
        var e20 = '2.71828182845904523536';
        expect(CReal.e.toStringAsPrecision(20), e20);
        var e257 =
            '2.71828182845904523536028747135266249775724709369995957496696762772407663035354759457138217852516642742746639193200305992181741359662904357290033429526059563073813232862794349076323382988075319525101901157383418793070215408914993488416750924476146066808226480';
        expect(CReal.e.toStringAsPrecision(257, 10, true), e257);
      });
    });
    group('pow', () {
      final m = {
        cr(1).pow(cr(1)): '1',
        cr(2).pow(cr(4)): '16',
        cr(1.5).pow(cr(2)): '2.25',
        cr(60).pow(cr(5)): '777600000',
        cr(60).pow(cr(-1)): '0.01666666666666666667',
        CReal.e.pow(CReal.e): '15.15426224147926418976',
      };
      for (var e in m.entries) {
        test(e.key, () {
          expect(e.key.toStringAsPrecision(20), e.value);
        });
      }
    });
  });

  group('SlowCReal', () {
    group('pi', () {
      test('15 digits', () {
        var cr = CReal.pi;
        var expected = "3.141592653589793";
        expect(cr.toStringAsPrecision(15), expected);
      });
      test('300 digits', () {
        var cr = CReal.pi;
        var expected =
            "3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067982148086513282306647093844609550582231725359408128481117450284102701938521105559644622948954930381964428810975665933446128475648233786783165271201909145648566923460348610454326648213393607260249141274";
        expect(cr.toStringAsPrecision(300), expected);
      });
      test('1/(Pi*1000)', () {
        var cr = CReal.from(1) / (CReal.pi * CReal.from(1000));
        var expected =
            "0.0003183098861837906715377675267450287240689192914809128974953347";
        expect(cr.toStringAsPrecision(64), expected);
      });
    });
    group('cos', () {
      // integer precision
      final m = {
        CReal.from(0): '1',
        CReal.pi: '-1',
        CReal.from(2) * CReal.pi: '1',
        //1/2pi + 3pi
        cr(1) / cr(2) * CReal.pi + cr(3) * CReal.pi: '0'
      };
      for (var e in m.entries) {
        test(e.key.toString(), () {
          expect(e.key.cos().toStringAsPrecision(0), e.value);
        });
      }

      // arbitrary precision
      final a = {
        cr(1): '0.54030230586813971740',
        cr(5): '0.28366218546322626447',
        cr(-35): '-0.90369220509150675985',
        cr(8008): '-0.99677560117552725167',
      };
      for (var e in a.entries) {
        test(e.key.toString(), () {
          expect(e.key.cos().toStringAsPrecision(20, 10, true), e.value);
        });
      }
    });
    group('sin', () {
      // integer precision
      final m = {
        cr(0): '0',
        CReal.pi: '0',
        // sin(3/2pi)
        cr(3) / cr(2) * CReal.pi: '-1',
        // sin(2pi+1/2pi)
        cr(2) * CReal.pi + cr(1) / cr(2) * CReal.pi: '1',
      };
      for (var e in m.entries) {
        test(e.key.toString(), () {
          expect(e.key.sin().toStringAsPrecision(0), e.value);
        });
      }

      // arbitrary precision
      final a = {
        cr(531): '-0.07078230485740781010',
        cr(-53): '-0.39592515018183418150',
        CReal.parse('0.4321'): '0.41877870990075814929'
      };
      for (var e in a.entries) {
        test(e.key.toString(), () {
          expect(e.key.sin().toStringAsPrecision(20, 10, true), e.value);
        });
      }
    });

    group('tan', () {
      // integer precision
      final m = {
        cr(0): '0',
        CReal.pi: '0',
        cr(3) / cr(4) * CReal.pi: '-1',
      };
      for (var e in m.entries) {
        test(e.key.toString(), () {
          expect(e.key.tan().toStringAsPrecision(4), e.value);
        });
      }

      // arbitrary precision
      final a = {
        cr(1): '1.55740772465490223051',
        cr(8780): '-0.93433997451292766996',
        cr(-10): '-0.64836082745908667126',
      };
      for (var e in a.entries) {
        test(e.key.toString(), () {
          expect(e.key.tan().toStringAsPrecision(20, 10, true), e.value);
        });
      }
    });
    group('asin', () {
      final m = {
        cr(0): '0',
        cr(1): '1.57079632679489661923',
        cr(0.5): '0.52359877559829887308',
        cr(-1): '-1.57079632679489661923',
      };
      for (var e in m.entries) {
        test(e.key.toString(), () {
          expect(e.key.asin().toStringAsPrecision(20), e.value);
        });
      }
    });
    group('acos', () {
      final m = {
        cr(1): '0',
        cr(0): '1.57079632679489661923',
        cr(0.5): '1.04719755119659774616',
        cr(-1): '3.14159265358979323846',
      };
      for (var e in m.entries) {
        test(e.key.toString(), () {
          expect(e.key.acos().toStringAsPrecision(20), e.value);
        });
      }
    });
    group('atan', () {
      final m = {
        cr(1): '0.78539816339744830962',
        cr(0): '0',
        CReal.pi: '1.26262725567891168344',
        cr(-1): '-0.78539816339744830962',
      };
      for (var e in m.entries) {
        test(e.key.toString(), () {
          expect(e.key.atan().toStringAsPrecision(20), e.value);
        });
      }
    });
    group('ln', () {
      final m = {
        cr(1): '0',
        CReal.e: '1',
        cr(100): '4.60517018598809136804',
        cr(100000000000): '25.3284360229345025242',
      };
      for (var e in m.entries) {
        test(e.key.toString(), () {
          expect(e.key.ln().toStringAsPrecision(20), e.value);
        });
      }
      test('throws when negative', () {
        var cr = CReal.from(-1);
        expect(() => cr.ln().toString(), throwsA(isA<ArithmeticException>()));
      });
    });
  });
}
