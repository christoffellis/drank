import 'dart:ui';

import 'package:drinkinggame/classes/categories_class.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';

bool _playPress = false;
bool _buyPress = false;

List<IAPItem> _items = [];
List<PurchasedItem> _purchases = [];
Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

List<category> categories = [];
category ownEntry =
    category('Own entries', 'own', Icons.mode_edit, Colors.teal[200]);

_initCategories() async {
  final SharedPreferences prefs = await _prefs;

  categories = [
    category('Pretty Basic', 'general', Icons.all_inclusive, Color(0xffFFB6A8),
        desc: 'The way it\'s meant to be played. Standard rules, all the fun',
        active: prefs.getBool('general.active')),
    category('Hot and Heavy', 'hah', Icons.whatshot, Color(0xffFCACFC),
        desc:
            'Time to get down and dirty. Play for some naughty fun. Time to get those lips wet',
        active: prefs.getBool('hah.active') ?? true,
        bought: prefs.getBool('hah.bought') ?? false,
        minAdCount: 3,
        currAdCount: prefs.getInt('hah.adRewardCount') ?? 0,
        storeId: 'pack.hot_and_heavy'),
    category('King of the Cups', 'kotc', Icons.local_drink, Color(0xffF3FFA8),
        active: prefs.getBool('kotc.active') ?? false,
        desc:
            'King of the Cups, a popular card game, to be played on Drank. Works best when played on its own, although if you want to play with other card packs, feel free to do so'),
    category('Finisher', 'finisher', Icons.trending_down, Color(0xffFFA8A8),
        desc:
            'Fewer cards make for fewer chance of getting a finisher. These cards require the whole table to down their drinks. For faster, more powerful games',
        active: prefs.getBool('finisher.active') ?? true),
    category('Countries of the World', 'cotw', Icons.public, Color(0xff91FFC4),
        active: prefs.getBool('cotw.active') ?? true,
        desc:
            'Challenge friends to see who knows more about the countries of the world!',
        bought: prefs.getBool('cotw.bought') ?? false,
        minAdCount: 2,
        currAdCount: prefs.getInt('cotw.adRewardCount') ?? 0,
        storeId: 'pack.countries_of_the_world'),
    category('Afrikaans', 'afrikaans', Icons.flag, Color(0xffAEFFA8),
        active: prefs.getBool('afrikaans.active') ?? true,
        desc:
            'For the afrikaans speaking. Rich with cultural references and nostalgia. Best paired with a Brandy and Coke',
        bought: prefs.getBool('afrikaans.bought') ?? false,
        minAdCount: 1,
        currAdCount: prefs.getInt('afrikaans.adRewardCount') ?? 0,
        storeId: 'pack.afrikaans'),
    category('SU', 'su', Icons.school, Color(0xffE46484),
        active: prefs.getBool('su.active') ?? true,
        desc:
            'Made for student from Stellenbosch University. Challenge your flat mate or dare to upset a rival residence',
        enabled: prefs.getBool('su.enabled') ?? false),
    category('NWU', 'nwu', Icons.school, Color(0xffAF88CD),
        active: prefs.getBool('nwu.active') ?? true,
        desc:
            'Made for student from Potchefstroom. Challenge your flat mate or dare to upset a rival residence',
        enabled: prefs.getBool('nwu.enabled') ?? false),
    category('South Africa', 'sa', Icons.supervisor_account, Color(0xffA8DCFF),
        desc:
            'The patriotic experience. Have fun with friends in this South African related pack',
        active: prefs.getBool('sa.active') ?? true,
        bought: prefs.getBool('sa.bought') ?? false,
        minAdCount: 2,
        currAdCount: prefs.getInt('sa.adRewardCount') ?? 0,
        storeId: 'pack.south_africa'),
    category('Charades', 'charades', Icons.accessibility_new, Color(0xffA8DCFF),
        desc: 'Jump up and down and get drunk doing it',
        active: prefs.getBool('charades.active') ?? true,
        bought: prefs.getBool('charades.bought') ?? false,
        minAdCount: 2,
        currAdCount: prefs.getInt('charades.adRewardCount') ?? 0,
        storeId: 'pack.charades'),
    category('Dungeons and Dragons', 'dnd', Icons.casino, Color(0xffFA8B8B),
        desc:
            'Made to play during a game of DnD, each card will bring a unique experience for each round of playing with your party. Drink some, play some',
        active: prefs.getBool('dnd.active') ?? true,
        bought: prefs.getBool('dnd.bought') ?? false,
        minAdCount: 2,
        currAdCount: prefs.getInt('dnd.adRewardCount') ?? 0,
        storeId: 'packs.dungeons_and_dragons'),
  ];

  ownEntry = category('Own entries', 'own', Icons.mode_edit, Color(0xffA8CBFF),
      active: prefs.getBool('own.active') ?? true);
}

