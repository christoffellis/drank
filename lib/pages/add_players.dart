import 'dart:async';
import 'dart:developer';
import 'dart:math';
import 'package:flutter/cupertino.dart';

import 'package:drinkinggame/classes/players.dart';
import 'package:flutter/material.dart';
import 'package:drinkinggame/main.dart';

class AddPlayers extends StatefulWidget {
  @override
  _AddPlayersState createState() => _AddPlayersState();
}

bool _continuePress = false;

Map textEditorControllers = {' ': new TextEditingController()};
List<Player> players = [Player(' ', Colors.white)];
int playerCounter = 1;

_addNewPlayer() {
  players.add(Player('Player $playerCounter', Colors.white));
  textEditorControllers['Player $playerCounter'] = new TextEditingController();

  playerCounter++;
}

_removePlayer(Player person) {
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
      players = [Player(' ', Colors.white)];
      playerCounter = 1;
      _showContinue = false;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(
            color: Colors.white, //change your color here
          ),
        ),
        backgroundColor: Color(0xffFFAB94),
        body: Container(
          height: MediaQuery.of(context).size.height,
          child: Stack(children: <Widget>[
            Center(
              child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                          SizedBox(height: 10),
                          Stack(
                            overflow: Overflow.visible,
                            children: <Widget>[
                              Positioned(
                                child: Container(
                                  height:
                                      MediaQuery.of(context).size.height * .15,
                                  width: MediaQuery.of(context).size.width * .5,
                                  decoration: BoxDecoration(
                                      color: Color(0xffE7E7E7),
                                      borderRadius: BorderRadius.circular(48)),
                                ),
                              ),
                              AnimatedPositioned(
                                duration: Duration(milliseconds: 150),
                                top: _continuePress || !_showContinue ? 0 : -10,
                                child: Container(
                                  height:
                                      MediaQuery.of(context).size.height * .15,
                                  width: MediaQuery.of(context).size.width * .5,
                                  child: FlatButton(
                                    disabledColor: Color(0xffE7E7E7),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(48)),
                                    child: Text(
                                      'Continue',
                                      style: TextStyle(fontSize: 30),
                                    ),
                                    onPressed: _showContinue
                                        ? () {
                                            setState(() {
                                              _continuePress = !_continuePress;
                                            });

                                            Future.delayed(
                                                    Duration(milliseconds: 150))
                                                .whenComplete(() {
                                              Navigator.pushNamed(
                                                  context, '/categories');
                                              setState(() {
                                                _continuePress =
                                                    !_continuePress;
                                              });
                                            });
                                          }
                                        : null,
                                  ),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(48)),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          )
                        ] +
                        players
                            .map((player) => Column(
                                  children: <Widget>[
                                    Container(
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                                color: Color(0xffE7E7E7),
                                                offset: Offset(0, 8))
                                          ]),
                                      width: MediaQuery.of(context).size.width *
                                          0.8,
                                      child: TextFormField(
                                        cursorColor: Colors.black38,
                                        maxLength: 50,
                                        onEditingComplete: () {
                                          FocusScope.of(context).nextFocus();
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
                                                textEditorControllers.values
                                                        .toList()
                                                        .where((editor) =>
                                                            editor.text
                                                                .isNotEmpty)
                                                        .length >=
                                                    2;
                                          });
                                        },
                                        controller:
                                            textEditorControllers[player.name],
                                        textCapitalization:
                                            TextCapitalization.words,
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 24),
                                        textAlign: TextAlign.center,
                                        textAlignVertical:
                                            TextAlignVertical.center,
                                        decoration: InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 12),
                                          hintText: 'Enter player name...',
                                          counterText: '',
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                    player == players.last
                                        ? Container(
                                            height: 20,
                                          )
                                        : Container(
                                            height: 20,
                                            width: 8,
                                            color: Color(0xffE7E7E7),
                                          )
                                  ],
                                ))
                            .toList() +
                        [
                          SizedBox(
                            height: 80,
                          )
                        ]),
              ),
            ),
            onBottom(AnimatedWave(
              height: 30,
              speed: 1,
              yOffset: 0, //MediaQuery.of(context).size.height * 10 ~/ 100,
              color: Color(0xff2eeff2),
            )),
            onBottom(AnimatedWave(
              height: 30,
              speed: 0.8,
              yOffset: 0, //MediaQuery.of(context).size.height * 10 ~/ 100,
              color: Color(0xff3ACCC9).withOpacity(0.8),
            )),
          ]),
        ),
      ),
    );
  }
}
