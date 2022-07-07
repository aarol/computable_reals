import 'exception.dart';

class Timeout {
  static const timeoutDuration = 3000;
  final s = Stopwatch()..start();

  void check() {
    if (s.elapsedMilliseconds > timeoutDuration) {
      throw TimeoutException();
    }
  }
}
