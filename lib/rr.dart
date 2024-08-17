
import 'dart:async';
import 'dart:typed_data';

import 'package:chopper/chopper.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart';
import 'package:story_reader/db.dart';
import 'package:story_reader/prefs.dart';
import 'package:story_reader/series_data.dart';
import 'package:story_reader/sh.dart';

part 'rr.chopper.dart';


const String baseURL = "https://www.royalroad.com/";

@ChopperApi(baseUrl: baseURL)
abstract class RRAPI extends ChopperService {
  
  Future<Response<List<SeriesData>>> simpleSearch(String name) async {
    var resp = await _simpleSearch(name);
    if (! resp.isSuccessful) {
      return resp.copyWith();
    }
    List<SeriesData> respBody = [];
    var body = parse(resp.bodyString);
    for (var f in body.querySelector(".fiction-list")!.querySelectorAll(".fiction-list-item")) {
      var title = f.querySelector(".fiction-title")!.children[0];
      var segments = Uri.parse(title.attributes["href"]!).pathSegments;
      var id = segments[segments.length-2];
      
      String thumbnailURL = f.getElementsByTagName("img").first.attributes["src"]!;
      respBody.add(SeriesData(site: Site.royalRoad, id: id, name: title.text.trim(), thumbnail: await _thumbnail(thumbnailURL)));
    }
    return resp.copyWith(body: respBody);
  }
  
  Future<Uint8List?> _thumbnail(String url) async {
    if (! Preferences.useImages.value) {
      return null;
    }
    if (url.startsWith("/")) {
      url = Uri.parse(baseURL).resolve(url).toString();
    }
    return (await _rrC.get(Uri.parse(url))).bodyBytes;
  }
  
  Future<Response<(SeriesData, List<ChapterData>)>> series(String id, String name) async {
    var resp = await _series(id, slugify(name));
    if (! resp.isSuccessful) {
      return resp.copyWith();
    }
    List<ChapterData> chapters = [];
    var body = parse(resp.bodyString);
    
    var stats = body.querySelector(".fiction-stats")!.querySelector(".stats-content")!;
    var statsRight = stats.children[1].children[0];
    var views = int.parse(_removeCommas(statsRight.children[1].text.trim()));
    var follows = int.parse(_removeCommas(statsRight.children[5].text.trim()));
    var favourites = int.parse(_removeCommas(statsRight.children[7].text.trim()));
    var ratings = int.parse(_removeCommas(statsRight.children[9].text.trim()));
    var score = double.parse(stats.children[0].children[0].children[1].children[0].attributes["data-content"]!.split(" ")[0]);
    
    
    var header = body.querySelector(".fic-header")!;
    var title = header.querySelector("h1")!;
    var description = body.querySelector(".description")!;
    
    Set<CW> cws = {};
    if (description.parent!.children.length >= 3) {
      var cwsText = description.previousElementSibling!.querySelector("ul")!.text.toLowerCase();
      if (cwsText.contains("sexual")) {
        cws.add(CW.sexual);
      }
      if (cwsText.contains("violence")) {
        cws.add(CW.gore);
      }
      if (cwsText.contains("profanity")) {
        cws.add(CW.language);
      }
      if (cwsText.contains("sensitive")) {
        cws.add(CW.mature);
      }
    }
    
    String thumbnailURL = header.querySelector(".thumbnail")!.attributes["src"]!;
    
    for (var c in body.getElementById("chapters")!.getElementsByTagName("tbody")[0].children) {
      var a = c.children[0].children[0];
      var segments = Uri.parse(a.attributes["href"]!).pathSegments;
      var id = segments[segments.length-2];
      chapters.add(ChapterData(id, a.text.trim()));
    }
    
    
    return resp.copyWith(body: (SeriesData(
        site: Site.royalRoad,
        id: id,
      name: title.text.trim(),
      description: description.text.trim(),
      chapters: chapters.length,
      views: views,
      follows: follows,
      favourites: favourites,
      ratings: ratings,
      score: score,
      contentWarnings: cws,
      thumbnail: await _thumbnail(thumbnailURL),
    ), chapters));
  }
  
  Future<Response<ChapterData>> chapterContents(SeriesData s, String id, String name) async {
    var resp = await _chapterContents(s.id, slugify(s.name), id, slugify(name));
    if (! resp.isSuccessful) {
      return resp.copyWith();
    }
    var body = parse(resp.bodyString);
    var excludedStyle = body.getElementsByTagName("style")[0].text.trim().split(RegExp(r"\s*{"))[0];
    var content = body.querySelector(".chapter-content")!;
    content.querySelector(excludedStyle)?.remove();
    
    var note = body.querySelector(".author-note");
    if (note != null) {
      var n = dom.Element.tag("div");
      var b = dom.Element.tag("div");
      n.classes.add("wi_authornotes");
      b.classes.add("wi_authornotes_body");
      b.children.addAll(note.children);
      n.children.add(b);
      content.children.insert(0, n);
    }
    
    return resp.copyWith(body: ChapterData(id, name, content.innerHtml));
  }
  
  
  @Get(path: "fictions/search")
  Future<Response> _simpleSearch(@Query() String title);
  
  @Get(path: "fiction/{id}/{slugged}")
  Future<Response> _series(@Path("id") String id, @Path("slugged") String slugged);
  
  @Get(path: "fiction/{sid}/{sslug}/chapter/{cid}/{cslug}")
  Future<Response> _chapterContents(@Path("sid") String seriesID, @Path("sslug") String seriesSlug, @Path("cid") String chapterID, @Path("cslug") String chapterSlug);
  
  static RRAPI create() => _$RRAPI(_rrC);
}

String _removeCommas(String s) {
  return s.replaceAll(",", "");
}

final _rrC = ChopperClient(interceptors: [RetryInterceptor()]);
