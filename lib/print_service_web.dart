import 'dart:js_interop';

@JS('window.print')
external void _windowPrint();

bool openPrintDialog() {
  _windowPrint();
  return true;
}
