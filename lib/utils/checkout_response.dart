import 'package:meta/meta.dart';
import 'package:moneta/common/strings.dart';
import 'package:moneta/moneta.dart';

class CheckoutResponse {
  /// A user readable message. If the transaction was not successful, this returns the
  /// cause of the error.
  String message;
  /// Transaction reference. Might return null for failed transaction transactions
  String reference;

  /// The status of the transaction. A successful response returns true and false
  /// otherwise
  bool status;

  /// The means of payment. It may return [CheckoutMethod.bank] or [CheckoutMethod.card]
  CheckoutMethod method;

  /// If the transaction should be verified. See https://developers.paystack.co/v2.0/reference#verify-transaction
  /// This might return true regardless whether a transaction fails or not.
  bool verify;

  CheckoutResponse.defaults() {
    message = Strings.userTerminated;
    reference = null;
    status = false;
    method = null;
    verify = false;
  }

  CheckoutResponse(
      {@required this.message,
      @required this.reference,
      @required this.status,
      @required this.method,
      @required this.verify});


    CheckoutResponse.fromJson(dynamic resp){
      this.message = resp["message"];
      this.reference = resp["reference"];
      this.status = (resp["status"] == "success") ? true : false;
      this.method = (resp["channel"].toString().toLowerCase() == "bank") ? CheckoutMethod.bank : CheckoutMethod.card;
      this.verify = true;
    }

  @override
  String toString() {
    return 'CheckoutResponse{message: $message, reference: $reference, status: $status, method: $method, verify: $verify}';
  }
}
