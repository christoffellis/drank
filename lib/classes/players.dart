import 'package:flutter/material.dart';
import 'dart:math';

class Player {
  String name;
  Color playerColor;
  int playCount;

  getRelativeplayCount() {
    var rand = Random();
    int variability = rand.nextInt(2);
    return this.playCount + variability;
  }

  Player(String name, Color playerColor) {
    this.name = name;
    this.playerColor = playerColor;
    this.playCount = 0;
  }
}
