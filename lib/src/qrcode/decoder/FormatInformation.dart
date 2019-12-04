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



import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
// import 'dart:ffi';

import '../../utils.dart';
import 'ErrorCorrectionLevel.dart';

/**
 * <p>Encapsulates a QR Code's format information, including the data mask used and
 * error correction level.</p>
 *
 * @author Sean Owen
 * @see DataMask
 * @see ErrorCorrectionLevel
 */
class FormatInformation {

  static final int _FORMAT_INFO_MASK_QR = 0x5412;

  /**
   * See ISO 18004:2006, Annex C, Table C.1
   */
  static final List<List<int>> _FORMAT_INFO_DECODE_LOOKUP = List<List<int>>.from({
      List<int>.from({0x5412, 0x00}),
      List<int>.from({0x5125, 0x01}),
      List<int>.from({0x5E7C, 0x02}),
      List<int>.from({0x5B4B, 0x03}),
      List<int>.from({0x45F9, 0x04}),
      List<int>.from({0x40CE, 0x05}),
      List<int>.from({0x4F97, 0x06}),
      List<int>.from({0x4AA0, 0x07}),
      List<int>.from({0x77C4, 0x08}),
      List<int>.from({0x72F3, 0x09}),
      List<int>.from({0x7DAA, 0x0A}),
      List<int>.from({0x789D, 0x0B}),
      List<int>.from({0x662F, 0x0C}),
      List<int>.from({0x6318, 0x0D}),
      List<int>.from({0x6C41, 0x0E}),
      List<int>.from({0x6976, 0x0F}),
      List<int>.from({0x1689, 0x10}),
      List<int>.from({0x13BE, 0x11}),
      List<int>.from({0x1CE7, 0x12}),
      List<int>.from({0x19D0, 0x13}),
      List<int>.from({0x0762, 0x14}),
      List<int>.from({0x0255, 0x15}),
      List<int>.from({0x0D0C, 0x16}),
      List<int>.from({0x083B, 0x17}),
      List<int>.from({0x355F, 0x18}),
      List<int>.from({0x3068, 0x19}),
      List<int>.from({0x3F31, 0x1A}),
      List<int>.from({0x3A06, 0x1B}),
      List<int>.from({0x24B4, 0x1C}),
      List<int>.from({0x2183, 0x1D}),
      List<int>.from({0x2EDA, 0x1E}),
      List<int>.from({0x2BED, 0x1F}),
  });

  ErrorCorrectionLevel _errorCorrectionLevel;
  Uint8List _dataMask;

  FormatInformation(int formatInfo) {
    // Bits 3,4
    this._errorCorrectionLevel = ErrorCorrectionLevel.forBits((formatInfo >> 3) & 0x03); // Bottom 3 bits
    this._dataMask = Uint8List.fromList({(formatInfo & 0x07)}.toList());
  }

  static int numBitsDiffering(int a, int b) {
    return bitCount(a ^ b);
  }

  /**
   * @param maskedFormatInfo1 format info indicator, with mask still applied
   * @param maskedFormatInfo2 second copy of same info; both are checked at the same time
   *  to establish best match
   * @return information about the format it specifies, or {@code null}
   *  if doesn't seem to match any known pattern
   */
  static FormatInformation decodeFormatInformation(int maskedFormatInfo1, int maskedFormatInfo2) {
    FormatInformation formatInfo = _doDecodeFormatInformation(maskedFormatInfo1, maskedFormatInfo2);

    if (formatInfo != null) {
      return formatInfo;
    }
    // Should return null, but, some QR codes apparently
    // do not mask this info. Try again by actually masking the pattern
    // first
    return _doDecodeFormatInformation(maskedFormatInfo1 ^ _FORMAT_INFO_MASK_QR,
                                     maskedFormatInfo2 ^ _FORMAT_INFO_MASK_QR);
  }

  static FormatInformation _doDecodeFormatInformation(int maskedFormatInfo1, int maskedFormatInfo2) {
    // Find the int in FORMAT_INFO_DECODE_LOOKUP with fewest bits differing
    int bestDifference = Int64.MAX_VALUE.toInt();
    int bestFormatInfo = 0;
    for (List<int> decodeInfo in _FORMAT_INFO_DECODE_LOOKUP) {
      int targetInfo = decodeInfo[0];
      if (targetInfo == maskedFormatInfo1 || targetInfo == maskedFormatInfo2) {
        // Found an exact match
        return new FormatInformation(decodeInfo[1]);
      }
      int bitsDifference = numBitsDiffering(maskedFormatInfo1, targetInfo);
      if (bitsDifference < bestDifference) {
        bestFormatInfo = decodeInfo[1];
        bestDifference = bitsDifference;
      }
      if (maskedFormatInfo1 != maskedFormatInfo2) {
        // also try the other option
        bitsDifference = numBitsDiffering(maskedFormatInfo2, targetInfo);
        if (bitsDifference < bestDifference) {
          bestFormatInfo = decodeInfo[1];
          bestDifference = bitsDifference;
        }
      }
    }

    // Hamming distance of the 32 masked codes is 7, by construction, so <= 3 bits
    // differing means we found a match
    if (bestDifference <= 3) {
      return new FormatInformation(bestFormatInfo);
    }
    return null;
  }

  ErrorCorrectionLevel getErrorCorrectionLevel() {
    return _errorCorrectionLevel;
  }

  Uint8List getDataMask() {
    return _dataMask;
  }


  int get hashCode {
    return (_errorCorrectionLevel.getBits() << 3) | _dataMask.first.toInt();
  }

  @override
  operator ==(Object o) {
    if (!(o.runtimeType == FormatInformation)) {
      return false;
    }
    FormatInformation other = o as FormatInformation;
    return this._errorCorrectionLevel.getBits() == other._errorCorrectionLevel.getBits() &&
        this._dataMask == other._dataMask;
  }

}
