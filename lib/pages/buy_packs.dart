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
import 'package:drinkinggame/main.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_options.dart';
import 'package:carousel_slider/carousel_slider.dart';

const String testDevice = 'E4D00BAD99E756081B32217D5343EDA3';

List<IAPItem> _items = [];
List<IAPItem> _subscriptions = [];
List<PurchasedItem> _purchases = [];
String _recentCatAdViewed = '';

bool _subscriptionsOpen = false;

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
          'pack.south_africa',
          'pack.afrikaans',
          'pack.hot_and_heavy',
          'pack.countries_of_the_world',
          'pack.dungeons_and_dragons',
          'pack.charades',
          'subscription.general'
        ]
      : []; //todo: add apple items of purchase

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

  void _requestSubscription(IAPItem subscription) async {
    FlutterInappPurchase.instance.requestPurchase(subscription.productId);
  }

  Future _getProduct() async {
    List<IAPItem> items =
        await FlutterInappPurchase.instance.getProducts(_productLists);

    for (var item in items) {
      //print('${item.toString()}');
      _items.add(item);
    }

    List<IAPItem> subs = await FlutterInappPurchase.instance
        .getSubscriptions(['subscription.general']);

    for (var item in subs) {
      //print('${item.toString()}');
      _subscriptions.add(item);
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

  Color _codesColor = Colors.grey[100];
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
            elevation: 0,
            backgroundColor: Colors.transparent,
            iconTheme: IconThemeData(
              color: Colors.white, //change your color here
            ),
          ),
          backgroundColor: Color(0xffFFAB94),
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width * .8,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.fromLTRB(12, 12, 0, 12),
                          child: TextFormField(
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20),
                            controller: codes,
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.all(0),
                                hintText: 'Enter special code',
                                fillColor: _codesColor,
                                filled: true,
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.transparent, width: 0)),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.transparent, width: 0)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: Colors.transparent, width: 0))),
                          ),
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        padding: EdgeInsets.all(0),
                        child: FlatButton(
                          onPressed: () {
                            _checkCodes();
                          },
                          child: Icon(Icons.send),
                        ),
                      )
                    ],
                  ),
                ),
                AnimatedContainer(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Color(0xffFFE67F),
                  ),
                  duration: Duration(milliseconds: 500),
                  margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
                  height: _subscriptionsOpen ? 250 : 35,
                  width: MediaQuery.of(context).size.width *
                      (_subscriptionsOpen ? 0.8 : 0.6),
                  child: _subscriptionsOpen
                      ? SingleChildScrollView(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Column(
                              children: <Widget>[
                                SizedBox(
                                  height: 8,
                                ),
                                CarouselSlider(
                                  options: CarouselOptions(
                                    height: 200,
                                    aspectRatio: 1 / 1,
                                    viewportFraction: 0.8,
                                    initialPage: 0,
                                    enableInfiniteScroll: true,
                                    reverse: false,
                                    autoPlayAnimationDuration:
                                        Duration(milliseconds: 800),
                                    autoPlayCurve: Curves.fastOutSlowIn,
                                    enlargeCenterPage: true,
                                    scrollDirection: Axis.horizontal,
                                  ),
                                  items: <Widget>[
                                    Container(
                                      color: Color(0xffF1D359),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: <Widget>[
                                            Text('General Subscription'),
                                            Text(
                                                ' - Unlocks all packs indefinitely\n - Continue games without watching\n     an ad'),
                                            FlatButton(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          16)),
                                              child: Text('Subscribe'),
                                              onPressed: () {
                                                _requestSubscription(
                                                    _subscriptions[0]);
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Container(
                                  width: 200,
                                  height: 30,
                                  child: FlatButton(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            bottom: Radius.circular(0),
                                            top: Radius.circular(12))),
                                    color: Colors.black12,
                                    child: Icon(Icons.arrow_drop_up),
                                    onPressed: () {
                                      setState(() {
                                        _subscriptionsOpen =
                                            !_subscriptionsOpen;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : FlatButton(
                          child: Text('VIP Subscriptions'),
                          onPressed: () {
                            setState(() {
                              _subscriptionsOpen = !_subscriptionsOpen;
                            });
                          },
                        ),
                ),
                SizedBox(
                  height: 20,
                ),
                CarouselSlider(
                  options: CarouselOptions(
                    height: 400,
                    aspectRatio: 16 / 9,
                    viewportFraction: 0.8,
                    initialPage: 0,
                    enableInfiniteScroll: true,
                    reverse: false,
                    autoPlayAnimationDuration: Duration(milliseconds: 800),
                    autoPlayCurve: Curves.fastOutSlowIn,
                    enlargeCenterPage: true,
                    scrollDirection: Axis.horizontal,
                  ),
                  items: categories
                      .where((cat) => !cat.bought)
                      .map((cat) => Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: cat.classColor,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Center(
                                  child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: HSVColor.fromColor(cat.classColor)
                                          .withSaturation(0.4)
                                          .withValue(0.95)
                                          .toColor(),
                                    ),
                                    padding: EdgeInsets.all(20),
                                    child: Icon(
                                      cat.classIcon,
                                      size: 48,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 8),
                                    decoration: BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(
                                      color: Colors.black.withOpacity(0.4),
                                    ))),
                                    child: Text(
                                      cat.className,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    cat.description,
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    'There are ${categoryCounts[cat.classId]} cards in this pack',
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  Text(
                                    _items
                                            .where((prod) =>
                                                prod.productId == cat.storeId)
                                            .isNotEmpty
                                        ? _items
                                            .firstWhere((prod) =>
                                                prod.productId == cat.storeId)
                                            .localizedPrice
                                        : 'Price unavailable',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    cat.adWatchesNeeded() > 0
                                        ? 'or watch ${cat.adWatchesNeeded()} more ad${cat.adWatchesNeeded() == 1 ? '' : 's'} to play'
                                        : 'or try this pack in your next game',
                                    style: TextStyle(
                                        color: Colors.black.withOpacity(0.5)),
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      FlatButton(
                                        color: Colors.white.withOpacity(0.6),
                                        shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: Colors.white,
                                              width: 0.8,
                                            ),
                                            borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(20),
                                                bottomLeft:
                                                    Radius.circular(20))),
                                        onPressed: () {
                                          _requestPurchase(_items.firstWhere(
                                              (prod) =>
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
                                        color: Colors.white.withOpacity(0.6),
                                        shape: RoundedRectangleBorder(
                                            side: BorderSide(
                                              color: Colors.white,
                                              width: 0.8,
                                            ),
                                            borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(20),
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
                          ))
                      .toList(),
                ),
              ],
            ),
          )),
    );
  }
}
