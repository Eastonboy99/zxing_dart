/*
 * Copyright 2007 ZXing authors
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

import '../../common/BitMatrix.dart';

import '../../common/Enum.dart';

class DataMask<int> extends Enum<int> {
  final Function isMasked;
  const DataMask(int val, this.isMasked) : super(val);

  /**
   * 000: mask bits for which (x + y) mod 2 == 0
   */
  static final DATA_MASK_000 =
      new DataMask(0, (i, j) => {((i + j) & 0x01) == 0});

  /**
   * 001: mask bits for which x mod 2 == 0
   */
  static final DATA_MASK_001 = new DataMask(1, (i, j) => {(i & 0x01) == 0});

  /**
   * 010: mask bits for which y mod 3 == 0
   */
  static final DATA_MASK_010 = new DataMask(2, (i, j) => {j % 3 == 0});

  /**
   * 011: mask bits for which (x + y) mod 3 == 0
   */
  static final DATA_MASK_011 = new DataMask(3, (i, j) => {(i + j) % 3 == 0});
  /**
   * 100: mask bits for which (x/2 + y/3) mod 2 == 0
   */
  static final DATA_MASK_100 =
      new DataMask(4, (i, j) => {(((i ~/ 2) + (j ~/ 3)) & 0x01) == 0});

  /**
   * 101: mask bits for which xy mod 2 + xy mod 3 == 0
   * equivalently, such that xy mod 6 == 0
   */
  static final DATA_MASK_101 = new DataMask(5, (i, j) => {(i * j) % 6 == 0});

  /**
   * 110: mask bits for which (xy mod 2 + xy mod 3) mod 2 == 0
   * equivalently, such that xy mod 6 < 3
   */
  static final DATA_MASK_110 = new DataMask(6, (i, j) => {((i * j) % 6) < 3});

  /**
   * 111: mask bits for which ((x+y)mod 2 + xy mod 3) mod 2 == 0
   * equivalently, such that (x + y + xy mod 3) mod 2 == 0
   */
  static final DATA_MASK_111 =
      new DataMask(7, (i, j) => {((i + j + ((i * j) % 3)) & 0x01) == 0});


  static final _list = List.from({
    DATA_MASK_000,
    DATA_MASK_001,
    DATA_MASK_010,
    DATA_MASK_011,
    DATA_MASK_100,
    DATA_MASK_101,
    DATA_MASK_110,
    DATA_MASK_111
  });

  /**
   * <p>Implementations of this method reverse the data masking process applied to a QR Code and
   * make its bits ready to read.</p>
   *
   * @param bits representation of QR Code bits
   * @param dimension dimension of QR Code, represented by bits, being unmasked
   */
  void unmaskBitMatrix(BitMatrix bits, num dimension) {
    for (var i = 0; i < dimension; i++) {
      for (var j = 0; j < dimension; j++) {
        if (isMasked(i, j)) {
          bits.flip(j, i);
        }
      }
    }
  }

  static List<DataMask> values(){
    return _list;
  }


}