_updateCategoryActive(category cat) async {
  final SharedPreferences prefs = await _prefs;
  prefs.setBool('${cat.classId}.active', cat.active);
}

Future<String> loadAsset() async {
  return await rootBundle.loadString('assets/actions.txt');
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  File myFile;
  if (!(await File('$path/actions.txt').exists())) {
    var myFile = new File('$path/actions.txt');
    print(myFile.create());
    var temp = await rootBundle.loadString('assets/actions.txt');

    myFile.writeAsString(temp);
  }
  myFile = File('$path/actions.txt');
  return myFile;
}

Map categoryCounts = {};

int _activeCardCount = 0;
int _ownCardCount = 0;

class Choose_Categories extends StatefulWidget {
  @override
  _Choose_CategoriesState createState() => _Choose_CategoriesState();
}

class _Choose_CategoriesState extends State<Choose_Categories> {
  _updateCatCounts() async {
    categoryCounts.clear();
    final file = await _localFile;
    String content = await file.readAsString();
    List<String> lines = content.split('\n');
    lines.removeWhere((element) => (element == '\r'));
    for (String line in lines) {
      if (categoryCounts.containsKey(line.split('#')[0])) {
        categoryCounts.update(line.split('#')[0], (value) => value + 1);
      } else {
        categoryCounts[line.split('#')[0]] = 1;
      }
    }
    await _setActiveCardCount();
  }

  _setActiveCardCount() async {
    _activeCardCount = 0;
    categoryCounts.forEach((key, value) {
      try {
        if (categories.firstWhere((cat) => (cat.classId == key)).active &&
            categories.firstWhere((cat) => (cat.classId == key)).enabled &&
            categories.firstWhere((cat) => (cat.classId == key)).bought) {
          _activeCardCount += value;
        }
      } catch (error) {
        print('The key $key is not yet initialized! Ignoring for now.');
      }
    });
    if (await File('${await _localPath}/own.txt').exists() && ownEntry.active) {
      String content = await File('${await _localPath}/own.txt').readAsString();
      setState(() {
        _activeCardCount +=
            content.split('\n').where((text) => text.length > 2).length;
        _ownCardCount =
            content.split('\n').where((text) => text.length > 2).length;
      });
    }
  }

  bool _animatedClicked = false;

  String _informationText =
      'To select or unselect a category, tap on it. Selected categories are shown in colour, while unselected categories are grayed out';

  StreamSubscription _purchaseUpdatedSubscription;
  StreamSubscription _purchaseErrorSubscription;
  StreamSubscription _conectionSubscription;
  final List<String> _productLists = Platform.isAndroid
      ? [
          'pack.hot_and_heavy',
          'pack.south_africa',
          'pack.afrikaans',
          'pack.countries_of_the_world',
          'pack.dungeons_and_dragons',
          'pack.charades',
          'subscription.general',
        ]
      : ['com.cooni.point1000', 'com.cooni.point5000'];

  final List<String> _subscriptionList = Platform.isAndroid
      ? [
          'subscription.general',
        ]
      : ['com.cooni.point1000', 'com.cooni.point5000'];

