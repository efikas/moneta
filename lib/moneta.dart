library moneta;

export './utils/charge.dart';
export './utils/checkout_response.dart';

import 'package:flutter/material.dart';
import 'package:moneta/utils/charge.dart';
import 'package:moneta/utils/checkout_response.dart';
import 'package:moneta/utils/exceptions.dart';
import 'package:moneta/widgets/initialize_page2.dart';

class Moneta {
  static String _publicKey;
  static String _secretKey;
  static String _callBackUrl;
  static bool _rrr;
  static dynamic _useSplit = false;
  static CheckoutResponse response;

  Moneta._();

  /// Initialize the moneta API
  // static Future<Moneta> initialize({
  static Future<void> initialize({
    @required String publicKey,
    @required String callBackUrl,
    @required String secretKey,
    bool rrr = false,
    dynamic useSplit
  }) async {
    assert(() {
      if (publicKey == null || publicKey.isEmpty) {
        throw new MonetaException('publicKey cannot be null or empty');
      }

      if (secretKey == null || secretKey.isEmpty) {
        throw new MonetaException('secretKey cannot be null or empty');
      }

      if (callBackUrl == null || callBackUrl.isEmpty) {
        throw new MonetaException('CallBack Url cannot be null or empty');
      }

      return true;
    }());

    _secretKey = secretKey;
    _publicKey = publicKey;
    _callBackUrl = callBackUrl;

    if (rrr != null && rrr == true) {
      _rrr = rrr;
    }

    if (useSplit != null && (useSplit == true || useSplit.runtimeType == String)) {
      _useSplit = useSplit;
    }
  }

  static checkout(
    BuildContext context, {
    @required Charge charge,
    CheckoutMethod method,
    Function(CheckoutResponse response) onCompleted,
  }) async {
    await Moneta._navigateAndDisplaySelection(
      context,
      method,
      charge,
      onCompleted,
    );
  }

  // A method that launches the SelectionScreen and awaits the
  // result from Navigator.pop.
  static _navigateAndDisplaySelection(
    BuildContext context,
    CheckoutMethod method,
    Charge charge,
    Function(CheckoutResponse response) onCompleted,
  ) async {
    await showPicture(
      context,
      charge: charge,
      method: method,
      rrr: _rrr,
      useSplit: _useSplit,
      publicKey: _publicKey,
      secretKey: _secretKey,
      callBackUrl: _callBackUrl,
      callbackMethod: (Map<String, dynamic> resp) async {
        CheckoutResponse res = await updateResponse(resp);
        if (onCompleted != null) {
          onCompleted(res);
        }
      },
    );
  }

  static showPicture(
    BuildContext context, {
    Charge charge,
    CheckoutMethod method,
    bool rrr,
    dynamic useSplit,
    String publicKey,
    String secretKey,
    String callBackUrl,
    Function callbackMethod,
  }) {
    Widget alert = AlertDialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(40.0),
        ),
      ),
      content: Builder(
        builder: (context) {
          var height = MediaQuery.of(context).size.height;
          var width = MediaQuery.of(context).size.width;

          return Container(
            height: height - 200,
            width: width - 50,
            child: Stack(
              children: [
                Container(
                  height: height - 200,
                  width: width - 50,
                  child: MonetaInitialize(
                    charge: charge,
                    method: method,
                    rrr: rrr,
                    useSplit: useSplit,
                    publicKey: publicKey,
                    secretKey: secretKey,
                    callBackUrl: callBackUrl,
                    callbackMethod: callbackMethod,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    color: Colors.grey,
                    icon: Icon(
                      Icons.close_outlined,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    showDialog(
      barrierDismissible: false,
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (_) => alert,
    );
  }

  static Future<CheckoutResponse> updateResponse(
      Map<String, dynamic> resp) async {
    if (resp == null) {
      response = CheckoutResponse.defaults();
      return CheckoutResponse.defaults();
    }
    response = CheckoutResponse.fromJson(resp);
    return CheckoutResponse.fromJson(resp);
  }
}

enum CheckoutMethod { card, bank, ussd, transfer, cheque }
