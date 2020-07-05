import 'package:drinkinggame/pages/buy_packs.dart';
import 'package:drinkinggame/pages/loader.dart';
import 'package:drinkinggame/pages/add_players.dart';
import 'package:drinkinggame/pages/game.dart';
import 'package:drinkinggame/pages/categories_page.dart';
import 'package:drinkinggame/pages/own_entries_page.dart';
import 'package:flutter/material.dart';
import 'pages/home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/RS.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => Loader(),
      '/home': (context) => Home(),
      '/addplayers': (context) => AddPlayers(),
      '/categories': (context) => Choose_Categories(),
      '/game': (context) => Game(),
      '/ownentries': (context) => OwnEntries(),
      '/buypacks': (context) => BuyPacks(),
    },
    theme: ThemeData(
        primaryColor: Color(0xff439080),
        fontFamily:
            GoogleFonts.robotoSlab(fontWeight: FontWeight.w800).fontFamily),
  ));
}