  String _platformVersion = 'Unknown';

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xffFFAB94),
    ));

    _initCategories();
    print(categories.where((cat) => cat.bought).length);
    _updateCatCounts().whenComplete(() {
      initPlatformState().whenComplete(() {
        setState(() {
          updateCategories().whenComplete(() {});
        });
      });
    });
    print(categories.where((cat) => cat.bought).length);

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
      print('purchase-updated: $productItem');

      setState(() {
        categories
            .firstWhere((cat) => cat.storeId == productItem.productId)
            .bought = true;
      });
    });

    _purchaseErrorSubscription =
        FlutterInappPurchase.purchaseError.listen((purchaseError) {
      print('purchase-error: $purchaseError');
    });
  }

  hasSubscription() async {
    return await FlutterInappPurchase.instance
        .checkSubscribed(sku: 'subscription.general');
  }

  updateCategories() async {
    try {
      SharedPreferences prefs = await _prefs;

      if (await hasSubscription()) {
        categories.forEach((cat) {
          setState(() {
            cat.bought = true;
          });
        });
        await _getPurchaseHistory();
        for (PurchasedItem item in _purchases) {
          print(item);
          if (categories
              .where((cat) => cat.storeId == item.productId)
              .isNotEmpty)
            categories
                .firstWhere((cat) => cat.storeId == item.productId)
                .bought = true;
          prefs.setBool(
              '${categories.firstWhere((cat) => cat.storeId == item.productId).classId}.bought',
              true);
        }
      }
    } on PlatformException catch (e) {
      print(e.code);
    }
  }

  void _requestPurchase(IAPItem item) {
    var response =
        FlutterInappPurchase.instance.requestPurchase(item.productId);
    print('response: $response');
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
      _items = items;
      _purchases = [];
    });
    //print('items: ${_items}');
  }

  Future _getPurchases() async {
    List<PurchasedItem> items =
        await FlutterInappPurchase.instance.getAvailablePurchases();
    for (var item in items) {
      //print('${item.toString()}');
      _purchases.add(item);
    }

    setState(() {
      _items = [];
      _purchases = items;
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

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: Colors.white, //change your color here
        ),
      ),
      backgroundColor: Color(0xffFFAB94),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                height: MediaQuery.of(context).size.height,
                child: ListView(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  children: <Widget>[
                    SizedBox(
                      height: 10,
                    ),
                    Center(
                      child: Stack(
                        overflow: Overflow.visible,
                        children: <Widget>[
                          Positioned(
                            child: Container(
                              height: MediaQuery.of(context).size.height * .15,
                              width: MediaQuery.of(context).size.width * .6,
                              decoration: BoxDecoration(
                                  color: Color(0xffE7E7E7),
                                  borderRadius: BorderRadius.circular(48)),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: Duration(milliseconds: 150),
                            top: _playPress ? 0 : -10,
                            child: Container(
                              height: MediaQuery.of(context).size.height * .15,
                              width: MediaQuery.of(context).size.width * .6,
                              child: FlatButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                                child: Text(
                                  'Continue',
                                  style: TextStyle(fontSize: 30),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _playPress = !_playPress;
                                  });

                                  Future.delayed(Duration(milliseconds: 150))
                                      .whenComplete(() {
                                    Navigator.pushNamed(context, '/game');
                                    setState(() {
                                      _playPress = !_playPress;
                                    });
                                  });
                                },
                              ),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(48)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Center(
                      child: Stack(
                        overflow: Overflow.visible,
                        children: <Widget>[
                          Positioned(
                            child: Container(
                              height: MediaQuery.of(context).size.height * .06,
                              width: MediaQuery.of(context).size.width * .4,
                              decoration: BoxDecoration(
                                  color: Color(0xffECCE50),
                                  borderRadius: BorderRadius.circular(48)),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: Duration(milliseconds: 150),
                            top: _buyPress ? 0 : -6,
                            child: Container(
                              height: MediaQuery.of(context).size.height * .06,
                              width: MediaQuery.of(context).size.width * .4,
                              child: FlatButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                                child: Text(
                                  'Get more packs',
                                  style: TextStyle(fontSize: 18),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _buyPress = !_buyPress;
                                  });

                                  Future.delayed(Duration(milliseconds: 150))
                                      .whenComplete(() {
                                    Navigator.pushNamed(context, '/buypacks');
                                    setState(() {
                                      _buyPress = !_buyPress;
                                    });
                                  });
                                },
                              ),
                              decoration: BoxDecoration(
                                  color: Color(0xffFFE67F),
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 24,
                    ),
                    Container(
                        decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  offset: Offset(3, -3)),
                            ],
                            color: Color(0xffFAA48C),
                            borderRadius: BorderRadius.circular(24)),
                        margin: EdgeInsets.symmetric(horizontal: 12),
                        padding:
                            EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                        child: Column(
                          children: <Widget>[
                                Text(
                                  'Tap to enable packs',
                                  style: TextStyle(fontSize: 24),
                                ),
                                SizedBox(
                                  height: 8,
                                )
                              ] +
                              categories
                                  .where((cat) => cat.bought && cat.enabled)
                                  .map((category) => Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Container(
                                          height: 70,
                                          child: Stack(
                                            overflow: Overflow.visible,
                                            children: <Widget>[
                                              Positioned(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                      color: HSVColor.fromColor(
                                                              category
                                                                  .classColor)
                                                          .withValue(0.85)
                                                          .toColor(),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              48)),
                                                ),
                                              ),
                                              AnimatedPositioned(
                                                top: category.active ? -6 : 0,
                                                height: 70,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.844,
                                                duration:
                                                    Duration(milliseconds: 50),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(48),
                                                  child: ShaderMask(
                                                    shaderCallback:
                                                        (Rect bounds) {
                                                      return LinearGradient(
                                                              begin: Alignment
                                                                  .topCenter,
                                                              end: Alignment
                                                                  .bottomCenter,
                                                              colors: [
                                                            Colors.black,
                                                            Colors.white
                                                          ])
                                                          .createShader(bounds);
                                                    },
                                                    blendMode: category.active
                                                        ? BlendMode.dst
                                                        : BlendMode.hue,
                                                    child: FlatButton(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          48)),
                                                      color:
                                                          category.classColor,
                                                      onPressed: () {
                                                        setState(() {
                                                          category.active =
                                                              !category.active;
                                                        });
                                                      },
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8.0),
                                                        child: Row(
                                                          children: <Widget>[
                                                            Icon(
                                                              category
                                                                  .classIcon,
                                                              size: 28,
                                                            ),
                                                            SizedBox(
                                                              width: 12,
                                                            ),
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: <
                                                                  Widget>[
                                                                Text(category
                                                                    .className),
                                                                Text(category
                                                                        .active
                                                                    ? 'Enabled with ${categoryCounts[category.classId]} cards'
                                                                    : 'This pack is disabled'),
                                                              ],
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ))
                                  .toList() +
                              [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    height: 70,
                                    child: Stack(
                                      overflow: Overflow.visible,
                                      children: <Widget>[
                                        Positioned(
                                          child: Container(
                                            decoration: BoxDecoration(
                                                color: HSVColor.fromColor(
                                                        ownEntry.classColor)
                                                    .withValue(0.85)
                                                    .toColor(),
                                                borderRadius:
                                                    BorderRadius.circular(48)),
                                          ),
                                        ),
                                        AnimatedPositioned(
                                          top: ownEntry.active ? -6 : 0,
                                          height: 70,
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.844,
                                          duration: Duration(milliseconds: 50),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(48),
                                            child: ShaderMask(
                                              shaderCallback: (Rect bounds) {
                                                return LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.black,
                                                      Colors.white
                                                    ]).createShader(bounds);
                                              },
                                              blendMode: ownEntry.active
                                                  ? BlendMode.dst
                                                  : BlendMode.hue,
                                              child: FlatButton(
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            48)),
                                                color: ownEntry.classColor,
                                                onPressed: () {
                                                  setState(() {
                                                    ownEntry.active =
                                                        !ownEntry.active;
                                                  });
                                                },
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    children: <Widget>[
                                                      Icon(
                                                        ownEntry.classIcon,
                                                        size: 28,
                                                      ),
                                                      SizedBox(
                                                        width: 12,
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: <Widget>[
                                                          Text(ownEntry
                                                              .className),
                                                          Text(ownEntry.active
                                                              ? 'Enabled with ${_ownCardCount} cards'
                                                              : 'This pack is disabled'),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                )
                              ],
                        )),
                    SizedBox(
                      height: 20,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
