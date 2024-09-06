import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:chopper/chopper.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:story_reader/db.dart';
import 'package:story_reader/prefs.dart';
import 'package:story_reader/rich_text_tree.dart';
import 'package:story_reader/series_data.dart';
import 'package:async/async.dart';

part 'sh.chopper.dart';

@ChopperApi(baseUrl: "https://www.scribblehub.com/")
abstract class SHAPI extends ChopperService {
  Future<Response<List<SeriesData>>> simpleSearch(String name) async {
    var resp = await _base({"action": "wi_ajaxsearchmain", "strOne": name, "strType": "series"});
    if (!resp.isSuccessful) {
      return resp.copyWith();
    }
    List<SeriesData> resBody = [];
    var body = parseFragment(resp.bodyString);
    for (var a in body.children[0].children) {
      var segments = Uri.parse(a.firstChild!.attributes["href"]!).pathSegments;
      var id = segments[segments.length - 3];

      String thumbnailURL = a.firstChild!.firstChild!.attributes["src"]!;
      Uint8List? thumbnail;
      if (Preferences.useImages.value) {
        thumbnail = (await _shC.get(Uri.parse(thumbnailURL))).bodyBytes;
      }
      resBody.add(SeriesData(site: Site.scribbleHub, name: a.text.trim(), id: id, thumbnail: thumbnail));
    }
    return resp.copyWith(body: resBody);
  }

  @Post(path: "wp-admin/admin-ajax.php")
  @FormUrlEncoded()
  Future<Response> _base(@Body() Map<String, dynamic> fields);

  Future<Response<List<ChapterData>>> chapters(String id) async {
    var resp = await _base({"action": "wi_gettocchp", "strSID": id});
    if (!resp.isSuccessful) {
      return resp.copyWith();
    }
    var body = parseFragment(resp.bodyString);
    return resp.copyWith(
        body: body.children[0].children[0].children.map((e) {
      var segments = Uri.parse(e.children[0].attributes["href"]!).pathSegments;
      var id = segments[segments.length - 2];
      return ChapterData(id, e.text.trim());
    }).toList());
  }

  @Get(path: "read/{idSlug}/chapter/{id}/")
  Future<Response> _chapterContents(@Path("idSlug") String idSlug, @Path("id") String id);

  Future<Response<ChapterData>> chapterContents(SeriesData series, String id) async {
    var resp = await _chapterContents("${series.id}-${slugify(series.name)}", id);
    if (!resp.isSuccessful) {
      return resp.copyWith();
    }
    var body = parse(resp.bodyString);
    return resp.copyWith(
        body: ChapterData(
            id, body.getElementsByClassName("chapter-title").first.text, RichTextDocument.html(body.getElementById("chp_raw")!.nodes)));
  }

  @Get(path: "series/{id}/{slugged}/")
  Future<Response> _series(@Path("id") String id, @Path("slugged") String slugged);

  Future<Response<SeriesData>> series(String id, String name) async {
    var resp = await _series(id, slugify(name));
    if (!resp.isSuccessful) {
      return resp.copyWith();
    }
    var body = parse(resp.bodyString);
    var stats = body.getElementsByClassName("mb_stat");
    var cws = <CW>{};
    var cwElements = body.getElementsByClassName("ul_rate_expand");
    if (cwElements.isNotEmpty) {
      var cwElement = cwElements[0];
      if (cwElement.text.contains("Gore")) {
        cws.add(CW.gore);
      }
      if (cwElement.text.contains("Sexual")) {
        cws.add(CW.sexual);
      }
      if (cwElement.text.contains("Strong")) {
        cws.add(CW.language);
      }
    }
    Uint8List? thumbnail;
    if (Preferences.useImages.value) {
      thumbnail =
          (await _shC.get(Uri.parse(body.getElementsByClassName("fic_image").first.children.first.attributes["src"]!)))
              .bodyBytes;
    }
    return resp.copyWith(
        body: SeriesData(
            site: Site.scribbleHub,
            name: body.getElementsByClassName("fic_title")[0].text.trim(),
            description: body.getElementsByClassName("wi_fic_desc")[0].text.trim(),
            id: id,
            contentWarnings: cws,
            chapters: int.parse(stats.where((s) => s.text == "Chapters").first.parent!.nodes[1].text!),
            score: double.parse(body.getElementById("ratefic_user")!.children.last.children.first.text),
            views: postfixedParseInt(stats.where((s) => s.text == "Views").first.parent!.nodes[1].text!),
            favourites: int.parse(stats.where((s) => s.text == "Favorites").first.parent!.nodes[1].text!),
            follows: int.parse(stats.where((s) => s.text == "Readers").first.parent!.nodes[1].text!),
            ratings: int.parse(body.getElementsByClassName("rate_more")[0].text.split(" ")[0]),
            thumbnail: thumbnail));
  }

  static SHAPI create() => _$SHAPI(_shC);
}

final _shC = ChopperClient(interceptors: [RetryInterceptor()]);

int postfixedParseInt(String s) {
  s = s.trim();
  if (s.endsWith("k")) {
    return (double.parse(s.substring(0, s.length - 1)) * 1000).toInt();
  }
  if (s.endsWith("M")) {
    return (double.parse(s.substring(0, s.length - 1)) * 1000000).toInt();
  }
  return int.parse(s);
}

String slugify(String name) {
  // TODO What happens with multiple consecutive spaces? Unicode chars? Multiple consecutive -?
  var slugged = name.replaceAll(RegExp(r"[^a-zA-Z ]"), "").replaceAll(" ", "-").replaceAll(RegExp(r"-+"), "-").toLowerCase();
  //print(slugged);
  return slugged;
}

final class RetryInterceptor implements Interceptor {
  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) async {
    Response<BodyType>? res;
    var headers = Map.fromEntries(chain.request.headers.entries);
    // TODO use user agent if a site requires it
    //headers["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0";
    var req = chain.request.copyWith(headers: headers);
    for (int i = 0; i < 3; i++) {
      try {
        res = (await Future.value(chain.proceed(req)).timeout(Duration(seconds: 5 * (i + 1)), onTimeout: null))
            as Response<BodyType>?;
      } catch (e) {
        //print(e);
      }
      if (res != null) {
        if (res.body != null) {
          return res;
        } else {
          if (res.statusCode == 429) {
            await Future.delayed(Duration(seconds: 3 * (i + 1)));
          }
          //print(res.statusCode);
          //print(res.headers);
          //print(res.error);
        }
      }
      //print("Try ${i+1} failed");
    }
    if (res == null) {
      throw const HttpException("");
    }
    return res;
  }
}
