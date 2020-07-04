import 'package:drinkinggame/pages/categories_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:firebase_admob/firebase_admob.dart';

const String testDevice = 'Mobile_id';

List<IAPItem> _items = [];
List<PurchasedItem> _purchases = [];
String _recentCatAdViewed = '';

String adId = 'ca-app-pub-2227511639014188/7503484377';
String admobId = 'ca-app-pub-2227511639014188~2895716024';

class BuyPacks extends StatefulWidget {
  @override
  _BuyPacksState createState() => _BuyPacksState();
}

_logPurchase(String prodID) async {
  String url = 'http://christoffellis.pythonanywhere.com/update-tally';
  Map<String, String> headers = {"Content-type": "application/json"};
  String jsonString =
      '{"plays":{"categories":[]},"buys":{"categories":["$prodID"]}}';
  print(jsonString);
  Response response = await post(
    url,
    headers: headers,
    body: json.encode(jsonString),
  );
  String body = response.body;
  print(body);
}

//todo: update amount of views with shared prefs

bool _buttonsActive = false;

class _BuyPacksState extends State<BuyPacks> {
  static const MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
      testDevices: testDevice != null ? <String>[testDevice] : null,
      nonPersonalizedAds: true,
      keywords: <String>['Drinking', 'game', 'alcohol']);

  StreamSubscription _purchaseUpdatedSubscription;
  StreamSubscription _purchaseErrorSubscription;
  StreamSubscription _conectionSubscription;
  final List<String> _productLists = Platform.isAndroid
      ? [
          'android.test.purchased',
          'pack.south_africa',
          'pack.afrikaans',
          'pack.hot_and_heavy',
          'pack.countries_of_the_world',
          'android.test.canceled',
        ]
      : ['com.cooni.point1000', 'com.cooni.point5000'];

  String _platformVersion = 'Unknown';

  RewardedVideoAd videoAd = RewardedVideoAd.instance;

  @override
  void initState() {
    initPlatformState().whenComplete(() => null);
    FirebaseAdMob.instance.initialize(appId: admobId);
    videoAd.listener =
        (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {
      if (event == RewardedVideoAdEvent.rewarded) {
        setState(() {
          categories
              .firstWhere((cat) => cat.classId == _recentCatAdViewed)
              .rewardForAd();
          if (categories
                  .firstWhere((cat) => cat.classId == _recentCatAdViewed)
                  .adWatchesNeeded() <=
              0) {
            _showDialog(
                'The pack "${categories.firstWhere((cat) => cat.classId == _recentCatAdViewed).className}" will be available in the next game you play');
          }
        });
      } else if (event == RewardedVideoAdEvent.closed) {
        videoAd.load(adUnitId: adId, targetingInfo: targetingInfo);
      } else if (event == RewardedVideoAdEvent.loaded) {
        setState(() {
          _buttonsActive = true;
        });
        print('loaded new ad');
      }
    };
    videoAd.load(adUnitId: adId, targetingInfo: targetingInfo);
    super.initState();
  }

  @override
  void dispose() {
    if (_conectionSubscription != null) {
      _conectionSubscription.cancel();
      _conectionSubscription = null;
    }
    super.dispose();
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
      _logPurchase(productItem.productId);
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
      _items.add(item);
    }

    setState(() {
      _items = items;
      _purchases = [];
    });
  }

  TextEditingController codes = new TextEditingController();

  Future _getPurchases() async {
    List<PurchasedItem> items =
        await FlutterInappPurchase.instance.getAvailablePurchases();
    for (var item in items) {
      print('${item.toString()}');
      _purchases.add(item);
    }

    setState(() {
      _items = [];
      _purchases = items;
    });
  }

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Color _codesColor = Colors.black.withOpacity(0.1);
  _checkCodes() async {
    final SharedPreferences prefs = await _prefs;

    String url = 'http://christoffellis.pythonanywhere.com/check-special-code';
    Map<String, String> headers = {"Content-type": "application/json"};
    String jsonString = '{"message":"${codes.text}"}';
    Response response = await post(
      url,
      headers: headers,
      body: json.encode(jsonString),
    );
    String body = response.body;
    print(body);
    int returnCode = response.statusCode;

    setState(() {
      if (returnCode == 200 && body != 'failed') {
        Map jsonCont = json.decode(body);
        prefs.setBool(jsonCont["category"], jsonCont["status"]);
        _codesColor = Colors.lightGreenAccent[100];
        _showDialog(
            "You will have to restart the app for these changes to take effect");
      } else {
        _codesColor = Colors.redAccent[100];
      }
    });
  }

  Future _getPurchaseHistory() async {
    List<PurchasedItem> items =
        await FlutterInappPurchase.instance.getPurchaseHistory();
    for (var item in items) {
      print('${item.toString()}');
      _purchases.add(item);
    }

    setState(() {
      _items = [];
      _purchases = items;
    });
  }

  void _showDialog(String text) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Notice"),
          content: new Text(text),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Okay"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _returnCallback() async {
    Choose_Categories().createState();
    Navigator.pop(context);
    return await true;
  }

  AdProcedure(cat) {
    videoAd.show().whenComplete(() {
      _recentCatAdViewed = cat.classId;
    });
    _buttonsActive = false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _returnCallback,
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: Color(0xff439080),
            title: Text('Buy new card packs'),
          ),
          backgroundColor: Color(0xff326c60),
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        margin: EdgeInsets.fromLTRB(15, 15, 0, 0),
                        width: 200,
                        child: TextFormField(
                          controller: codes,
                          decoration: InputDecoration(
                              hintText: 'Enter special code',
                              fillColor: _codesColor,
                              filled: true),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 15, 0, 0),
                      width: 50,
                      height: 50,
                      child: FlatButton(
                        onPressed: () {
                          _checkCodes();
                        },
                        child: Icon(Icons.send),
                      ),
                    )
                  ],
                ),
                Column(
                  children: categories
                      .where((cat) => !cat.bought)
                      .map((cat) => ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return LinearGradient(
                                begin: Alignment.bottomLeft,
                                end: Alignment.topRight,
                                colors: <Color>[
                                  cat.classColor.withOpacity(.6),
                                  HSVColor.fromColor(cat.classColor)
                                      .withSaturation(1)
                                      .toColor()
                                      .withOpacity(.4)
                                ],
                                tileMode: TileMode.mirror,
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.colorBurn,
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Card(
                                color: cat.classColor,
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Center(
                                      child: Column(
                                    children: <Widget>[
                                      Icon(cat.classIcon),
                                      Text(
                                        cat.className,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 20),
                                      ),
                                      Text(
                                        cat.description,
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        'There are ${categoryCounts[cat.classId]} cards in this pack',
                                        style:
                                            TextStyle(color: Colors.grey[700]),
                                      ),
                                      Text(
                                        _items
                                                .where((prod) =>
                                                    prod.productId ==
                                                    cat.storeId)
                                                .isNotEmpty
                                            ? _items
                                                .firstWhere((prod) =>
                                                    prod.productId ==
                                                    cat.storeId)
                                                .localizedPrice
                                            : 'Price unavailable',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        cat.adWatchesNeeded() > 0
                                            ? 'or watch ${cat.adWatchesNeeded()} more ad${cat.adWatchesNeeded() == 1 ? '' : 's'} to play'
                                            : 'or try this pack in your next game',
                                        style: TextStyle(
                                            color:
                                                Colors.black.withOpacity(0.5)),
                                      ),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          FlatButton(
                                            color:
                                                Colors.white.withOpacity(0.6),
                                            shape: RoundedRectangleBorder(
                                                side: BorderSide(
                                                  color: Colors.white,
                                                  width: 0.8,
                                                ),
                                                borderRadius: BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(20),
                                                    bottomLeft:
                                                        Radius.circular(20))),
                                            onPressed: () {
                                              _requestPurchase(
                                                  _items.firstWhere((prod) =>
                                                      prod.productId ==
                                                      cat.storeId));
                                              setState(() {});
                                            },
                                            child: Text('Buy it'),
                                            //color: Colors.white.withAlpha(128),
                                          ),
                                          FlatButton(
                                            disabledColor:
                                                Colors.white.withOpacity(0.3),
                                            color:
                                                Colors.white.withOpacity(0.6),
                                            shape: RoundedRectangleBorder(
                                                side: BorderSide(
                                                  color: Colors.white,
                                                  width: 0.8,
                                                ),
                                                borderRadius: BorderRadius.only(
                                                    topRight:
                                                        Radius.circular(20),
                                                    bottomRight:
                                                        Radius.circular(20))),
                                            onPressed: !_buttonsActive
                                                ? null
                                                : () => AdProcedure(cat),

                                            child: Text(_buttonsActive
                                                ? 'Try it'
                                                : 'Loading ad'),
                                            //color: Colors.white.withAlpha(128),
                                          ),
                                        ],
                                      )
                                    ],
                                  )),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          )),
    );
  }
}
