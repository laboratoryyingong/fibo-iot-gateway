import 'dart:typed_data';

/// Minimal protobuf wire-format encoder/decoder for the handful of protocomm
/// session messages (ESP-IDF `session.proto` / `sec1.proto`). Only varint and
/// length-delimited wire types are needed.
class ProtoWriter {
  final BytesBuilder _bytes = BytesBuilder();

  Uint8List toBytes() => _bytes.toBytes();

  void writeVarintField(int fieldNumber, int value) {
    _writeVarint((fieldNumber << 3) | 0);
    _writeVarint(value);
  }

  void writeBytesField(int fieldNumber, List<int> value) {
    _writeVarint((fieldNumber << 3) | 2);
    _writeVarint(value.length);
    _bytes.add(value);
  }

  void writeMessageField(int fieldNumber, ProtoWriter message) {
    writeBytesField(fieldNumber, message.toBytes());
  }

  void _writeVarint(int value) {
    var v = value;
    while (v >= 0x80) {
      _bytes.addByte((v & 0x7F) | 0x80);
      v >>= 7;
    }
    _bytes.addByte(v);
  }
}

/// Decoded protobuf message: last-seen value per field number.
class ProtoMessage {
  ProtoMessage._(this._varints, this._bytes);

  final Map<int, int> _varints;
  final Map<int, Uint8List> _bytes;

  /// Returns the varint value of [fieldNumber], or 0 when absent (proto3
  /// default semantics).
  int varint(int fieldNumber) => _varints[fieldNumber] ?? 0;

  /// Returns the length-delimited value of [fieldNumber], or null when absent.
  Uint8List? bytes(int fieldNumber) => _bytes[fieldNumber];

  ProtoMessage? message(int fieldNumber) {
    final raw = _bytes[fieldNumber];
    return raw == null ? null : ProtoMessage.parse(raw);
  }

  static ProtoMessage parse(Uint8List data) {
    final varints = <int, int>{};
    final bytes = <int, Uint8List>{};
    var offset = 0;

    int readVarint() {
      var result = 0;
      var shift = 0;
      while (true) {
        if (offset >= data.length) {
          throw const FormatException('Truncated varint');
        }
        final b = data[offset++];
        result |= (b & 0x7F) << shift;
        if (b & 0x80 == 0) return result;
        shift += 7;
      }
    }

    while (offset < data.length) {
      final tag = readVarint();
      final fieldNumber = tag >> 3;
      final wireType = tag & 0x7;
      switch (wireType) {
        case 0:
          varints[fieldNumber] = readVarint();
        case 2:
          final length = readVarint();
          if (offset + length > data.length) {
            throw const FormatException('Truncated length-delimited field');
          }
          bytes[fieldNumber] = Uint8List.sublistView(
            data,
            offset,
            offset + length,
          );
          offset += length;
        case 5:
          offset += 4;
        case 1:
          offset += 8;
        default:
          throw FormatException('Unsupported wire type $wireType');
      }
    }
    return ProtoMessage._(varints, bytes);
  }
}
