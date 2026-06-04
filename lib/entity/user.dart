class UserInfo {
  String? id;
  String? userName;
  String? nickName;
  String? description;
  int? followNum;
  int? badgeNum;

  UserInfo({
    required this.id,
    required this.userName,
    required this.nickName,
    required this.description,
    required this.followNum,
    required this.badgeNum,
  });

  String toJsonStr() {
    return """{
      "id": "$id",
      "userName": "$userName",
      "nickName": "$nickName",
      "description": "$description",
      "followNum": $followNum,
      "badgeNum": $badgeNum
    }
    """;
  }

  UserInfo.formJson(dynamic jsonMap) {
    id = jsonMap["id"];
    userName = jsonMap["userName"];
    nickName = jsonMap["nickName"];
    description = jsonMap["description"];
    followNum = jsonMap["followNum"];
    badgeNum = jsonMap["badgeNum"];
  }
}
