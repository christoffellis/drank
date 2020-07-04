import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:drinkinggame/classes/donation_obj.dart';

class Donations extends StatefulWidget {
  @override
  _DonationsState createState() => _DonationsState();
}

Future<String> loadAsset() async {
  return await rootBundle.loadString('assets/donations.txt');
}

List<String> lines = [];
List<donation> donors = [];

loadItems() async {
  lines.clear();
  donors.clear();

  String file = await loadAsset();
  lines = file.split('\n');
  for (String line in lines) {
    donors.add(donation(line.split('#')[0], line.split('#')[1],
        double.parse(line.split('#')[2])));
  }

  donors.sort((a, b) => b.value.compareTo(a.value));
}

class _DonationsState extends State<Donations> {
  @override
  void initState() {
    loadItems().whenComplete(() {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xff326c60),
        appBar: AppBar(
          title: Text('Donations'),
          centerTitle: true,
          backgroundColor: Color(0xff439080),
        ),
        body: ListView(
          children: [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: (Text(
                    'Drank is a student made project. To buy me a cup of coffee and help improve Drank, consider donating! Donations are still a work in progress. Thank you for being patient',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[300], fontSize: 18),
                  )),
                ),
                Container(
                  width: 100,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 130, vertical: 0),
                    child: RaisedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/makedonation');
                      },
                      child: Text('Donate'),
                      color: Colors.amberAccent,
                    ),
                  ),
                )
              ] +
              donors
                  .map((donor) => Padding(
                        padding: EdgeInsets.fromLTRB(8, 4, 8, 0),
                        child: Card(
                            child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            children: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  Text(donor.donor),
                                  Text('\$${donor.value.toStringAsFixed(2)}'),
                                ],
                              ),
                              Container(
                                child: Text(
                                  donor.dare,
                                  style: TextStyle(color: Colors.grey[700]),
                                  textAlign: TextAlign.justify,
                                ),
                              )
                            ],
                          ),
                        )),
                      ))
                  .toList(),
        ));
  }
}
