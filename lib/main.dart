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
import 'dart:math';
import 'package:simple_animations/simple_animations.dart';
import 'package:flutter/services.dart';

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
        primaryColor: Color(0xffFFAB94),
        fontFamily:
            GoogleFonts.robotoSlab(fontWeight: FontWeight.w800).fontFamily),
  ));
}

String adId = 'ca-app-pub-2227511639014188/7503484377';
String gameAdId = 'ca-app-pub-2227511639014188/6632780478';
String admobId = 'ca-app-pub-2227511639014188~2895716024';

Widget onBottom(Widget child) => Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: child,
      ),
    );

class AnimatedWave extends StatelessWidget {
  final double height;
  final double speed;
  final double offset;
  final int yOffset;
  final Color color;

  AnimatedWave(
      {this.height,
      this.speed,
      this.offset = 0.0,
      this.yOffset = 0,
      this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        height: height,
        width: constraints.biggest.width,
        child: ControlledAnimation(
            playback: Playback.LOOP,
            duration: Duration(milliseconds: (5000 / speed).round()),
            tween: Tween(begin: 0.0, end: 2 * pi),
            builder: (context, value) {
              return CustomPaint(
                foregroundPainter:
                    CurvePainter(value + offset, this.yOffset, this.color),
              );
            }),
      );
    });
  }
}

class CurvePainter extends CustomPainter {
  final double value;
  final int yOffset;
  final Color color;

  CurvePainter(this.value, this.yOffset, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final aqua = Paint()..color = this.color;
    final path = Path();

    final y1 = sin(value);
    final y2 = sin(value + pi / 2);
    final y3 = sin(value + pi);

    final startPointY = -this.yOffset + size.height * (0.5 + 0.4 * y1);
    final controlPointY = -this.yOffset + size.height * (0.5 + 0.4 * y2);
    final endPointY = -this.yOffset + size.height * (0.5 + 0.4 * y3);

    path.moveTo(size.width * 0, startPointY);
    path.quadraticBezierTo(
        size.width * 0.5, controlPointY, size.width, endPointY);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, aqua);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
