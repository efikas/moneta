import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:moneta/moneta.dart';
import 'package:moneta/services/services.dart';
import 'package:moneta/utils/charge.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:moneta/values/constants.dart';

// ignore: must_be_immutable
class MonetaInitialize extends StatefulWidget {
  Charge charge;
  bool rrr;
  dynamic useSplit;
  String publicKey;
  String secretKey;
  CheckoutMethod method;
  Function callbackMethod;
  String callBackUrl;

  MonetaInitialize(
      {Key key,
      @required this.charge,
      @required this.rrr,
      @required this.useSplit,
      @required this.method,
      @required this.publicKey,
      @required this.secretKey,
      @required this.callBackUrl,
      @required this.callbackMethod})
      : super(key: key);

  @override
  _MonetaInitializeState createState() => _MonetaInitializeState();
}

class _MonetaInitializeState extends State<MonetaInitialize> with Services {
  bool isCompleted = false;
  String paymentType = "card";
  String baseUrl = "";
  String callbackUrl = "";
  String channel = "";

  InAppWebViewController webViewController;
  String url = "";
  double progress = 0;
  Digest sha512Result;

  @override
  void initState() {
    super.initState();
    setState(() {
      callbackUrl = Uri.encodeFull(widget.callBackUrl);
      baseUrl = Constants.monetaBaseUrl;
    });
    this.setPaymentChannel(widget.method);

    String initializationString =
        "${widget.charge.email}${widget.charge.amount}$paymentType${widget.callBackUrl}";

    List<int> key = utf8.encode(widget.secretKey);
    List<int> bytes = utf8.encode(initializationString); 

    var hmacSha512 = new Hmac(sha512, key);
    sha512Result = hmacSha512.convert(bytes);
  }

  Digest getVerificationHash(String reference){
    String verificationString = "$reference$paymentType"; 

    List<int> key = utf8.encode(widget.secretKey);
    List<int> bytes = utf8.encode(verificationString);

    var hmacSha512 = new Hmac(sha512, key);
    return hmacSha512.convert(bytes);
  }

