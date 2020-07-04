import 'package:drinkinggame/pages/buy_packs.dart';
import 'package:drinkinggame/pages/loader.dart';
import 'package:drinkinggame/pages/make_donation.dart';
import 'package:drinkinggame/pages/add_players.dart';
import 'package:drinkinggame/pages/donations_names.dart';
import 'package:drinkinggame/pages/game.dart';
import 'package:drinkinggame/pages/categories_page.dart';
import 'package:drinkinggame/pages/own_entries_page.dart';
import 'package:flutter/material.dart';
import 'pages/home.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: '/',
    routes: {
      '/': (context) => Loader(),
      '/home': (context) => Home(),
      '/addplayers': (context) => AddPlayers(),
      '/categories': (context) => Choose_Categories(),
      '/game': (context) => Game(),
      '/ownentries': (context) => OwnEntries(),
      '/donations': (context) => Donations(),
      '/makedonation': (context) => MakeDonation(),
      '/buypacks': (context) => BuyPacks(),
    },
    theme: ThemeData(
        primaryColor: Color(0xff439080),
        fontFamily:
            GoogleFonts.robotoSlab(fontWeight: FontWeight.w800).fontFamily),
  ));
}
