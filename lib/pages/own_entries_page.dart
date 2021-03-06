import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart';
import 'dart:convert';

class OwnEntries extends StatefulWidget {
  @override
  _OwnEntriesState createState() => _OwnEntriesState();
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  File myFile;
  print('ans' + (await File('$path/own.txt').exists()).toString());
  if (!(await File('$path/own.txt').exists())) {
    var myFile = new File('$path/own.txt');
    print(myFile.create());
    var temp = await rootBundle.loadString('assets/own.txt');

    myFile.writeAsString(temp);
    print('wrote ' + temp);
  }
  myFile = File('$path/own.txt');
  //myFile.delete();

  return myFile;
}

int getFreshMapID() {
  var keyList = editors.keys.toList();
  keyList.sort();
  return (keyList.last + 1);
}

List<String> oldLines = [];

loadEntries() async {
  try {
    final file2 = await _localFile;

    // Read the file.
    String contents = await file2.readAsString();
    lines = contents.split('\n');
    oldLines = contents.split('\n');

    for (int i = 0; i <= lines.length - 1; i++) {
      editors[i] = new TextEditingController();
      editors[i].text = lines[i];
    }
    if (editors[editors.keys.last].text.length > 0) {
      var newID = getFreshMapID();
      editors[newID] = new TextEditingController();
      editors[newID].text = '';
    }
  } catch (e) {
    print(e);
  }
}

Future<String> loadAsset() async {
  return await rootBundle.loadString('assets/own.txt');
}

List<String> lines = [];
Map editors = {};

_uploadNewEntries() async {
  String url = 'http://christoffellis.pythonanywhere.com/upload-lines';
  Map<String, String> headers = {"Content-type": "application/json"};

  String newLines = '';
  List<String> linesNow = [];
  for (TextEditingController editor in editors.values) {
    linesNow.add(editor.text);
  }

  for (String line in linesNow) {
    if (!(oldLines.contains(line)) && line.length > 1) {
      newLines += '{"category":"usermade", "text":"$line"},';
    }
  }

  if (newLines.length > 0) {
    newLines = newLines.substring(0, newLines.length - 1);
    String jsonString = '{"admin": "false", "lines": [$newLines]}';
    print(jsonString);
    Response response = await post(
      url,
      headers: headers,
      body: json.encode(jsonString),
    );
    String body = response.body;
    print(body);
  }
}

saveEntries() async {
  final file2 = await _localFile;
  file2.writeAsStringSync('');
  String bigString = '';
  for (TextEditingController cont in editors.values) {
    if (cont.text.length > 0) {
      bigString += cont.text + '\n';
    }
  }
  await file2.writeAsString(bigString.substring(0, bigString.length - 1));
  print(await file2.readAsString());
}

removeIndex(int index) {
  editors.remove(index);
}

class _OwnEntriesState extends State<OwnEntries> {
  @override
  void initState() {
    loadEntries().whenComplete(() {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _uploadNewEntries();
    saveEntries();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff224840),
      appBar: AppBar(
        backgroundColor: Color(0xff439080),
        title: Text('Tap to edit your entries'),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey[900],
                      offset: Offset(0, 4),
                      blurRadius: 8)
                ],
                color: Color(0xff326c60),
              ),
              height: 450,
              child: RefreshIndicator(
                onRefresh: () async {
                  //await loadEntries();
                  setState(() {});
                },
                child: ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    children: editors.entries
                        .map((entry) => Dismissible(
                              background: Container(
                                color: Colors.redAccent,
                              ),
                              key: Key(entry.key.toString()),
                              onDismissed: (_) => removeIndex(entry.key),
                              child: Container(
                                decoration: BoxDecoration(
                                    color: Color(0xff82b5ab),
                                    border: Border(
                                        bottom: BorderSide(
                                      color: Color(0xff224840),
                                      width: 2,
                                    ))),
                                padding: EdgeInsets.all(8),
                                child: TextFormField(
                                  controller: editors[entry.key],
                                  maxLines: 3,
                                  minLines: 1,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    disabledBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.only(
                                        left: 15,
                                        bottom: 11,
                                        top: 11,
                                        right: 15),
                                    hintText: 'Tap to enter text',
                                  ),
                                ),
                              ),
                            ))
                        .toList()),
              ),
            ),
            Container(
                child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'To address one of the players in a card, use the tags @name1 and @name2. Any names higher than 2 will currently not work',
                style: TextStyle(
                  color: Colors.grey[200],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xffabdc41),
        tooltip: 'Click to add new cards',
        child: Icon(Icons.add),
        onPressed: () {
          editors[getFreshMapID()] = new TextEditingController();
          setState(() {});
        },
      ),
    );
  }
}
