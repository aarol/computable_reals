export 'creal.dart' show CReal;

import 'precision_vm.dart' if (dart.library.html) 'precision_js.dart'
    as platform;

const intMinValue = platform.intMinValue;
