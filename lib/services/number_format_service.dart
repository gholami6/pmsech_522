class NumberFormatService {
  /// فرمت کردن اعداد با جداکننده کاما
  /// مثال: 123456789 → 123,456,789
  static String formatNumber(dynamic number) {
    if (number == null) return '0';

    final value = number is double ? number.toInt() : number;
    String numberStr = value.toString();

    if (numberStr.length <= 3) return numberStr;

    final List<String> parts = [];
    String remaining = numberStr;

    while (remaining.length > 3) {
      parts.insert(0, remaining.substring(remaining.length - 3));
      remaining = remaining.substring(0, remaining.length - 3);
    }

    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }

    return parts.join(',');
  }

  /// فرمت کردن اعداد اعشاری با جداکننده
  /// مثال: 123456.78 → 123,456.78
  static String formatDecimalNumber(dynamic number, {int decimalPlaces = 2}) {
    if (number == null) return '0';

    final value = number is int ? number.toDouble() : number as double;
    String formattedNumber = value.toStringAsFixed(decimalPlaces);

    // جدا کردن قسمت صحیح و اعشاری
    List<String> parts = formattedNumber.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';

    // فرمت کردن قسمت صحیح
    String formattedInteger = formatNumber(int.parse(integerPart));

    // ترکیب قسمت صحیح و اعشاری
    if (decimalPart.isNotEmpty && decimalPart != '00') {
      return '$formattedInteger.$decimalPart';
    } else {
      return formattedInteger;
    }
  }

  /// فرمت کردن عدد با واحد تناژ
  /// مثال: 123456 → 123,456 تن
  static String formatTonnage(dynamic number) {
    return '${formatNumber(number)} تن';
  }

  /// فرمت کردن درصد
  /// مثال: 0.1234 → 12.34%
  static String formatPercentage(dynamic number, {int decimalPlaces = 2}) {
    if (number == null) return '0%';

    final value = number is int ? number.toDouble() : number as double;
    final percentage = value * 100;
    return '${formatDecimalNumber(percentage, decimalPlaces: decimalPlaces)}%';
  }
}
