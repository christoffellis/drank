import 'dart:io';
import 'dart:async';

import 'dart:async' show Future;
import 'package:drinkinggame/pages/add_players.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:drinkinggame/classes/players.dart';
import 'package:drinkinggame/classes/categories_class.dart';
import 'package:drinkinggame/main.dart';
import 'package:flutter/material.dart';
import 'categories_page.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class Game extends StatefulWidget {
  @override
  _GameState createState() => _GameState();
}

const String testDevice = 'E4D00BAD99E7560'; //81B32217D5343EDA3';

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<File> get _actionsFile async {
  final path = await _localPath;
  File myFile;
  if (!(await File('$path/actions.txt').exists())) {
    var myFile = new File('$path/actions.txt');
    var temp = await rootBundle.loadString('assets/actions.txt');

    myFile.writeAsString(temp);
  }
  myFile = File('$path/actions.txt');
  return myFile;
}

Future<File> get _ownFile async {
  final path = await _localPath;
  File myFile;
  if (!(await File('$path/own.txt').exists())) {
    var myFile = new File('$path/own.txt');
    var temp = await rootBundle.loadString('assets/own.txt');

    myFile.writeAsString(temp);
  }
  myFile = File('$path/own.txt');
  return myFile;
}

List<category> loadableCategories = [];
List<String> actionLineup = [];
bool _answerCardShown = true;
String _answerString;

_getPlayerNamesSorted() {
  players.sort(
      (a, b) => a.getRelativeplayCount().compareTo(b.getRelativeplayCount()));
  List<String> names = [];
  for (Player play in players) {
    names.add(play.name);
  }
  return names;
}

_replaceMarkers(String haystack) {
  List<String> names = _getPlayerNamesSorted();
  if (haystack.contains('@name1')) {
    players.where((i) => (i.name == names[0])).toList()[0].playCount += 1;
    haystack = haystack.replaceAll('@name1', names[0]);
  }
  if (haystack.contains('@name2')) {
    haystack = (names.length >= 2)
        ? haystack.replaceAll('@name2', names[1])
        : haystack.replaceAll('@name2', 'Player 2');
  }

  if (haystack.contains('*enter*')) {
    _answerString = haystack.split('*enter*')[1];
    _answerCardShown = false;
    haystack = haystack.split('*enter*')[0] + '\n\nTap to get the answer';
  }

  return haystack;
}

_logCategories() async {
  String url = 'http://christoffellis.pythonanywhere.com/update-tally';
  Map<String, String> headers = {"Content-type": "application/json"};
  String insertStr = '';
  categories.where((cat) => cat.activeInGame()).forEach((cat) {
    insertStr += '"${cat.classId}",';
  });
  insertStr = insertStr.substring(0, insertStr.length - 1);
  String jsonString =
      '{"plays":{"categories":[$insertStr]},"buys":{"categories":[]}}';
  print(jsonString);
  Response response = await post(
    url,
    headers: headers,
    body: json.encode(jsonString),
  );
  String body = response.body;
  //print(body);
}

Widget _buttonBarChild = Container();

int _actionCountLimit = 65;
bool _buttonsActive = false;

class _GameState extends State<Game> {
  String buttonText = 'Click to start';
  Icon categoryIcon;
  String categoryType = '';
  Color buttonColor = Colors.greenAccent;
  int actionCount = 1;

  static const MobileAdTargetingInfo targetingInfo = MobileAdTargetingInfo(
      testDevices: testDevice != null ? <String>[testDevice] : null,
      nonPersonalizedAds: true,
      keywords: <String>['Drinking', 'game', 'alcohol']);

  _loadActions() async {
    loadableCategories.clear();
    actionLineup.clear();
    actionCount = 0;
    _actionCountLimit = 65;
    for (category cat in categories) {
      if (cat.activeInGame()) {
        loadableCategories.add(cat);
        cat.checkIfReward();
        print('added ${cat.className} to loadables');
      }
    }

    final actionsFile = await _actionsFile;
    String content = await actionsFile.readAsString();
    List<String> lines = content.split('\n');
    for (String line in lines) {
      for (category cat in loadableCategories) {
        if (cat.classId.contains(line.split('#')[0]) && line.length > 0) {
          actionLineup.add(line.replaceAll('\r', ''));
        }
      }
    }

    if (ownEntry.active) {
      final ownFile = await _ownFile;
      String ownContent = await ownFile.readAsString();
      List<String> ownLines = ownContent.split('\n');
      for (String line in ownLines) {
        actionLineup.add('own#$line');
      }
    }

    actionLineup.shuffle();

    if (loadableCategories.where((cat) => cat.classId == 'cotw').isNotEmpty) {
      actionLineup.insert(1,
          'cotw#To play Countries of The World, read the questions. If the mentioned player can answer the question, they can hand out 2 sips. If they can\'t, they must drink once');
    }

    _updateButton();
  }

