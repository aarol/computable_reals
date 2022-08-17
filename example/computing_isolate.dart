import 'dart:isolate';

import 'package:computable_reals/computable_reals.dart';

/// Example of parallel creal computation using isolates.
/// Note that Flutter apps have access to the `compute` function,
/// which simplifies the process greatly.
Future<void> main() async {
  var crs = List.generate(10, (index) {
    return CReal.from(index) / CReal.from(2);
  });
  var ports = <ReceivePort>[];

  for (var cr in crs) {
    var p = ReceivePort();
    Isolate.spawn(_compute, [p.sendPort, cr]);
    ports.add(p);
  }
  for (var p in ports) {
    p.first.then(print);
  }
}

Future<String> _compute(List args) {
  SendPort responsePort = args[0];
  CReal cr = args[1];
  var s = cr.toString();
  Isolate.exit(responsePort, s);
}
