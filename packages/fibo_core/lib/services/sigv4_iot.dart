import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'aws_credentials.dart';

/// Builds a SigV4-presigned `wss://` URL for connecting to AWS IoT Core over
/// MQTT-over-WebSocket (service `iotdevicegateway`). The session token is
/// appended after signing, per the AWS WebSocket signing spec.
String presignIotWssUrl({
  required AwsCredentials creds,
  required String region,
  required String endpoint,
  DateTime? now,
}) {
  const service = 'iotdevicegateway';
  const method = 'GET';
  const canonicalUri = '/mqtt';
  const emptyPayloadHash =
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855';

  final t = (now ?? DateTime.now()).toUtc();
  String p2(int n) => n.toString().padLeft(2, '0');
  final amzDate =
      '${t.year}${p2(t.month)}${p2(t.day)}T${p2(t.hour)}${p2(t.minute)}${p2(t.second)}Z';
  final dateStamp = '${t.year}${p2(t.month)}${p2(t.day)}';
  final scope = '$dateStamp/$region/$service/aws4_request';

  // Canonical query string (signed; security token added later).
  final params = <String, String>{
    'X-Amz-Algorithm': 'AWS4-HMAC-SHA256',
    'X-Amz-Credential': '${creds.accessKeyId}/$scope',
    'X-Amz-Date': amzDate,
    'X-Amz-SignedHeaders': 'host',
  };
  final sortedKeys = params.keys.toList()..sort();
  final canonicalQuery =
      sortedKeys.map((k) => '${_enc(k)}=${_enc(params[k]!)}').join('&');

  final canonicalHeaders = 'host:$endpoint\n';
  final canonicalRequest = [
    method,
    canonicalUri,
    canonicalQuery,
    canonicalHeaders,
    'host',
    emptyPayloadHash,
  ].join('\n');

  final stringToSign = [
    'AWS4-HMAC-SHA256',
    amzDate,
    scope,
    _hex(sha256.convert(utf8.encode(canonicalRequest)).bytes),
  ].join('\n');

  final kDate = _hmac(utf8.encode('AWS4${creds.secretKey}'), dateStamp);
  final kRegion = _hmac(kDate, region);
  final kService = _hmac(kRegion, service);
  final kSigning = _hmac(kService, 'aws4_request');
  final signature = _hex(_hmac(kSigning, stringToSign));

  return 'wss://$endpoint$canonicalUri?$canonicalQuery'
      '&X-Amz-Signature=$signature'
      '&X-Amz-Security-Token=${_enc(creds.sessionToken)}';
}

List<int> _hmac(List<int> key, String data) =>
    Hmac(sha256, key).convert(utf8.encode(data)).bytes;

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

/// RFC 3986 encoding (AWS canonical): encode everything except unreserved.
String _enc(String input) {
  const unreserved =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~';
  final sb = StringBuffer();
  for (final byte in utf8.encode(input)) {
    final ch = String.fromCharCode(byte);
    if (unreserved.contains(ch)) {
      sb.write(ch);
    } else {
      sb.write('%${byte.toRadixString(16).toUpperCase().padLeft(2, '0')}');
    }
  }
  return sb.toString();
}