  hasSubscription() async {
    return await FlutterInappPurchase.instance
        .checkSubscribed(sku: 'subscription.general');
  }

  _updateButton() async {
    /*
  This checks if the amount of cards displayed exceeds the amount of cards available.
  If not, a fresh card is displayed and the
   */
    if (!_answerCardShown) {
      buttonText = _answerString;
      _answerCardShown = true;
    } else if (actionCount == 0) {
    } else if (actionLineup.length > actionCount &&
        actionCount < _actionCountLimit) {
      if (loadableCategories
              .where((cat) =>
                  (cat.classId == actionLineup[actionCount].split('#')[0]))
              .toList()
              .length >
          0) {
        buttonText = _replaceMarkers(actionLineup[actionCount].split('#')[1]);
        buttonColor = loadableCategories
            .where((cat) =>
                (cat.classId == actionLineup[actionCount].split('#')[0]))
            .toList()[0]
            .classColor;
        categoryType = loadableCategories
            .where((cat) =>
                (cat.classId == actionLineup[actionCount].split('#')[0]))
            .toList()[0]
            .className;
      } else {
        //This is if card is own entry
        buttonText = _replaceMarkers(actionLineup[actionCount].split('#')[1]);
        buttonColor = ownEntry.classColor;
        categoryType = ownEntry.classId;
      }
    } else if (actionLineup.length == actionCount ||
        actionCount == _actionCountLimit) {
      buttonText =
          'That\'s a wrap.\n Thanks for playing and consider voting 5 stars! \n\nIf you would like to continue, you can ${!await hasSubscription() ? 'watch an ad' : 'click below'}. Otherwise, clicking will return you to the main menu';
      buttonColor = Colors.grey[300];

      if (await hasSubscription()) {
        setState(() {
          _buttonBarChild = RaisedButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: Colors.amberAccent[100],
            onPressed: () {
              setState(() {
                _actionCountLimit += 35;
                _updateButton();
                _buttonBarChild = Container();
              });
            },
            child: Text('Continue'),
          );
        });
      } else {
        setState(() {
          _buttonBarChild = RaisedButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: Colors.amberAccent[100],
            onPressed: _buttonsActive
                ? () {
                    videoAd.show();
                  }
                : () {
                    print('did not show ad');
                  },
            child: Text(_buttonsActive ? 'Watch an ad' : 'No ad is available'),
          );
        });
      }
      categoryType = '';
    } else {
      Navigator.popUntil(context, ModalRoute.withName('/home'));
    }
    if (_answerCardShown) {
      actionCount += 1;
    }
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: buttonColor,
    ));
  }

  RewardedVideoAd videoAd = RewardedVideoAd.instance;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: buttonColor,
    ));
    _buttonBarChild = Container();
    _loadActions().whenComplete(() {
      setState(() {});
    });

    FirebaseAdMob.instance.initialize(appId: admobId);
    videoAd.listener =
        (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {
      if (event == RewardedVideoAdEvent.rewarded) {
        setState(() {
          _actionCountLimit += 35;
          _updateButton();
          _buttonBarChild = Container();
        });
      } else if (event == RewardedVideoAdEvent.closed) {
        setState(() {
          _buttonsActive = false;
        });
        videoAd.load(adUnitId: gameAdId, targetingInfo: targetingInfo);
      } else if (event == RewardedVideoAdEvent.loaded) {
        setState(() {
          _buttonsActive = true;
        });
        print('loaded new ad');
      }
    };
    videoAd.load(adUnitId: gameAdId, targetingInfo: targetingInfo);

    _logCategories();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: buttonColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height - 8,
            child: FlatButton(
              onPressed: () async {
                _updateButton().whenComplete(() {
                  setState(() {});
                });
              },
              color: buttonColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    height: 80,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(categoryType == 'own'
                            ? ownEntry.classIcon
                            : categoryType.isNotEmpty
                                ? categories
                                    .firstWhere(
                                        (cat) => cat.className == categoryType)
                                    .classIcon
                                : null),
                        Text(categoryType),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        buttonText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 80,
                    child: _buttonBarChild,
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: buttonColor,
            height: 8,
            width: MediaQuery.of(context).size.width,
            child: LinearProgressIndicator(
              valueColor: AlwaysStoppedAnimation(Colors.black.withOpacity(0.2)),
              backgroundColor: Colors.black.withOpacity(0.1),
              value: (actionCount /
                  (actionLineup.length > _actionCountLimit
                      ? _actionCountLimit + 1
                      : actionLineup.length + 1)),
            ),
          ),
        ],
      ),
    );
  }
}
