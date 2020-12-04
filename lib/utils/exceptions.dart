import 'package:moneta/common/strings.dart';

class MonetaException implements Exception {
  String message;

  MonetaException(this.message);

  @override
  String toString() {
    if (message == null) return Strings.unKnownError;
    return message;
  }
}