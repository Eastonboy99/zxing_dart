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



/**
 * <p>See ISO 18004:2006, 6.5.1. This enum encapsulates the four error correction levels
 * defined by the QR code standard.</p>
 *
 * @author Sean Owen
 */
class ErrorCorrectionLevel {

  /** L = ~7% correction */
  static final L = (0x01);
  /** M = ~15% correction */
  static final M = (0x00);
  /** Q = ~25% correction */
  static final Q = (0x03);
  /** H = ~30% correction */
  static final H = (0x02);

  static final List<ErrorCorrectionLevel> _FOR_BITS = List.from({M, L, H, Q});

  final int _bits;

  ErrorCorrectionLevel(this._bits);

  int getBits() {
    return this._bits;
  }

  /**
   * @param bits int containing the two bits encoding a QR Code's error correction level
   * @return ErrorCorrectionLevel representing the encoded error correction level
   */
  static ErrorCorrectionLevel forBits(int bits) {
    if (bits < 0 || bits >= _FOR_BITS.length) {
      throw new Exception();
    }
    return _FOR_BITS[bits];
  }


}
