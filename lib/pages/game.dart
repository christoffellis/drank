import 'dart:io';
import 'dart:async';

import 'dart:async' show Future;
import 'package:drinkinggame/pages/add_players.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:drinkinggame/classes/players.dart';
import 'package:drinkinggame/classes/categories_class.dart';
import 'package:flutter/material.dart';
import 'categories_page.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart';
import 'dart:convert';

class Game extends StatefulWidget {
  @override
  _GameState createState() => _GameState();
}

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
    haystack = haystack.replaceAll('*enter*', '\n\n');
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

class _GameState extends State<Game> {
  String buttonText = 'Click to start';
  Icon categoryIcon;
  String categoryType = '';
  Color buttonColor = Colors.greenAccent;
  int actionCount = 1;

  _loadActions() async {
    loadableCategories.clear();
    actionLineup.clear();
    actionCount = 0;
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

  _updateButton() async {
    /*
  This checks if the amount of cards displayed exceeds the amount of cards available.
  If not, a fresh card is displayed and the
   */
    if (actionCount == 0) {
    } else if (actionLineup.length > actionCount && actionCount < 65) {
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
    } else if (actionLineup.length == actionCount || actionCount == 65) {
      buttonText =
          'That\'s a wrap.\n Thanks for playing and consider voting 5 stars! \n\n Click again to return to the main menu';
      buttonColor = Colors.grey[300];
      categoryType = '';
    } else {
      Navigator.pushNamed(context, '/home');
    }

    actionCount += 1;
  }

  @override
  void initState() {
    _loadActions().whenComplete(() {
      setState(() {});
    });
    _logCategories();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff224840),
      body: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Card(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [Colors.grey[50], Colors.grey[400]])
                    .createShader(bounds);
              },
              blendMode: BlendMode.colorBurn,
              child: FlatButton(
                onPressed: () async {
                  _updateButton().whenComplete(() {
                    setState(() {});
                  });
                },
                color: buttonColor,
                child: Column(
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
                                      .firstWhere((cat) =>
                                          cat.className == categoryType)
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
                    LinearProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation(Colors.black.withOpacity(0.2)),
                      backgroundColor: Colors.black.withOpacity(0.1),
                      value: (actionCount /
                          (actionLineup.length > 65
                              ? 66
                              : actionLineup.length + 1)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
