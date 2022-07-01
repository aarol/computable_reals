export 'creal.dart' show CReal;
export 'functions.dart' show SqrtCReal;
export 'operators.dart' show MultCReal;

import 'precision_vm.dart' if (dart.library.html) 'precision_js.dart'
    as platform;

const intMinValue = platform.intMinValue;
