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

import '../../DecodeHintType.dart';
import '../../common/BitMatrix.dart';
import '../../common/DecoderResult.dart';
import '../../common/reedsolomon/GenericGF.dart';
import '../../common/reedsolomon/ReedSolomonDecoder.dart';
import 'BitMatrixParser.dart';
import 'DataBlock.dart';
import 'DecodedBitStreamParser.dart';
import 'ErrorCorrectionLevel.dart';
import 'QRCodeDecoderMetaData.dart';
import 'Version.dart';



// import com.google.zxing.ChecksumException;
// import com.google.zxing.FormatException;
// import com.google.zxing.common.reedsolomon.ReedSolomonException;


/**
 * <p>The main class which implements QR Code decoding -- as opposed to locating and extracting
 * the QR Code from an image.</p>
 *
 * @author Sean Owen
 */
class Decoder {

  final ReedSolomonDecoder _rsDecoder = new ReedSolomonDecoder(GenericGF.QR_CODE_FIELD_256);


  /**
   * <p>Convenience method that can decode a QR Code represented as a 2D array of booleans.
   * "true" is taken to mean a black module.</p>
   *
   * @param image booleans representing white/black QR Code modules
   * @param hints decoding hints that should be used to influence decoding
   * @return text and bytes encoded within the QR Code
   * @throws FormatException if the QR Code cannot be decoded
   * @throws ChecksumException if error correction fails
   */

  /**
   * <p>Decodes a QR Code represented as a {@link BitMatrix}. A 1 or "true" is taken to mean a black module.</p>
   *
   * @param bits booleans representing white/black QR Code modules
   * @param hints decoding hints that should be used to influence decoding
   * @return text and bytes encoded within the QR Code
   * @throws FormatException if the QR Code cannot be decoded
   * @throws ChecksumException if error correction fails
   */
  DecoderResult decode(BitMatrix bits, Map<DecodeHintType,Object> hints)
    {

    // Construct a parser and read version, error-correction level
    BitMatrixParser parser = new BitMatrixParser(bits);
    Exception fe;
    Exception ce;
    try {
      return decode(parser as BitMatrix, hints);
    } catch (e) {
      // fe = e; // need to fix this
      // ce = e; // need to fix this
    }

    try {

      // Revert the bit matrix
      parser.remask();
      print("#1");

      // Will be attempting a mirrored reading of the version and format info.
      parser.setMirror(true);
      print("#2");


      // Preemptively read the version.
      parser.readVersion();
      print("#3");


      // Preemptively read the format information.
      parser.readFormatInformation();
      print("#5");

      /*
       * Since we're here, this means we have successfully detected some kind
       * of version and format information when mirrored. This is a good sign,
       * that the QR code may be mirrored, and we should try once more with a
       * mirrored content.
       */
      // Prepare for a mirrored reading.
      parser.mirror();
      print("#6");


      DecoderResult result = _decode(parser, hints);
      print("#7");


      // Success! Notify the caller that the code was mirrored.
      result.setOther(new QRCodeDecoderMetaData(true));
      print("#8");


      return result;

    } catch (e) {
      throw Exception(e); //TODO: Fix this
      // // Throw the exception from the original reading
      // if (fe != null) {
      //   throw Exception("Something Happened");
      // }
      // throw Exception("Something happend"); // If fe is null, this can't be
    }
  }

  DecoderResult _decode(BitMatrixParser parser, Map<DecodeHintType, Object> hints)
      {
    Version version = parser.readVersion();
    print("#31");

    ErrorCorrectionLevel ecLevel = parser.readFormatInformation().getErrorCorrectionLevel();
    print("#32");
    // Read codewords
    Uint8List codewords = parser.readCodewords();
    print("#33");

    // Separate into data blocks
    List<DataBlock> dataBlocks = DataBlock.getDataBlocks(codewords, version, ecLevel);
    print("#34");


    // Count total number of data bytes
    int totalBytes = 0;
    for (DataBlock dataBlock in dataBlocks) {
      totalBytes += dataBlock.getNumDataCodewords();
    }
    print("#35");

    Uint8List resultBytes = new Uint8List(totalBytes);
    int resultOffset = 0;

    // Error-correct and copy data blocks together into a stream of bytes
    for (DataBlock dataBlock in dataBlocks) {
      Uint8List codewordBytes = dataBlock.getCodewords();
      int numDataCodewords = dataBlock.getNumDataCodewords();
    print("#36");

      _correctErrors(codewordBytes, numDataCodewords);
    print("#37");

      for (int i = 0; i < numDataCodewords; i++) {
        resultBytes[resultOffset++] = codewordBytes[i];
      }
    }

    // Decode the contents of that stream of bytes
    return DecodedBitStreamParser.decode(resultBytes, version, ecLevel, hints);
  }

  /**
   * <p>Given data and error-correction codewords received, possibly corrupted by errors, attempts to
   * correct the errors in-place using Reed-Solomon error correction.</p>
   *
   * @param codewordBytes data and error correction codewords
   * @param numDataCodewords number of codewords that are data bytes
   * @throws ChecksumException if error correction fails
   */
  void _correctErrors(Uint8List codewordBytes, int numDataCodewords) {
    int numCodewords = codewordBytes.length;
    // First read into an array of ints
    List<int> codewordsInts = List<int>.filled(numCodewords, 0);
    for (int i = 0; i < numCodewords; i++) {
      codewordsInts[i] = codewordBytes[i] & 0xFF;
    }
    try {
      _rsDecoder.decode(codewordsInts, codewordBytes.length - numDataCodewords);
    } catch (ignored) {
      throw Exception(ignored);
      // throw Exception("Checksum Exception");
    }
    // Copy back into array of bytes -- only need to worry about the bytes that were data
    // We don't care about errors in the error-correction codewords
    for (int i = 0; i < numDataCodewords; i++) {
      codewordBytes[i] = codewordsInts[i];
    }
  }

}
