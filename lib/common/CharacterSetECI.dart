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

import 'dart:collection';
import '../common/Enum.dart';

class CharacterSetECI extends Enum<int> {
  static final Map<int,CharacterSetECI> _VALUE_TO_ECI = new HashMap();
  static final Map<String,CharacterSetECI> _NAME_TO_ECI = new HashMap();
  final List<int> _values;
  final List<String> _otherEncodingNames;

  const CharacterSetECI(int value, this._values, this._otherEncodingNames)
      : super(value);

  static final Cp437 = new CharacterSetECI(0, List.from({0, 2}), null);
  static final ISO8859_1 =
      new CharacterSetECI(1, List.from({1, 3}), List.from({"ISO-8859-1"}));
  static final ISO8859_2 =
      new CharacterSetECI(2, List.from({4}), List.from({"ISO-8859-2"}));
  static final ISO8859_3 =
      new CharacterSetECI(3, List.from({5}), List.from({"ISO-8859-3"}));
  static final ISO8859_4 =
      new CharacterSetECI(4, List.from({6}), List.from({"ISO-8859-4"}));
  static final ISO8859_5 =
      new CharacterSetECI(5, List.from({7}), List.from({"ISO-8859-5"}));
  static final ISO8859_6 =
      new CharacterSetECI(6, List.from({8}), List.from({"ISO-8859-6"}));
  static final ISO8859_7 =
      new CharacterSetECI(7, List.from({9}), List.from({"ISO-8859-7"}));
  static final ISO8859_8 =
      new CharacterSetECI(8, List.from({10}), List.from({"ISO-8859-8"}));
  static final ISO8859_9 =
      new CharacterSetECI(9, List.from({11}), List.from({"ISO-8859-9"}));
  static final ISO8859_10 =
      new CharacterSetECI(10, List.from({12}), List.from({"ISO-8859-10"}));
  static final ISO8859_11 =
      new CharacterSetECI(11, List.from({13}), List.from({"ISO-8859-11"}));
  static final ISO8859_13 =
      new CharacterSetECI(12, List.from({15}), List.from({"ISO-8859-13"}));
  static final ISO8859_14 =
      new CharacterSetECI(13, List.from({16}), List.from({"ISO-8859-14"}));
  static final ISO8859_15 =
      new CharacterSetECI(14, List.from({17}), List.from({"ISO-8859-15"}));
  static final ISO8859_16 =
      new CharacterSetECI(15, List.from({18}), List.from({"ISO-8859-16"}));
  static final SJIS =
      new CharacterSetECI(16, List.from({20}), List.from({"Shift_JIS"}));
  static final Cp1250 =
      new CharacterSetECI(17, List.from({21}), List.from({"windows-1250"}));
  static final Cp1251 =
      new CharacterSetECI(18, List.from({22}), List.from({"windows-1251"}));
  static final Cp1252 =
      new CharacterSetECI(19, List.from({23}), List.from({"windows-1252"}));
  static final Cp1256 =
      new CharacterSetECI(20, List.from({24}), List.from({"windows-1256"}));
  static final UnicodeBigUnmarked = new CharacterSetECI(
      12, List.from({25}), List.from({"UTF-16BE" "UnicodeBig"}));
  static final UTF8 =
      new CharacterSetECI(22, List.from({26}), List.from({"UTF-8"}));
  static final ASCII =
      new CharacterSetECI(23, List.from({27, 170}), List.from({"US-ASCII"}));
  static final Big5 = new CharacterSetECI(24, List.from({28}), null);
  static final GB18030 = new CharacterSetECI(
      25, List.from({29}), List.from({"GB2312", "EUC_CN", "GBK"}));
  static final EUC_KR =
      new CharacterSetECI(26, List.from({30}), List.from({"EUC-KR"}));
}

// class CharacterSetEciObject {

//   final List<int> _values;
//   final List<String> _otherEncodingNames;
//   final String _name;

//   CharacterSetEciObject(this._name, this._values, this._otherEncodingNames);

//   int getValue() {
//     return this._values[0];
//   }

// }

// class CharacterSetECI{
//     static final Map<int,CharacterSetEciObject> _VALUE_TO_ECI = new HashMap();
//     static final Map<String,CharacterSetEciObject> _NAME_TO_ECI = new HashMap();

