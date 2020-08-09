import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:http/http.dart';
import 'dart:convert';
import 'dart:math';

import 'package:drinkinggame/main.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

bool _playPress = false;
bool _sharePress = false;
bool _ratePress = false;
bool _cardsPress = false;

List<dynamic> _notificationList = [];

class _HomeState extends State<Home> {
  @override
  void initState() {
    _loadNotifications();

    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xff3ACCC9),
    ));

    super.initState();
  }

  _loadNotifications() async {
    String url = 'http://christoffellis.pythonanywhere.com/get-notifications';

    Response response = await get(url);
    setState(() {
      _notificationList = json.decode(response.body);
    });
    print(_notificationList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFAB94),
      body: WillPopScope(
        child: SingleChildScrollView(
            child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: <Widget>[
              Center(
                child: Text(
                  'Drank',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 60),
                ),
              ),
              onBottom(AnimatedWave(
                height: 70,
                speed: 1,
                yOffset: MediaQuery.of(context).size.height * 40 ~/ 100,
                color: Color(0xff2eeff2),
              )),
              onBottom(AnimatedWave(
                height: 70,
                speed: 0.8,
                yOffset: MediaQuery.of(context).size.height * 40 ~/ 100,
                color: Color(0xff3ACCC9).withOpacity(0.8),
              )),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Stack(overflow: Overflow.visible, children: <Widget>[
                      Positioned(
                        child: Container(
                          height: MediaQuery.of(context).size.height * .2,
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
                          height: MediaQuery.of(context).size.height * .2,
                          width: MediaQuery.of(context).size.width * .6,
                          child: FlatButton(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(48)),
                            child: Text(
                              'Play',
                              style: TextStyle(fontSize: 30),
                            ),
                            onPressed: () {
                              setState(() {
                                _playPress = !_playPress;
                              });

                              Future.delayed(Duration(milliseconds: 150))
                                  .whenComplete(() {
                                Navigator.pushNamed(context, '/addplayers');
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
                      )
                    ]),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * .4,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Stack(overflow: Overflow.visible, children: <Widget>[
                          Positioned(
                            child: Container(
                              height: 80,
                              width: 88,
                              decoration: BoxDecoration(
                                  color: Color(0xffE7E7E7),
                                  borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: Duration(milliseconds: 150),
                            top: _sharePress ? 0 : -10,
                            child: Container(
                              height: 80,
                              width: 88,
                              child: FlatButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                                child: Text(
                                  'Share',
                                  style: TextStyle(fontSize: 20),
                                  textAlign: TextAlign.center,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _sharePress = !_sharePress;
                                  });

                                  Future.delayed(Duration(milliseconds: 150))
                                      .whenComplete(() {
                                    Share.share(
                                        'Hey! Check out this drinking game I\'ve wanted to play! It\'s called Drank.\n\nAvailable on the Play Store: www.blahblahblah.com');
                                    setState(() {
                                      _sharePress = !_sharePress;
                                    });
                                  });
                                },
                              ),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24)),
                            ),
                          )
                        ]),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * .02,
                        ),
                        Stack(overflow: Overflow.visible, children: <Widget>[
                          Positioned(
                            child: Container(
                              height: 80,
                              width: 88,
                              decoration: BoxDecoration(
                                  color: Color(0xffE7E7E7),
                                  borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: Duration(milliseconds: 150),
                            top: _ratePress ? 0 : -10,
                            child: Container(
                              height: 80,
                              width: 88,
                              child: FlatButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                                child: Text(
                                  'Rate Us',
                                  style: TextStyle(fontSize: 20),
                                  textAlign: TextAlign.center,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _ratePress = !_ratePress;
                                  });

                                  Future.delayed(Duration(milliseconds: 150))
                                      .whenComplete(() {
                                    if (Platform.isAndroid) {
                                    } else if (Platform
                                        .isIOS) {} //todo: populate
                                    setState(() {
                                      _ratePress = !_ratePress;
                                    });
                                  });
                                },
                              ),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24)),
                            ),
                          )
                        ]),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * .02,
                        ),
                        Stack(overflow: Overflow.visible, children: <Widget>[
                          Positioned(
                            child: Container(
                              height: 80,
                              width: 88,
                              decoration: BoxDecoration(
                                  color: Color(0xffE7E7E7),
                                  borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: Duration(milliseconds: 150),
                            top: _cardsPress ? 0 : -10,
                            child: Container(
                              height: 80,
                              width: 88,
                              child: FlatButton(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24)),
                                child: Text(
                                  'Your Cards',
                                  style: TextStyle(fontSize: 20),
                                  textAlign: TextAlign.center,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _cardsPress = !_cardsPress;
                                  });

                                  Future.delayed(Duration(milliseconds: 150))
                                      .whenComplete(() {
                                    Navigator.pushNamed(context, '/ownentries');
                                    setState(() {
                                      _cardsPress = !_cardsPress;
                                    });
                                  });
                                },
                              ),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24)),
                            ),
                          )
                        ]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}
