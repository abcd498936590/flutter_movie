import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:movie/entity/video.dart';
import 'package:movie/utils/shared_preferences.dart';

class Storage {
  static String userInfo = "user_info";
  static String videoHistory = "video_history";
  static String adState = 'ad_state';
  static String account = "account";
  static String signing = "signing";
  static String sourceUrl = "source_url";

  static String getSourceUrl() {
    return SpUtil().getString(sourceUrl) ?? "";
  }

  static Future<bool> setSourceUrl(String newUrl) async {
    return SpUtil().setString(sourceUrl, newUrl);
  }

  static bool getSigningResult() {
    return SpUtil().getBool(signing) ?? false;
  }

  static Future<bool> setSigningResult(bool newValue) async {
    return SpUtil().setBool(signing, newValue);
  }

  static List<String> getStoreAccount() {
    return SpUtil().getStringList(account);
  }

  static Future<bool> setStoreAccount(String newAccount) async {
    List<String> accountList = Storage.getStoreAccount();
    accountList.removeWhere((it) => it == newAccount);
    accountList.add(newAccount);
    return SpUtil().setStringList(account, accountList);
  }

  static Future<bool> setAdState(bool newState) {
    return SpUtil().setBool(adState, newState);
  }

  static Future<bool> getAdState() async {
    return SpUtil().getBool(adState) ?? false;
  }

  static Future<bool> clearUserInfo() {
    return SpUtil().remove(userInfo);
  }

  static Future<bool> setVideoHistory(Object source) {
    List<String> videoItemList = [];
    switch (source) {
      // 单个
      case VideoSourceListItem s:
        List<VideoSourceListItem> curHistoryList =
            Storage.getVideoHistoryList();
        curHistoryList.removeWhere(
          (el) => el.vodId == s.vodId && el.vodName == s.vodName,
        );
        curHistoryList = curHistoryList.reversed.toList();
        curHistoryList.add(s);
        videoItemList = curHistoryList
            .map((it) => jsonEncode(it.toJson()))
            .toList();
        break;
      // 集合
      case List<VideoSourceListItem> l:
        videoItemList = l.map((it) => jsonEncode(it.toJson())).toList();
        break;
      default:
        if (kDebugMode) {
          print("未知类型");
        }
    }

    return SpUtil().setStringList(videoHistory, videoItemList);
  }

  static List<VideoSourceListItem> getVideoHistoryList() {
    return SpUtil().getStringList(videoHistory).reversed.map((it) {
      return VideoSourceListItem.fromJson(jsonDecode(it));
    }).toList();
  }
}
