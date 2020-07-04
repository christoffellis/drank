import 'dart:ui';

import 'package:drinkinggame/classes/categories_class.dart';
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

List<IAPItem> _items = [];
List<PurchasedItem> _purchases = [];
Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

List<category> categories = [];
category ownEntry =
    category('Own entries', 'own', Icons.mode_edit, Colors.teal[200]);

_initCategories() async {
  final SharedPreferences prefs = await _prefs;

  categories = [
    category('Pretty Basic', 'general', Icons.all_inclusive,
        Colors.deepOrangeAccent[200],
        desc: 'The way it\'s meant to be played. Standard rules, all the fun',
        active: prefs.getBool('general.active')),
    category('Hot and Heavy', 'hah', Icons.whatshot, Color(0xffc670fc),
        desc:
            'Time to get down and dirty. Play for some naughty fun. Time to get those lips wet',
        active: prefs.getBool('hah.active') ?? true,
        bought: prefs.getBool('hah.bought') ?? false,
        minAdCount: 3,
        currAdCount: prefs.getInt('hah.adRewardCount') ?? 0,
        storeId: 'pack.hot_and_heavy'),
    category('King of the Cups', 'kotc', Icons.local_drink, Color(0xfffce770),
        active: prefs.getBool('kotc.active') ?? false,
        desc:
            'King of the Cups, a popular card game, to be played on Drank. Works best when played on its own, although if you want to play with other card packs, feel free to do so'),
    category('Finisher', 'finisher', Icons.trending_down, Color(0xfffc7070),
        desc:
            'Fewer cards make for fewer chance of getting a finisher. These cards require the whole table to down their drinks. For faster, more powerful games',
        active: prefs.getBool('finisher.active') ?? true),
    category('Countries of the World', 'cotw', Icons.public, Colors.green[400],
        active: prefs.getBool('cotw.active') ?? true,
        desc:
            'Challenge friends to see who knows more about the countries of the world!',
        bought: prefs.getBool('cotw.bought') ?? false,
        minAdCount: 2,
        currAdCount: prefs.getInt('cotw.adRewardCount') ?? 0,
        storeId: 'pack.countries_of_the_world'),
    category('Afrikaans', 'afrikaans', Icons.flag, Colors.lightGreen[300],
        active: prefs.getBool('afrikaans.active') ?? true,
        desc:
            'For the afrikaans speaking. Rich with cultural references and nostalgia. Best paired with a Brandy and Coke',
        bought: prefs.getBool('afrikaans.bought') ?? false,
        minAdCount: 1,
        currAdCount: prefs.getInt('afrikaans.adRewardCount') ?? 0,
        storeId: 'pack.afrikaans'),
    category('SU', 'su', Icons.school, Color.fromARGB(255, 228, 100, 132),
        active: prefs.getBool('su.active') ?? true,
        desc:
            'Made for student from Stellenbosch University. Challenge your flat mate or dare to upset a rival residence',
        enabled: prefs.getBool('su.enabled') ?? false),
    category('NWU', 'nwu', Icons.school, Color(0xffAF88CD),
        active: prefs.getBool('nwu.active') ?? true,
        desc:
            'Made for student from Potchefstroom. Challenge your flat mate or dare to upset a rival residence',
        enabled: prefs.getBool('nwu.enabled') ?? false),
    category('South Africa', 'sa', Icons.supervisor_account, Colors.lightBlue,
        desc:
            'The patriotic experience. Have fun with friends in this South African related pack',
        active: prefs.getBool('sa.active') ?? true,
        bought: prefs.getBool('sa.bought') ?? false,
        minAdCount: 2,
        currAdCount: prefs.getInt('sa.adRewardCount') ?? 0,
        storeId: 'pack.south_africa'),
    /*
    category('Dungeons and Dragons', 'dnd', Icons.casino, Colors.red[600],
        desc:
            'Made to play during a game of DnD, each card will bring a unique experience for each round of playing with your party. Drink some, play some',
        active: prefs.getBool('dnd.active') ?? true,
        bought: prefs.getBool('dnd.bought') ?? false,
        minAdCount: 2,
        currAdCount: prefs.getInt('dnd.adRewardCount') ?? 0,
        storeId: 'packs.dungeons_and_dragons'), */
  ];

  ownEntry = category('Own entries', 'own', Icons.mode_edit, Colors.teal[200],
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
          'android.test.purchased',
          'pack.hot_and_heavy',
          'pack.south_africa',
          'pack.afrikaans',
          'pack.countries_of_the_world',
          'android.test.canceled',
        ]
      : ['com.cooni.point1000', 'com.cooni.point5000'];

  String _platformVersion = 'Unknown';

  @override
  void initState() {
    print('init');
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

  updateCategories() async {
    try {
      SharedPreferences prefs = await _prefs;
      await _getPurchaseHistory();
      for (PurchasedItem item in _purchases) {
        if (categories.where((cat) => cat.storeId == item.productId).isNotEmpty)
          categories.firstWhere((cat) => cat.storeId == item.productId).bought =
              true;
        prefs.setBool(
            '${categories.firstWhere((cat) => cat.storeId == item.productId).classId}.bought',
            true);
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
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        backgroundColor: Color(0xff439080),
        title: Text('Click to select categories'),
        actions: <Widget>[
          Container(
            width: 60,
            child: FlatButton(
              onPressed: () {
                _animatedClicked = !_animatedClicked;
                setState(() {});
              },
              child: Icon(Icons.info),
            ),
          )
        ],
      ),
      backgroundColor: Color(0xff326c60),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: _animatedClicked ? 150 : 0,
              decoration: BoxDecoration(color: Colors.grey[200], boxShadow: [
                BoxShadow(
                  color: Colors.grey[800].withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ]),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      Text(
                        _informationText,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height - 80,
              child: ListView(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                children: [
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Container(
                          height: 80,
                          width: 220,
                          child: RaisedButton(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Text('Play!'),
                                Text(
                                  '$_activeCardCount cards active',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                )
                              ],
                            ),
                            elevation: 20,
                            color: Colors.grey[100],
                            onPressed: () {
                              Navigator.pushNamed(context, '/game');
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(125, 0, 125, 10),
                        child: Container(
                          width: 100,
                          child: RaisedButton(
                            color: Colors.amberAccent,
                            child: Text('Get new packs'),
                            onPressed: () {
                              Navigator.pushNamed(context, '/buypacks');
                            },
                          ),
                        ),
                      )
                    ] +
                    categories
                        .where((cat) => cat.bought && cat.enabled)
                        .map((category) => Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [Colors.black, Colors.white])
                                      .createShader(bounds);
                                },
                                blendMode: category.active
                                    ? BlendMode.dst
                                    : BlendMode.hue,
                                child: RaisedButton(
                                  color: category.classColor,
                                  onPressed: () {
                                    setState(() {
                                      category.active = !category.active;
                                      _updateCategoryActive(category);
                                      _setActiveCardCount();
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(25.0),
                                    child: Column(
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Icon(
                                              category.classIcon,
                                              size: 30,
                                            ),
                                            SizedBox(
                                              width: 20,
                                            ),
                                            Expanded(
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: <Widget>[
                                                  Text(
                                                    category.className,
                                                    style:
                                                        TextStyle(fontSize: 18),
                                                  ),
                                                  Text(
                                                    category.active
                                                        ? categoryCounts[category
                                                                    .classId]
                                                                .toString() +
                                                            ' cards'
                                                                .replaceFirst(
                                                                    'null cards',
                                                                    '')
                                                        : 'Disabled',
                                                    style: TextStyle(
                                                        color:
                                                            Colors.grey[800]),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        AnimatedContainer(
                                            constraints: _animatedClicked
                                                ? BoxConstraints(maxHeight: 100)
                                                : BoxConstraints(maxHeight: 0),
                                            duration:
                                                Duration(milliseconds: 300),
                                            child: Text(category.description))
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ))
                        .toList() +
                    [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Colors.black, Colors.white])
                                .createShader(bounds);
                          },
                          blendMode:
                              ownEntry.active ? BlendMode.dst : BlendMode.hue,
                          child: RaisedButton(
                            color: ownEntry.classColor,
                            onPressed: () {
                              setState(() {
                                ownEntry.active = !ownEntry.active;
                                _updateCategoryActive(ownEntry);
                                _setActiveCardCount().whenComplete(() {});
                              });
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(25.0, 25, 25, 2),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Icon(
                                        ownEntry.classIcon,
                                        size: 30,
                                      ),
                                      SizedBox(
                                        width: 20,
                                      ),
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: <Widget>[
                                            Text(
                                              ownEntry.className,
                                              style: TextStyle(fontSize: 18),
                                            ),
                                            Text(
                                              ownEntry.active
                                                  ? _ownCardCount.toString() +
                                                      ' cards'
                                                  : 'Disabled',
                                              style: TextStyle(
                                                  color: Colors.grey[700]),
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  FlatButton(
                                    color: Colors.teal[100],
                                    shape: new RoundedRectangleBorder(
                                        borderRadius:
                                            new BorderRadius.circular(10.0)),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                          context, '/ownentries');
                                    },
                                    child: Icon(Icons.open_in_new),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