//     static final list = List.from({
//       new CharacterSetEciObject("Cp437", new List.from({0,2}), null),
//       new CharacterSetEciObject("ISO8859_1", new List.from({1,3}), new List.from({"ISO-8859-1"})),
//       new CharacterSetEciObject("ISO8859_2", new List.from({4}), new List.from({"ISO-8859-2"})),
//       new CharacterSetEciObject("ISO8859_3",new List.from({5}), new List.from({"ISO-8859-3"})),
//       new CharacterSetEciObject("ISO8859_4",new List.from({6}),  new List.from({"ISO-8859-4"})),
//       new CharacterSetEciObject("ISO8859_5",new List.from({7}), new List.from({"ISO-8859-5"})),
//       new CharacterSetEciObject("ISO8859_6",new List.from({8}), new List.from({"ISO-8859-6"})),
//       new CharacterSetEciObject("ISO8859_7",new List.from({9}), new List.from({"ISO-8859-7"})),
//       new CharacterSetEciObject("ISO8859_8",new List.from({10}), new List.from({"ISO-8859-8"})),
//       new CharacterSetEciObject("ISO8859_9",new List.from({11}), new List.from({"ISO-8859-9"})),
//       new CharacterSetEciObject("ISO8859_10",new List.from({12}), new List.from({"ISO-8859-10"})),
//       new CharacterSetEciObject("ISO8859_11",new List.from({13}), new List.from({"ISO-8859-11"})),
//       new CharacterSetEciObject("ISO8859_13",new List.from({15}), new List.from({"ISO-8859-13"})),
//       new CharacterSetEciObject("ISO8859_14",new List.from({16}), new List.from({"ISO-8859-14"})),
//       new CharacterSetEciObject("ISO8859_15",new List.from({17}), new List.from({"ISO-8859-15"})),
//       new CharacterSetEciObject("ISO8859_16",new List.from({18}), new List.from({"ISO-8859-16"})),
//       new CharacterSetEciObject("SJIS",new List.from({20}), new List.from({"Shift_JIS"})),
//       new CharacterSetEciObject("Cp1250",new List.from({21}), new List.from({"windows-1250"})),
//       new CharacterSetEciObject("Cp1251",new List.from({22}), new List.from({"windows-1251"})),
//       new CharacterSetEciObject("Cp1252",new List.from({23}), new List.from({"windows-1252"})),
//       new CharacterSetEciObject("Cp1256",new List.from({24}),new List.from({ "windows-1256"})),
//       new CharacterSetEciObject("UnicodeBigUnmarked",new List.from({25}), new List.from({"UTF-16BE", "UnicodeBig"})),
//       new CharacterSetEciObject("UTF8",new List.from({26}), new List.from({"UTF-8"})),
//       new CharacterSetEciObject("ASCII",new List.from({27, 170}), new List.from({"US-ASCII"})),
//       new CharacterSetEciObject("Big5",new List.from({28}), null),
//       new CharacterSetEciObject("GB18030",new List.from({29}), new List.from({"GB2312", "EUC_CN", "GBK"})),
//       new CharacterSetEciObject("EUC_KR",new List.from({30}), new List.from({"EUC-KR"}))
//     });

//       static final CharacterSetEciObject Cp437 = list[0];
//       static final CharacterSetEciObject ISO8859_1 = list[1];
//       static final CharacterSetEciObject ISO8859_2 = list[2];
//       static final CharacterSetEciObject ISO8859_3 = list[3];
//       static final CharacterSetEciObject ISO8859_4 = list[4];
//       static final CharacterSetEciObject ISO8859_5 = list[5];
//       static final CharacterSetEciObject ISO8859_6 = list[6];
//       static final CharacterSetEciObject ISO8859_7 = list[7];
//       static final CharacterSetEciObject ISO8859_8 = list[8];
//       static final CharacterSetEciObject ISO8859_9 = list[9];
//       static final CharacterSetEciObject ISO8859_10 = list[10];
//       static final CharacterSetEciObject ISO8859_11 = list[11];
//       static final CharacterSetEciObject ISO8859_13 = list[12];
//       static final CharacterSetEciObject ISO8859_14 = list[13];
//       static final CharacterSetEciObject ISO8859_15 = list[14];
//       static final CharacterSetEciObject ISO8859_16 = list[15];
//       static final CharacterSetEciObject SJIS = list[16];
//       static final CharacterSetEciObject Cp1250 = list[17];
//       static final CharacterSetEciObject Cp1251 = list[18];
//       static final CharacterSetEciObject Cp1252 = list[19];
//       static final CharacterSetEciObject Cp1256 = list[20];
//       static final CharacterSetEciObject UnicodeBigUnmarked = list[21];
//       static final CharacterSetEciObject UTF8 = list[22];
//       static final CharacterSetEciObject ASCII = list[23];
//       static final CharacterSetEciObject Big5 = list[24];
//       static final CharacterSetEciObject GB18030 = list[25];
//       static final CharacterSetEciObject EUC_KR = list[26];

//       CharacterSetECI(){
//             for (CharacterSetEciObject eci in list) {
//       for (int value in eci._values) {
//         _VALUE_TO_ECI.addEntries({MapEntry(value, eci)});
//       }
//       _NAME_TO_ECI.addEntries({MapEntry(eci._name, eci)});
//       for (String name in eci._otherEncodingNames) {
//         _NAME_TO_ECI.addEntries({MapEntry(name, eci)});
//       }
//     }
//       }

//         /**
//    * @param value character set ECI value
//    * @return {@code CharacterSetECI} representing ECI of given value, or null if it is legal but
//    *   unsupported
//    * @throws FormatException if ECI value is invalid
//    */
//   static CharacterSetEciObject getCharacterSetECIByValue(int value) {
//     if (value < 0 || value >= 900) {
//       throw Exception("FormatException");
//     }
//     return _VALUE_TO_ECI[value];
//   }

//   /**
//    * @param name character set ECI encoding name
//    * @return CharacterSetECI representing ECI for character encoding, or null if it is legal
//    *   but unsupported
//    */
//   static CharacterSetEciObject getCharacterSetECIByName(String name) {
//     return _NAME_TO_ECI[name];
//   }
// }
