
import "dart:convert";

import "package:http/http.dart" as http;

http.Client _client = http.Client();

const String _currentTag = "0.9.1";

Future<String?> updateAvailable() async {
  try {
    var res = await _client.get(Uri.parse("https://api.github.com/repos/tareksander/StoryReader/releases"), headers: {
      "Accept": "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
    });
    if (res.statusCode != 200) {
      return null;
    }
    String newest = (json.decode(res.body) as List<dynamic>)[0]["tag_name"] as String;
    if (newest != _currentTag) {
      return newest;
    }
    return null;
  } catch (e) {
    return null;
  }
}

