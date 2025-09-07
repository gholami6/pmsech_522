import 'dart:convert';

class EncodingService {
  static final EncodingService _instance = EncodingService._internal();
  factory EncodingService() => _instance;
  EncodingService._internal();

  String decodePersianText(String text) {
    try {
      // Try UTF-8 first
      return utf8.decode(text.codeUnits);
    } catch (e) {
      try {
        // Try direct UTF-8 decoding
        return utf8.decode(utf8.encode(text));
      } catch (e) {
        // If all decoding attempts fail, return original text
        return text;
      }
    }
  }

  dynamic decodeJsonData(dynamic data) {
    if (data is Map<String, dynamic>) {
      final Map<String, dynamic> decodedMap = {};
      data.forEach((key, value) {
        if (value is String) {
          decodedMap[key] = decodePersianText(value);
        } else if (value is Map<String, dynamic>) {
          decodedMap[key] = decodeJsonData(value);
        } else if (value is List) {
          decodedMap[key] = value.map((item) {
            if (item is String) {
              return decodePersianText(item);
            } else if (item is Map<String, dynamic>) {
              return decodeJsonData(item);
            }
            return item;
          }).toList();
        } else {
          decodedMap[key] = value;
        }
      });
      return decodedMap;
    } else if (data is List) {
      return data.map((item) => decodeJsonData(item)).toList();
    }
    return data;
  }
}
