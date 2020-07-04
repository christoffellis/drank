import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

// ignore: camel_case_types
class category {
  String className;
  String classId;
  String storeId;
  String description;
  IconData classIcon;
  Color classColor;
  bool active;
  bool bought;
  bool enabled;
  int minAdRewardCount;
  int currentAdRewardCount;

  category(String name, String id, IconData icon, Color color,
      {String desc,
      bool active,
      bool bought,
      String storeId,
      enabled,
      int minAdCount,
      int currAdCount}) {
    this.className = name;
    this.classId = id;
    this.classIcon = icon;
    this.classColor = color;
    if (active != null) {
      this.active = active;
    } else {
      this.active = true;
    }

    if (desc != null) {
      this.description = desc;
    } else {
      this.description = '';
    }

    if (bought != null) {
      this.bought = bought;
    } else {
      this.bought = true;
    }

    if (storeId != null) {
      this.storeId = storeId;
    } else {
      this.storeId = '';
    }

    if (enabled != null) {
      this.enabled = enabled;
    } else {
      this.enabled = true;
    }

    if (minAdCount != null) {
      this.minAdRewardCount = minAdCount;
    } else {
      this.minAdRewardCount = 1;
    }

    if (currAdCount != null) {
      this.currentAdRewardCount = currAdCount;
    } else {
      this.currentAdRewardCount = 0;
    }
  }

  rewardForAd() async {
    final SharedPreferences prefs = await _prefs;

    this.currentAdRewardCount += 1;
    prefs.setInt('${this.classId}.adRewardCount', this.currentAdRewardCount);
  }

  adWatchesNeeded() {
    return (this.minAdRewardCount - this.currentAdRewardCount);
  }

  checkIfReward() {
    if (!this.bought) {
      this.currentAdRewardCount -= this.minAdRewardCount;
    }
  }

  bool activeInGame() {
    return ((this.active && this.enabled && this.bought) ||
        (this.active &&
            this.enabled &&
            this.currentAdRewardCount >= this.minAdRewardCount));
  }
}
