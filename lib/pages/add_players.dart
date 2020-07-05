import 'dart:async';
import 'dart:developer';
import 'dart:math';
import 'package:flutter/cupertino.dart';

import 'package:drinkinggame/classes/players.dart';
import 'package:flutter/material.dart';

class AddPlayers extends StatefulWidget {
  @override
  _AddPlayersState createState() => _AddPlayersState();
}

Map textEditorControllers = {' ': new TextEditingController()};
List<Player> players = [Player(' ', _getFunColor())];
int playerCounter = 1;

List<Color> colors = [
  Colors.redAccent,
  Colors.lightGreenAccent,
  Colors.yellowAccent,
  Colors.blueAccent,
  Colors.indigoAccent,
  Colors.purpleAccent,
  Colors.pinkAccent,
  Colors.cyanAccent,
];
Color _getFunColor() {
  var rand = Random();
  Color newColor = colors[rand.nextInt(colors.length)];
  return newColor;
}

_addNewPlayer() {
  players.add(Player('Player $playerCounter', _getFunColor()));
  textEditorControllers['Player $playerCounter'] = new TextEditingController();

  playerCounter++;
}

_removePlayer(Player person) {
  colors.add(person.playerColor);
  players.remove(person);
}

_cleanupPlayers() {
  for (Player person in players) {
    person.name = textEditorControllers[person.name].text;
  }

  players.removeWhere((person) => person.name.isEmpty);
}

bool _showContinue = false;
String _errorMessage = '';

class _AddPlayersState extends State<AddPlayers> {
  @override
  void initState() {
    textEditorControllers.clear();
    players.clear();
    setState(() {
      textEditorControllers = {' ': new TextEditingController()};
      players = [Player(' ', _getFunColor())];
      playerCounter = 1;
      _showContinue = false;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _showContinueDelay() async {
      await Future.delayed(Duration(seconds: 5));
      _showContinue = false;
      setState(() {});
    }

    return Scaffold(
      backgroundColor: Color(0xff326c60),
      appBar: AppBar(
        title: Text('Add players'),
        backgroundColor: Color(0xff439080),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          AnimatedContainer(
            alignment: Alignment.center,
            duration: Duration(milliseconds: 200),
            height: _showContinue ? 80 : 0,
            child: FlatButton(
              onPressed: () async {
                _cleanupPlayers();
                var nav = await Navigator.of(context).pushNamed('/categories');
                if (nav == true || nav == null) {
                  textEditorControllers.clear();
                  players.clear();
                  setState(() {
                    textEditorControllers = {' ': new TextEditingController()};
                    players = [Player(' ', _getFunColor())];
                    playerCounter = 1;
                    _showContinue = false;
                  });
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Click to continue',
                    style: TextStyle(fontSize: 18, color: Colors.grey[200]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            decoration: BoxDecoration(
                color: Colors.black45.withOpacity(0.5),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12))),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              child: Container(
                height: MediaQuery.of(context).size.height,
                child: ListView(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    children: <Widget>[] +
                        players
                            .map((player) => Card(
                                color: player.playerColor,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Container(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 12),
                                      color: player.playerColor,
                                      child: Icon(
                                        Icons.person,
                                        size: 40,
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            0, 12, 12, 12),
                                        child: Container(
                                          width: 270,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                width: 2,
                                                color: HSVColor.fromColor(
                                                        player.playerColor)
                                                    .withSaturation(.8)
                                                    .toColor()
                                                    .withOpacity(0.4)),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(8)),
                                            color:
                                                Colors.black87.withOpacity(0.2),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: TextFormField(
                                              onEditingComplete: () {
                                                setState(() {});
                                              },
                                              onChanged: (text) {
                                                if (player == players.last) {
                                                  setState(() {
                                                    _addNewPlayer();
                                                  });
                                                }

                                                //If more than 2 editors are not empty, display continue message
                                                setState(() {
                                                  _showContinue =
                                                      textEditorControllers
                                                              .values
                                                              .toList()
                                                              .where((editor) =>
                                                                  editor.text
                                                                      .isNotEmpty)
                                                              .length >=
                                                          2;
                                                });
                                              },
                                              maxLength: 50,
                                              controller: textEditorControllers[
                                                  player.name],
                                              textAlign: TextAlign.center,
                                              textInputAction:
                                                  TextInputAction.next,
                                              decoration: InputDecoration(
                                                  enabledBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                        color: Colors.black
                                                            .withOpacity(0),
                                                        width: 2
                                                        //  when the TextFormField in unfocused
                                                        ),
                                                  ),
                                                  focusedBorder:
                                                      UnderlineInputBorder(
                                                          borderSide: BorderSide(
                                                              color: Colors.grey
                                                                  .withOpacity(
                                                                      0))
                                                          //  when the TextFormField in focused
                                                          ),
                                                  border:
                                                      UnderlineInputBorder(),
                                                  hintText:
                                                      'Click to enter a name',
                                                  contentPadding:
                                                      EdgeInsets.fromLTRB(
                                                          0, 2, 0, 0),
                                                  counter: Offstage(),
                                                  floatingLabelBehavior:
                                                      FloatingLabelBehavior
                                                          .always),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )))
                            .toList()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
