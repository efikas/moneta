import 'package:http/http.dart' as http;
import 'dart:convert' as convert;

import 'package:http/http.dart';

class Services {
  // final String baseUrl = 'https://app.moneta.ng/api/v1/';

  Map<String, String> setHeader(String token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      "Authorization": "Bearer " + token,
    };
  }

  Future<Map<String, dynamic>> apiPostRequests(
      String endPoint, Map<String, dynamic> credentials,
      {String baseUrl, String token}) async {
    try {
      Response response = await http.post("${baseUrl}transaction/$endPoint",
          headers: setHeader(token), body: credentials);

      // print('Response status: ${response.statusCode}');
      // print('Response body: ${response.body}');

      return convert.json.decode(response.body);
    } catch (e) {
      return _catchError(e);
    }
  }

  Future<Map<String, dynamic>> apiGetRequests(String endPoint,
      {String baseUrl, String token}) async {
    try {
      Response response = await http.get("${baseUrl}transaction/$endPoint",
          headers: setHeader(token));

      return convert.json.decode(response.body);
    } catch (e) {
      return _catchError(e);
    }
  }

  Future<Map<String, dynamic>> apiDeleteRequests(String endPoint,
      {String baseUrl, String token}) async {
    try {
      Response response = await http.delete("${baseUrl}transaction/$endPoint",
          headers: setHeader(token));
      return convert.json.decode(response.body);
    } catch (e) {
      return _catchError(e);
    }
  }

  Future<dynamic> apiDeleteRequestsWithFullResponse(String endPoint,
      {String baseUrl, String token}) async {
    try {
      return await http.delete("${baseUrl}transaction/$endPoint",
          headers: setHeader(token));
    } catch (e) {
      return _catchError(e);
    }
  }

  Future<Map<String, dynamic>> apiPatchRequests(String endPoint,
      {String baseUrl, String token}) async {
    try {
      final response = await http.patch("${baseUrl}transaction/$endPoint",
          headers: setHeader(token));
      return convert.json.decode(response.toString());
    } catch (e) {
      return _catchError(e);
    }
  }

  Future<Map<String, dynamic>> apiPutRequests(
      String endPoint, Map<String, dynamic> credentials,
      {String baseUrl, String token}) async {
    try {
      final response = await http.put("${baseUrl}transaction/$endPoint",
          headers: setHeader(token), body: credentials);
      return convert.json.decode(response.toString());
    } catch (e) {
      print(e);
      return _catchError(e);
    }
  }

  Future<Map<String, dynamic>> apiPatchRequestsWithCredentials(
      String endPoint, Map<String, dynamic> credentials,
      {String baseUrl, String token}) async {
    try {
      final response = await http.patch("${baseUrl}transaction/$endPoint",
          headers: setHeader(token), body: credentials);
      return convert.json.decode(response.toString());
    } catch (e) {
      return _catchError(e);
    }
  }

  _catchError(dynamic e) {
    print(e);
    if (e.response != null) {
      print(e.response.data);
      print(e.response.headers);
      print(e.response.request);

      return e.response.data;
    } else {
      print(e.request);
      print(e.message);

      return {};
    }
  }
}
