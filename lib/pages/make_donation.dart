import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class MakeDonation extends StatefulWidget {
  @override
  _MakeDonationState createState() => _MakeDonationState();
}

final String testID = 'pack.south-africa';
bool _available = true;
TextEditingController nameController = new TextEditingController();
TextEditingController bodyController = new TextEditingController();

sendEmail() async {
  final Email email = Email(
    body:
        'This is an automated message. Click send to ensure that I get this message. \n\n Message:\n${bodyController.text}',
    subject: nameController.text,
    recipients: ['christo.c.kruger@gmail.com'],
    isHTML: false,
  );
  await FlutterEmailSender.send(email);
}

class _MakeDonationState extends State<MakeDonation> {
  StreamSubscription _purchaseUpdatedSubscription;
  StreamSubscription _purchaseErrorSubscription;
  StreamSubscription _conectionSubscription;
  final List<String> _productLists = Platform.isAndroid
      ? [
          'android.test.purchased',
          '10_message',
          '5_message',
          '2_message',
          'android.test.canceled',
        ]
      : ['com.cooni.point1000', 'com.cooni.point5000'];

  String _platformVersion = 'Unknown';
  List<IAPItem> _items = [];
  List<PurchasedItem> _purchases = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    if (_conectionSubscription != null) {
      _conectionSubscription.cancel();
      _conectionSubscription = null;
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await FlutterInappPurchase.instance.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // prepare
    var result = await FlutterInappPurchase.instance.initConnection;
    print('result: $result');

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });

    // refresh items for android
    try {
      String msg = await FlutterInappPurchase.instance.consumeAllItems;
      print('consumeAllItems: $msg');
    } catch (err) {
      print('consumeAllItems error: $err');
    }

    _conectionSubscription =
        FlutterInappPurchase.connectionUpdated.listen((connected) {
      print('connected: $connected');
    });

    _purchaseUpdatedSubscription =
        FlutterInappPurchase.purchaseUpdated.listen((productItem) {
      print('purchase-updated: $productItem');
    });

    _purchaseErrorSubscription =
        FlutterInappPurchase.purchaseError.listen((purchaseError) {
      print('purchase-error: $purchaseError');
    });
    await _getProduct();
  }

  void _requestPurchase(IAPItem item) {
    FlutterInappPurchase.instance.requestPurchase(item.productId);
  }

  Future _getProduct() async {
    List<IAPItem> items =
        await FlutterInappPurchase.instance.getProducts(_productLists);
    for (var item in items) {
      //print('${item.toString()}');
      if (item.title.contains('message')) {
        _items.add(item);
      }
    }

    setState(() {
      this._items = items;
      this._purchases = [];
    });
    //print('items: ${_items}');
  }

  Future _getPurchases() async {
    List<PurchasedItem> items =
        await FlutterInappPurchase.instance.getAvailablePurchases();
    for (var item in items) {
      print('${item.toString()}');
      this._purchases.add(item);
    }

    setState(() {
      this._items = [];
      this._purchases = items;
    });
  }

  Future _getPurchaseHistory() async {
    List<PurchasedItem> items =
        await FlutterInappPurchase.instance.getPurchaseHistory();
    for (var item in items) {
      print('${item.toString()}');
      this._purchases.add(item);
    }

    setState(() {
      _items = [];
      _purchases = items;
    });
  }

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _formKey,
      backgroundColor: Color(0xff326c60),
      appBar: AppBar(
        backgroundColor: Color(0xff439080),
        title: Text(
            _available ? 'Make a donation' : 'This service is unavailable'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(8),
                height: 80,
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _items
                      .where((item) => item.title.contains('Message'))
                      .map((prod) => FlatButton(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text(prod.title.split(' (D')[0]),
                                Text(prod.localizedPrice)
                              ],
                            ),
                            onPressed: () {
                              _requestPurchase(prod);
                            },
                            color: Colors.amberAccent,
                          ))
                      .toList(),
                ),
              ),
              Text(
                'The following is for sending in a custom card:',
                style: TextStyle(fontSize: 18),
              ),
              Card(
                elevation: 4,
                child: Container(
                  color: Colors.amberAccent[100],
                  padding: EdgeInsets.all(12),
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 25,
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: Color(0xff439080),
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        padding: EdgeInsets.all(12),
                        child: TextFormField(
                          autovalidate: true,
                          maxLength: 48,
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                          controller: nameController,
                          decoration: InputDecoration(
                            hintText: 'Your name here',
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Color(0xff439080),
                            borderRadius: BorderRadius.all(Radius.circular(8))),
                        child: TextFormField(
                          autovalidate: true,
                          maxLength: 128,
                          minLines: 1,
                          maxLines: 3,
                          validator: (value) {
                            if (value.isEmpty) {
                              return 'Please enter some text';
                            }
                            return null;
                          },
                          controller: bodyController,
                          decoration: InputDecoration(
                            hintText: 'Your rule here',
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      RaisedButton(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: <Widget>[
                              Text(
                                'Send',
                                style: TextStyle(fontSize: 18),
                              ),
                              Text('(This will send as an email)')
                            ],
                          ),
                        ),
                        onPressed: () {
                          if (bodyController.text.isNotEmpty &&
                              nameController.text.isNotEmpty) {
                            sendEmail();
                          }
                        },
                        color: Colors.amber,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
