class TerbilangID {
  List<String> digits = [
    "",
    "satu",
    "dua",
    "tiga",
    "empat",
    "lima",
    "enam",
    "tujuh",
    "delapan",
    "sembilan",
    "sepuluh",
    "sebelas",
  ];

  Map<String, String> fractions = {
    "0": "nol",
    "1": "satu",
    "2": "dua",
    "3": "tiga",
    "4": "empat",
    "5": "lima",
    "6": "enam",
    "7": "tujuh",
    "8": "delapan",
    "9": "sembilan",
  };

  dynamic number;
  int p = 0;
  String f = "";
  String result = "";
  String fraction = "";

  TerbilangID({this.number}) {
    // print(double.parse(this.number.toString()));
    List<String> tmp = double.parse(number.toString()).toString().split(".");
    p = int.parse(tmp[0]);
    f = tmp[1];
    p = number;
  }

  String results() {
    String pText = convert(p);

    if (f != "0") {
      pText += " koma ";
      String ftext = convertFraction(f);

      pText += ftext;
    }

    return pText;
  }

  String convertFraction(String number) {
    for (var e in number.runes) {
      var c = String.fromCharCode(e);
      fraction +=
          fractions[c.toString()] ??
          ""
              " ";
    }

    return fraction.trim();
  }

  String convert(int number) {
    if (number < 12) {
      result = digits[number];
    } else if (number >= 12 && number <= 19) {
      result = "${digits[number % 10]} belas";
    } else if (number >= 20 && number <= 99) {
      result = "${convert((number ~/ 10))} puluh ${digits[number % 10]}";
    } else if (number >= 100 && number <= 199) {
      result = "seratus ${convert(number % 100)}";
    } else if (number >= 200 && number <= 999) {
      result = "${convert(number ~/ 100)} ratus ${convert(number % 100)}";
    } else if (number >= 1000 && number <= 1999) {
      result = "seribu ${convert(number % 1000)}";
    } else if (number >= 2000 && number <= 999999) {
      result = "${convert(number ~/ 1000)} ribu ${convert(number % 1000)}";
    } else if (number >= 1000000 && number <= 999999999) {
      result =
          "${convert(number ~/ 1000000)} juta ${convert(number % 1000000)}";
    } else if (number >= 1000000000 && number <= 999999999999) {
      result =
          "${convert(number ~/ 1000000000)} milyar ${convert(number % 1000000000)}";
    } else if (number >= 1000000000000 && number <= 999999999999999) {
      result =
          "${convert(number ~/ 1000000000000)} trilyun ${convert(number % 1000000000000)}";
    } else if (number >= 1000000000000000 && number <= 999999999999999999) {
      result =
          "${convert(number ~/ 1000000000000000)} kuadriliun ${convert(number % 1000000000000000)}";
    }
    return result;
  }
}