  setPaymentChannel(paymentMethod) {
    switch (paymentMethod) {
      case CheckoutMethod.card:
        setState(() {
          channel = "card";
          paymentType = "card";
        });
        break;
      case CheckoutMethod.bank:
        setState(() {
          channel = "";
          paymentType = "bank";
        });
        break;
      case CheckoutMethod.ussd:
        setState(() {
          channel = "ussd";
          paymentType = "card";
        });
        break;
      case CheckoutMethod.cheque:
        setState(() {
          channel = "";
          paymentType = "bank";
        });
        break;
      case CheckoutMethod.transfer:
        setState(() {
          channel = "bank";
          paymentType = "card";
        });
        break;
      default:
        setState(() {
          channel = "card";
          paymentType = "card";
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          InAppWebView(
            initialUrl: "${baseUrl}transaction/initialize?${getUrl()}",
            initialHeaders: {
              "Authorization": "Bearer ${widget.publicKey}",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            initialOptions: InAppWebViewGroupOptions(
              // android: AndroidInAppWebViewOptions(
              //   useShouldInterceptRequest: true,
              // ),
              crossPlatform: InAppWebViewOptions(
                useShouldOverrideUrlLoading: true,
                javaScriptEnabled: true,
                userAgent:
                    "Mozilla/5.0 (Linux; Android 7.0; SM-G930V Build/NRD90M) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.125 Mobile Safari/537.36",
                debuggingEnabled: true,
              ),
            ),
            shouldOverrideUrlLoading: (InAppWebViewController controller,
                ShouldOverrideUrlLoadingRequest
                    shouldOverrideUrlLoadingRequest) async {
              if (Platform.isAndroid ||
                  shouldOverrideUrlLoadingRequest.iosWKNavigationType ==
                      IOSWKNavigationType.LINK_ACTIVATED) {
                await controller.loadUrl(
                    url: shouldOverrideUrlLoadingRequest.url,
                    headers: {
                      "Authorization": "Bearer ${widget.publicKey}",
                      "Content-Type": "application/json",
                      "Accept": "application/json",
                    });
                return ShouldOverrideUrlLoadingAction.CANCEL;
              }

              return ShouldOverrideUrlLoadingAction.ALLOW;
            },
            // androidShouldInterceptRequest: (InAppWebViewController controller,
            //     WebResourceRequest request) async {
            //   await controller.loadUrl(url: request.url, headers: {
            //     "Authorization": "Bearer ${widget.publicKey}",
            //     "Content-Type": "application/json",
            //     "Accept": "application/json",
            //   });
            //   return;
            // },
            onWebViewCreated: (InAppWebViewController controller) {
              webViewController = controller;
            },
            onLoadStart: (InAppWebViewController controller, String url) async {
              setState(() {
                this.url = url;
              });

              print(url);

              /// when there is a duplicated transaction ref on moneta,
              /// it redirect to api/v1/transaction/error
              var uri = Uri.parse(url);
              if (uri.queryParameters.containsKey("reference")) {
                String refNumber = uri.queryParameters["reference"] ?? "";
                this.updateIsCompleted(false);

                ///verify the transaction
                Map<String, dynamic> response = await apiGetRequests(
                  "verify/$paymentType/$refNumber?hash=${getVerificationHash(refNumber)}",
                  baseUrl: Constants.monetaBaseUrl,
                  token: widget.publicKey,
                );

                if (response["status"] == "success") {
                  // if the payment method is bank, format the response

                  if (paymentType == "bank") {
                    response = this.verifyBankAndFormatResponse(response);
                  }

                  /// check if the reference number exist
                  if (response["data"]["reference"] != null &&
                      response["data"]["reference"] != "") {
                    widget.callbackMethod(response["data"]);
                  } else {
                    widget.callbackMethod(null);
                  }
                } else {
                  widget.callbackMethod(null);
                }

                this.updateIsCompleted(true);

                response = null;
                Navigator.pop(context);
              }

              if (url.contains("transaction/error")) {
                widget.callbackMethod(null);
                this.updateIsCompleted(true);

                Future.delayed(Duration(seconds: 25), () {
                  Navigator.pop(context);
                });
              }
            },
            onLoadStop: (InAppWebViewController controller, String url) async {
              setState(() {
                this.url = url;
              });
              this.updateIsCompleted(true);
            },
            onProgressChanged:
                (InAppWebViewController controller, int progress) {
              setState(() {
                this.progress = progress / 100;
              });
            },
          ),
          _showStack(),
        ],
      ),
    );
  }

  updateIsCompleted(bool status) {
    isCompleted = status;
  }

  Widget _showStack() {
    if (!isCompleted) {
      return Container(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SizedBox();
  }

  String getUrl() {
    ///payment type -- card payment : card, pay later: bank.

    if (widget.charge.transRef != null && widget.charge.transRef.trim() != "") {
      return "amount=${widget.charge.amount}&email=${widget.charge.email}&hash=$sha512Result&payment_type=$paymentType&channel=$channel&callback_url=$callbackUrl&customerinfo=${widget.charge.metadata}&transaction_reference=${widget.charge.transRef}";
    }

    if(widget.rrr != null && widget.rrr == true){
      return "amount=${widget.charge.amount}&email=${widget.charge.email}&hash=$sha512Result&payment_type=$paymentType&channel=$channel&callback_url=$callbackUrl&customerinfo=${widget.charge.metadata}&metadata=${widget.charge.parameters}&rrr=${widget.rrr}";
    }

    if(widget.useSplit != null && (widget.useSplit == true || widget.useSplit.runtimeType == String)){
      return "amount=${widget.charge.amount}&email=${widget.charge.email}&hash=$sha512Result&payment_type=$paymentType&channel=$channel&callback_url=$callbackUrl&customerinfo=${widget.charge.metadata}&metadata=${widget.charge.parameters}&use_split=${widget.useSplit}";
    }

    return "amount=${widget.charge.amount}&email=${widget.charge.email}&hash=$sha512Result&payment_type=$paymentType&channel=$channel&callback_url=$callbackUrl&customerinfo=${widget.charge.metadata}&metadata=${widget.charge.parameters}";
  }

  Map<String, dynamic> verifyBankAndFormatResponse(
      Map<String, dynamic> response) {
    /// check if the initialize response is really for the transaction
    Map<String, dynamic> metas = jsonDecode(widget.charge.metadata);
    String amount = (widget.charge.amount / 100).toStringAsFixed(2);

    if (response["customer"]["Email"] == widget.charge.email &&
        response["customer"]["AmountDue"] == amount &&
        response["customer"]["FirstName"] == metas["first_name"] &&
        response["customer"]["OtherName"] == metas["other_name"] &&
        response["customer"]["LastName"] == metas["last_name"]) {
      response = {
        ...response,
        "data": {
          "reference": response["customer"]["Customer_Id"],
          "status": response["status"],
          "channel": paymentType,
          "message": "",
        }
      };
    }

    return response;
  }
}
