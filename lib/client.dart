
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';


http.Client httpClient() {
  return IOClient(HttpClient()
    ..userAgent = "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0");
}






