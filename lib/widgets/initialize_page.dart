//import 'dart:async';
//import 'dart:convert';
//import 'package:flutter/material.dart';
//import 'package:moneta/moneta.dart';
//import 'package:moneta/services/services.dart';
//import 'package:moneta/utils/charge.dart';
//import 'package:webview_flutter/webview_flutter.dart';
//
//// ignore: must_be_immutable
//class MonetaInitialize extends StatefulWidget {
//  Charge charge;
//  String publicKey;
//  CheckoutMethod method;
//  Function callbackMethod;
//  String callBackUrl;
//  String monetaBaseUrl;
//
//  MonetaInitialize(
//      {Key key,
//      @required this.charge,
//      @required this.method,
//      @required this.publicKey,
//      @required this.callBackUrl,
//      @required this.monetaBaseUrl,
//      @required this.callbackMethod})
//      : super(key: key);
//
//  @override
//  _MonetaInitializeState createState() => _MonetaInitializeState();
//}
//
//class _MonetaInitializeState extends State<MonetaInitialize> with Services {
//  Completer<WebViewController> _controller = Completer<WebViewController>();
//  bool isCompleted = false;
//  String paymentType = "card";
//  String baseUrl = "";
//  String callbackUrl = "";
//  String channel = "";
//
//  @override
//  void initState() {
//    super.initState();
//
//    setState(() {
//      callbackUrl = Uri.encodeFull(widget.callBackUrl);
//      baseUrl = widget.monetaBaseUrl;
//    });
//    this.setPaymentChannel(widget.method);
//  }
//
//  setPaymentChannel(paymentMethod) {
//    switch (paymentMethod) {
//      case CheckoutMethod.card:
//        setState(() {
//          channel = "card";
//          paymentType = "card";
//        });
//        break;
//      case CheckoutMethod.bank:
//        setState(() {
//          channel = "";
//          paymentType = "bank";
//        });
//        break;
//      case CheckoutMethod.ussd:
//        setState(() {
//          channel = "ussd";
//          paymentType = "card";
//        });
//        break;
//      case CheckoutMethod.cheque:
//        setState(() {
//          channel = "";
//          paymentType = "bank";
//        });
//        break;
//      case CheckoutMethod.transfer:
//        setState(() {
//          channel = "bank";
//          paymentType = "card";
//        });
//        break;
//      default:
//        setState(() {
//          channel = "card";
//          paymentType = "card";
//        });
//    }
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      body: Stack(
//        children: <Widget>[
//          WebView(
//            onPageFinished: (String str) {
//              setState(() {
//                isCompleted = true;
//              });
//            },
//            onPageStarted: (String str) async {
//              /// when there is a duplicated transaction ref on moneta,
//              /// it redirect to api/v1/transaction/error
//              var uri = Uri.parse(str);
//              if (uri.queryParameters.containsKey("reference")) {
//                String refNumber = uri.queryParameters["reference"] ?? "";
//                this.updateIsCompleted(false);
//
//                ///verify the transaction
//                Map<String, dynamic> response = await apiGetRequests(
//                  "verify/$paymentType/$refNumber?api_token=${widget.publicKey}",
//                  baseUrl: widget.monetaBaseUrl,
//                  token: widget.publicKey,
//                );
//
////                debugPrint(response.toString());
//
//                if (response["status"] == "success") {
//                  // if the payment method is bank, format the response
//
//                  if (paymentType == "bank") {
//                    response = this.verifyBankAndFormatResponse(response);
//                  }
//
////                  debugPrint(response.toString());
//
//                  /// check if the reference number exist
//                  if (response["data"]["reference"] != null &&
//                      response["data"]["reference"] != "") {
//                    widget.callbackMethod(response["data"]);
//                  } else {
//                    widget.callbackMethod(null);
//                  }
//                } else {
//                  widget.callbackMethod(null);
//                }
//
//                this.updateIsCompleted(true);
//
//                response = null;
//                Navigator.pop(context);
//              }
//
//              if (str.contains("transaction/error")) {
//                widget.callbackMethod(null);
//                this.updateIsCompleted(true);
//
//                Future.delayed(Duration(seconds: 25), () {
//                  Navigator.pop(context);
//                });
//              }
//            },
//            debuggingEnabled: true,
//            initialUrl: '${baseUrl}transaction/initialize${getUrl()}',
//            javascriptMode: JavascriptMode.unrestricted,
//            userAgent:
//                "Mozilla/5.0 (Linux; Android 7.0; SM-G930V Build/NRD90M) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.125 Mobile Safari/537.36",
//            onWebViewCreated: (WebViewController webViewController) {
//              _controller.complete(webViewController);
//            },
//          ),
//          _showStack(),
//        ],
//      ),
//    );
//  }
//
//  updateIsCompleted(bool status) {
////    setState(() {
//    isCompleted = status;
////    });
//  }
//
//  Widget _showStack() {
//    if (!isCompleted) {
//      return Container(
//        child: Center(child: CircularProgressIndicator()),
//      );
//    }
//    return SizedBox();
//  }
//
//  String getUrl() {
//    ///payment type -- card payment : card, pay later: bank.
//
//    if (widget.charge.transRef != null && widget.charge.transRef.trim() != "") {
//      return "?amount=${widget.charge.amount}&email=${widget.charge.email}&payment_type=$paymentType&channel=$channel&callback_url=$callbackUrl&api_token=${widget.publicKey}&customerinfo=${widget.charge.metadata}&transaction_reference=${widget.charge.transRef}";
//    }
//
//    return "?amount=${widget.charge.amount}&email=${widget.charge.email}&payment_type=$paymentType&channel=$channel&callback_url=$callbackUrl&api_token=${widget.publicKey}&customerinfo=${widget.charge.metadata}&metadata=${widget.charge.parameters}";
//  }
//
//  Map<String, dynamic> verifyBankAndFormatResponse(
//      Map<String, dynamic> response) {
//    /// check if the initialize response is really for the transaction
//    Map<String, dynamic> metas = jsonDecode(widget.charge.metadata);
//    String amount = (widget.charge.amount / 100).toStringAsFixed(2);
//
//    if (response["customer"]["Email"] == widget.charge.email &&
//        response["customer"]["AmountDue"] == amount &&
//        response["customer"]["FirstName"] == metas["first_name"] &&
//        response["customer"]["OtherName"] == metas["other_name"] &&
//        response["customer"]["LastName"] == metas["last_name"]) {
//      response = {
//        ...response,
//        "data": {
//          "reference": response["customer"]["Customer_Id"],
//          "status": response["status"],
//          "channel": paymentType,
//          "message": "",
//        }
//      };
//    }
//
//    return response;
//  }
//}
