/*
 * Copyright 2008 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// import com.google.zxing.FormatException;

import '../common/Enum.dart';

class CharacterSetECI extends Enum<int> {
  final List<int> _values;
  final List<String> _otherEncodingNames;

  const CharacterSetECI(int value, this._values, this._otherEncodingNames)
      : super(value);

  static final Cp437 =
      new CharacterSetECI(0, List.from({0, 2}), List.from({"Cp437"}));
  static final ISO8859_1 = new CharacterSetECI(
      1, List.from({1, 3}), List.from({"ISO8859_1", "ISO-8859-1"}));
  static final ISO8859_2 = new CharacterSetECI(
      2, List.from({4}), List.from({"ISO8859_2", "ISO-8859-2"}));
  static final ISO8859_3 = new CharacterSetECI(
      3, List.from({5}), List.from({"ISO8859_3", "ISO-8859-3"}));
  static final ISO8859_4 = new CharacterSetECI(
      4, List.from({6}), List.from({"ISO8859_4", "ISO-8859-4"}));
  static final ISO8859_5 = new CharacterSetECI(
      5, List.from({7}), List.from({"ISO8859_5", "ISO-8859-5"}));
  static final ISO8859_6 = new CharacterSetECI(
      6, List.from({8}), List.from({"ISO8859_6", "ISO-8859-6"}));
  static final ISO8859_7 = new CharacterSetECI(
      7, List.from({9}), List.from({"ISO8859_7", "ISO-8859-7"}));
  static final ISO8859_8 = new CharacterSetECI(
      8, List.from({10}), List.from({"ISO8859_8", "ISO-8859-8"}));
  static final ISO8859_9 = new CharacterSetECI(
      9, List.from({11}), List.from({"ISO8859_9", "ISO-8859-9"}));
  static final ISO8859_10 = new CharacterSetECI(
      10, List.from({12}), List.from({"ISO8859_10", "ISO-8859-10"}));
  static final ISO8859_11 = new CharacterSetECI(
      11, List.from({13}), List.from({"ISO8859_11", "ISO-8859-11"}));
  static final ISO8859_13 = new CharacterSetECI(
      12, List.from({15}), List.from({"ISO8859_13", "ISO-8859-13"}));
  static final ISO8859_14 = new CharacterSetECI(
      13, List.from({16}), List.from({"ISO8859_14", "ISO-8859-14"}));
  static final ISO8859_15 = new CharacterSetECI(
      14, List.from({17}), List.from({"ISO8859_15", "ISO-8859-15"}));
  static final ISO8859_16 = new CharacterSetECI(
      15, List.from({18}), List.from({"ISO8859_16", "ISO-8859-16"}));
  static final SJIS = new CharacterSetECI(
      16, List.from({20}), List.from({"SJIS", "Shift_JIS"}));
  static final Cp1250 = new CharacterSetECI(
      17, List.from({21}), List.from({"Cp1250", "windows-1250"}));
  static final Cp1251 = new CharacterSetECI(
      18, List.from({22}), List.from({"Cp1251", "windows-1251"}));
  static final Cp1252 = new CharacterSetECI(
      19, List.from({23}), List.from({"Cp1252", "windows-1252"}));
  static final Cp1256 = new CharacterSetECI(
      20, List.from({24}), List.from({"Cp1256", "windows-1256"}));
  static final UnicodeBigUnmarked = new CharacterSetECI(12, List.from({25}),
      List.from({"UnicodeBigUnmarked", "UTF-16BE" "UnicodeBig"}));
  static final UTF8 =
      new CharacterSetECI(22, List.from({26}), List.from({"UTF8", "UTF-8"}));
  static final ASCII = new CharacterSetECI(
      23, List.from({27, 170}), List.from({"ASCII", "US-ASCII"}));
  static final Big5 =
      new CharacterSetECI(24, List.from({28}), List.from({"Big5"}));
  static final GB18030 = new CharacterSetECI(
      25, List.from({29}), List.from({"GB18030", "GB2312", "EUC_CN", "GBK"}));
  static final EUC_KR =
      new CharacterSetECI(26, List.from({30}), List.from({"EUC_KR", "EUC-KR"}));

  static final _list = List.from({
    Cp437,
    ISO8859_1,
    ISO8859_2,
    ISO8859_3,
    ISO8859_4,
    ISO8859_5,
    ISO8859_6,
    ISO8859_7,
    ISO8859_8,
    ISO8859_9,
    ISO8859_10,
    ISO8859_11,
    ISO8859_13,
    ISO8859_14,
    ISO8859_15,
    SJIS,
    Cp1250,
    Cp1251,
    Cp1252,
    Cp1256,
    UnicodeBigUnmarked,
    UTF8,
    ASCII,
    Big5,
    GB18030,
    EUC_KR
  });

  static List<CharacterSetECI> values() {
    return _list;
  }

  static Map<int, CharacterSetECI> _VALUE_TO_ECI() {
    Map<int, CharacterSetECI> map;
    for (CharacterSetECI eci in values()) {
      for (int value in eci._values) {
        map.putIfAbsent(value, () => eci);
      }
    }
    return map;
  }

  static Map<String, CharacterSetECI> _NAME_TO_ECI() {
    Map<String, CharacterSetECI> map;
    for (CharacterSetECI eci in values()) {
      for (String name in eci._otherEncodingNames) {
        map.putIfAbsent(name, () => eci);
      }
    }
    return map;
  }

  int getValue() {
    return this._values[0];
  }

  String name(){
    return _otherEncodingNames[0];
  }

  /**
   * @param value character set ECI value
   * @return {@code CharacterSetECI} representing ECI of given value, or null if it is legal but
   *   unsupported
   * @throws FormatException if ECI value is invalid
   */
  static CharacterSetECI getCharacterSecECIByValue(int value) {
    return _VALUE_TO_ECI()[value];
  }

  /**
   * @param name character set ECI encoding name
   * @return CharacterSetECI representing ECI for character encoding, or null if it is legal
   *   but unsupported
   */
  static CharacterSetECI getCharacterSetECIByName(String name) {
    return _NAME_TO_ECI()[name];
  }
}
