import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:http/http.dart';
import 'dart:convert';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

_shader(bounds, color) {
  return LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      color.withOpacity(.6),
      HSVColor.fromColor(color).withSaturation(1).toColor().withOpacity(.4)
    ],
  ).createShader(bounds);
}

List<dynamic> _notificationList = [];

class _HomeState extends State<Home> {
  @override
  void initState() {
    _loadNotifications();
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
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text('Drank'),
          backgroundColor: Color(0xff326c60), //Color(0xff439080),
          elevation: 0,
        ),
        backgroundColor: Color(0xff326c60),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(25.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return _shader(bounds, Color(0xfffdaa88));
                      },
                      blendMode: BlendMode.colorBurn,
                      child: Container(
                        height: 100,
                        width: MediaQuery.of(context).size.width,
                        child: RaisedButton(
                          color: Color(0xfffdaa88),
                          elevation: 10,
                          onPressed: () {
                            Navigator.pushNamed(context, '/addplayers');
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text('Start',
                                  style: TextStyle(
                                    fontSize: 24,
                                  )),
                              Text('Click to setup a game of Drank')
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return _shader(bounds, Color(0xff88ddfd));
                      },
                      blendMode: BlendMode.colorBurn,
                      child: Container(
                        height: 100,
                        width: 0.8 * MediaQuery.of(context).size.width,
                        child: RaisedButton(
                          color: Color(0xff88ddfd),
                          elevation: 10,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text('Own Entries',
                                  style: TextStyle(
                                    fontSize: 24,
                                  )),
                              Text('Add your own cards to play Drank with')
                            ],
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/ownentries');
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return _shader(bounds, Color(0xfffde388));
                      },
                      blendMode: BlendMode.colorBurn,
                      child: Container(
                        height: 100,
                        width: 0.8 * MediaQuery.of(context).size.width,
                        child: RaisedButton(
                          color: Color(0xfffde388),
                          elevation: 10,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text('Share',
                                  style: TextStyle(
                                    fontSize: 24,
                                  )),
                              Text('Tell your friends about Drank')
                            ],
                          ),
                          onPressed: () {
                            //Navigator.pushNamed(context, '/donations');
                            Share.share(
                                'Check out this awesome drinking app Drank!\n\nGoogle Play Store: https://play.google.com/store/apps/details?id=com.christo.drinkinggame');
                            //todo: add apple link
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return _shader(bounds, Color(0xff88fdb1));
                      },
                      blendMode: BlendMode.colorBurn,
                      child: Container(
                        height: 100,
                        width: 0.8 * MediaQuery.of(context).size.width,
                        child: RaisedButton(
                          color: Color(0xff88fdb1),
                          elevation: 10,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text('Rate Us',
                                  style: TextStyle(
                                    fontSize: 24,
                                  )),
                              Text('If you enjoy Drank, rate us 5-stars')
                            ],
                          ),
                          onPressed: () {
                            if (Platform.isAndroid) {
                              launch(
                                  'https://play.google.com/store/apps/details?id=com.christo.drinkinggame');
                            } else if (Platform.isIOS) {
                              print('sss');
                              //todo: add apple link
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black.withOpacity(0.1),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: _notificationList
                            .map((notif) => Card(
                                  color: Colors.black.withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  margin: EdgeInsets.all(12),
                                  child: FlatButton(
                                      onPressed: notif['hasLink']
                                          ? () => launch(notif['link'])
                                          : {},
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 12),
                                      child: Column(
                                        children: <Widget>[
                                          Text(
                                            notif['date'],
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[300]),
                                          ),
                                          Text(
                                            notif['message'],
                                            style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.grey[300]),
                                          ),
                                        ],
                                      )),
                                ))
                            .toList(),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
