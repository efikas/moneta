import 'package:flutter/material.dart';
import 'package:moneta/moneta.dart';
import 'package:submit_button/submit_button.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moneta Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Moneta Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {

    @override
    void initState() { 
      super.initState();
      Moneta.initialize(
        secretKey: "secrete token",
        publicKey: "moneta private key",
        callBackUrl: "your api call back url",
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SubmitButton(
              button: FlatButton(child: Text("Pay"),
              onPressed: _payNow,
              ),
              isLoading: false,
              backgroundColor: Colors.green,
            )
          ],
        ),
      ),
    );
  }

  _payNow() async {

    Charge charge = Charge()
      ..amount = 500000 // Moneta value is in Kobo, this equals 5000 naira
      ..reference = "MNYT767673GI83738" /// unique reference
      ..putMetaData("phone", "payer phone")
      ..putMetaData("first_name", "payer's first name")
      ..putMetaData("last_name", "payer's last name")
      ..putMetaData("other_name", "payer's other names")
      ..email = "payer's email";

    CheckoutResponse response =  await Moneta.checkout(
      context,
      method: CheckoutMethod.card, // Defaults to CheckoutMethod.card
      charge: charge,
    );

    print(response.reference);
    print(response.status);
    print(response.message);
    
  }
}
