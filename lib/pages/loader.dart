import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Loader extends StatefulWidget {
  @override
  _LoaderState createState() => _LoaderState();
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
  //myFile.delete();

  return myFile;
}

Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

_updateActionsFile() async {
  final SharedPreferences prefs = await _prefs;
  String url = 'http://christoffellis.pythonanywhere.com/get-actions-version';
  Map<String, String> headers = {"Content-type": "application/json"};
  String jsonString = '{}';
  Response response = await post(
    url,
    headers: headers,
    body: json.encode(jsonString),
  );
  String body = response.body;
  print(
      'New Version: ${double.parse(body)} vs Current Version: ${prefs.getDouble('actionsVersion') ?? 0}');
  final file2 = await _localFile;
  if ((prefs.getDouble('actionsVersion') ?? 0) == 0) {
    String actions = await loadAsset();

    file2.writeAsStringSync('');

    await file2.writeAsStringSync(actions);
  }

  if (double.parse(body) > (prefs.getDouble('actionsVersion') ?? 0)) {
    url = 'http://christoffellis.pythonanywhere.com/get-all-lines';
    response = await post(url,
        headers: headers,
        body: json.encode(jsonString),
        encoding: Encoding.getByName("utf-8"));
    List bodyList = json.decode(response.body);
    print(bodyList);

    final file2 = await _localFile;
    file2.writeAsStringSync('');
    String contents = await file2.readAsString();
    for (String line in bodyList) {
      await file2.writeAsString(line, mode: FileMode.append);
      print(line);
    }
    //print(await file2.readAsString());
    prefs.setDouble('actionsVersion', double.parse(body));
  }
}

class _LoaderState extends State<Loader> {
  @override
  void initState() {
    _updateActionsFile().whenComplete(() {
      Navigator.pushNamed(context, '/home');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff326c60),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 150,
              height: 150,
              child: CircularProgressIndicator(
                backgroundColor: Color(0xff439080),
                valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(0.8)),
              ),
            ),
            SizedBox(
              height: 12,
            ),
            Text(
              'Updating your cards...',
              style: TextStyle(fontSize: 22),
            ),
            Text(
              'This will only take a moment...',
              style: TextStyle(color: Colors.black.withOpacity(0.5)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 50,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.black, width: 2))),
        child: Text(
          'Play Drank responsibly. All players must by law be of drinking age. Do not overindulge.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
