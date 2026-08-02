import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/export.dart' show
    AESEngine, CTRStreamCipher, KeyParameter, ParametersWithIV;

import 'protocomm_proto.dart';

/// Thrown when the security1 handshake fails (bad status from the device or a
/// proof-of-possession mismatch).
class Security1Exception implements Exception {
  const Security1Exception(this.message);

  final String message;

  @override
  String toString() => 'Security1Exception: $message';
}

/// One continuous AES-CTR keystream, as used by protocomm security1: both
/// sides advance the same stream, alternating encrypt/decrypt in lock-step
/// with the request/response order.
class Security1Cipher {
  Security1Cipher(Uint8List key, Uint8List iv)
    : _cipher = CTRStreamCipher(AESEngine())
        ..init(true, ParametersWithIV(KeyParameter(key), iv));

  final CTRStreamCipher _cipher;

  Uint8List apply(Uint8List data) => _cipher.process(data);
}

/// Computes the security1 session key: X25519 shared secret, XOR-ed with
/// SHA-256 of the proof-of-possession when a PoP is set.
Uint8List security1SessionKey({
  required List<int> sharedSecret,
  required String pop,
}) {
  final key = Uint8List.fromList(sharedSecret);
  if (pop.isNotEmpty) {
    final popHash = sha256.convert(utf8.encode(pop)).bytes;
    for (var i = 0; i < key.length; i++) {
      key[i] ^= popHash[i];
    }
  }
  return key;
}

// Protobuf schema constants (ESP-IDF session.proto / sec1.proto).
class Sec1Fields {
  // SessionData
  static const secVer = 2; // SecSchemeVersion, varint
  static const sec1Payload = 11;
  static const secScheme1 = 1;

  // Sec1Payload
  static const msgType = 1;
  static const sc0 = 20;
  static const sr0 = 21;
  static const sc1 = 22;
  static const sr1 = 23;
  static const msgSessionCommand0 = 0;
  static const msgSessionResponse0 = 1;
  static const msgSessionCommand1 = 2;
  static const msgSessionResponse1 = 3;

  // SessionCmd0 / SessionResp0
  static const clientPubKey = 1;
  static const respStatus = 1;
  static const devicePubKey = 2;
  static const deviceRandom = 3;

  // SessionCmd1 / SessionResp1
  static const clientVerifyData = 2;
  static const deviceVerifyData = 3;

  // constants.proto Status
  static const statusSuccess = 0;
}

Uint8List _wrapSec1(ProtoWriter payload) {
  final session = ProtoWriter()
    ..writeVarintField(Sec1Fields.secVer, Sec1Fields.secScheme1)
    ..writeMessageField(Sec1Fields.sec1Payload, payload);
  return session.toBytes();
}

/// Client side of the protocomm security1 handshake.
///
/// Usage: send [buildSessionCmd0] to the `prov-session` endpoint, feed the
/// response to [handleSessionResp0] and send the returned SessionCmd1, then
/// feed that response to [handleSessionResp1]. After that [encrypt]/[decrypt]
/// protect all endpoint payloads.
class Security1Client {
  Security1Client(this.pop);

  final String pop;
  final X25519 _x25519 = X25519();

  late SimpleKeyPair _keyPair;
  late Uint8List _clientPubKey;
  late Uint8List _devicePubKey;
  Security1Cipher? _cipher;

  bool get isEstablished => _cipher != null;

  Future<Uint8List> buildSessionCmd0() async {
    _keyPair = await _x25519.newKeyPair();
    final publicKey = await _keyPair.extractPublicKey();
    _clientPubKey = Uint8List.fromList(publicKey.bytes);

    final cmd0 = ProtoWriter()
      ..writeBytesField(Sec1Fields.clientPubKey, _clientPubKey);
    final payload = ProtoWriter()
      ..writeMessageField(Sec1Fields.sc0, cmd0);
    return _wrapSec1(payload);
  }

  /// Consumes SessionResp0 and returns the SessionCmd1 bytes to send.
  Future<Uint8List> handleSessionResp0(Uint8List response) async {
    final resp0 = _unwrap(response, Sec1Fields.sr0, 'SessionResp0');
    if (resp0.varint(Sec1Fields.respStatus) != Sec1Fields.statusSuccess) {
      throw Security1Exception(
        'Handshake rejected (status ${resp0.varint(Sec1Fields.respStatus)})',
      );
    }
    final devicePubKey = resp0.bytes(Sec1Fields.devicePubKey);
    final deviceRandom = resp0.bytes(Sec1Fields.deviceRandom);
    if (devicePubKey == null || deviceRandom == null) {
      throw const Security1Exception('SessionResp0 missing key material');
    }
    _devicePubKey = devicePubKey;

    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: _keyPair,
      remotePublicKey: SimplePublicKey(
        devicePubKey,
        type: KeyPairType.x25519,
      ),
    );
    final key = security1SessionKey(
      sharedSecret: await sharedSecret.extractBytes(),
      pop: pop,
    );
    final cipher = Security1Cipher(key, deviceRandom);
    final clientVerify = cipher.apply(_devicePubKey);
    _cipher = cipher;

    final cmd1 = ProtoWriter()
      ..writeBytesField(Sec1Fields.clientVerifyData, clientVerify);
    final payload = ProtoWriter()
      ..writeVarintField(Sec1Fields.msgType, Sec1Fields.msgSessionCommand1)
      ..writeMessageField(Sec1Fields.sc1, cmd1);
    return _wrapSec1(payload);
  }

  /// Verifies SessionResp1; throws [Security1Exception] on a PoP mismatch.
  void handleSessionResp1(Uint8List response) {
    final resp1 = _unwrap(response, Sec1Fields.sr1, 'SessionResp1');
    if (resp1.varint(Sec1Fields.respStatus) != Sec1Fields.statusSuccess) {
      throw const Security1Exception(
        'Device rejected verification — wrong proof-of-possession?',
      );
    }
    final verifyData = resp1.bytes(Sec1Fields.deviceVerifyData);
    if (verifyData == null) {
      throw const Security1Exception('SessionResp1 missing verify data');
    }
    final decrypted = decrypt(verifyData);
    if (!_constantTimeEquals(decrypted, _clientPubKey)) {
      throw const Security1Exception(
        'Device verification mismatch — wrong proof-of-possession?',
      );
    }
  }

  Uint8List encrypt(Uint8List data) => _requireCipher().apply(data);

  Uint8List decrypt(Uint8List data) => _requireCipher().apply(data);

  Security1Cipher _requireCipher() {
    final cipher = _cipher;
    if (cipher == null) {
      throw const Security1Exception('Session not established');
    }
    return cipher;
  }

  ProtoMessage _unwrap(Uint8List response, int field, String name) {
    final ProtoMessage session;
    try {
      session = ProtoMessage.parse(response);
    } on FormatException catch (e) {
      throw Security1Exception('Malformed $name: ${e.message}');
    }
    final message = session.message(Sec1Fields.sec1Payload)?.message(field);
    if (message == null) {
      throw Security1Exception('Response is not a $name');
    }
    return message;
  }

  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
