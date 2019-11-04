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
import 'dart:math';

import 'package:flutter/material.dart';

import '../BarcodeFormat.dart';
import '../BinaryBitmap.dart';
import '../DecodeHintType.dart';
import '../Reader.dart';
import '../Result.dart';
import '../ResultMetadataType.dart';
import '../ResultPoint.dart';
import '../common/BitMatrix.dart';
import '../common/DecoderResult.dart';
import '../common/DetectorResult.dart';
import './decoder/Decoder.dart';
import './decoder/QRCodeDecoderMetaData.dart';

import com.google.zxing.qrcode.detector.Detector;


/**
 * This implementation can detect and decode QR Codes in an image.
 *
 * @author Sean Owen
 */
class QRCodeReader implements Reader {

  static final List<ResultPoint> _NO_POINTS = new List<ResultPoint>(0);

  final Decoder _decoder = new Decoder();

  @protected
  Decoder getDecoder() {
    return this._decoder;
  }

  /**
   * Locates and decodes a QR code in an image.
   *
   * @return a String representing the content encoded by the QR code
   * @throws NotFoundException if a QR code cannot be found
   * @throws FormatException if a QR code cannot be decoded
   * @throws ChecksumException if error correction fails
   */

  @override
Result decode(BinaryBitmap image, {Map<DecodeHintType, Object> hints})
      {
    DecoderResult decoderResult;
    List<ResultPoint> points;
    if (hints != null && hints.containsKey(DecodeHintType.PURE_BARCODE)) {
      BitMatrix bits = extractPureBits(image.getBlackMatrix());
      decoderResult = this._decoder.decode(bits, hints);
      points = QRCodeReader._NO_POINTS;
    } else {
      DetectorResult detectorResult = new Detector(image.getBlackMatrix()).detect(hints);
      decoderResult = this._decoder.decode(detectorResult.getBits(), hints);
      points = detectorResult.getPoints();
    }

    // If the code was mirrored: swap the bottom-left and the top-right points.
    if (decoderResult.getOther().runtimeType == QRCodeDecoderMetaData) {
      (decoderResult.getOther() as QRCodeDecoderMetaData).applyMirroredCorrection(points);
    }

    Result result = new Result(decoderResult.getText(), decoderResult.getRawBytes(), points, BarcodeFormat.QR_CODE);
    List<Uint64List> byteSegments = decoderResult.getByteSegments();
    if (byteSegments != null) {
      result.putMetadata(ResultMetadataType.BYTE_SEGMENTS, byteSegments);
    }
    String ecLevel = decoderResult.getECLevel();
    if (ecLevel != null) {
      result.putMetadata(ResultMetadataType.ERROR_CORRECTION_LEVEL, ecLevel);
    }
    if (decoderResult.hasStructuredAppend()) {
      result.putMetadata(ResultMetadataType.STRUCTURED_APPEND_SEQUENCE,
                         decoderResult.getStructuredAppendSequenceNumber());
      result.putMetadata(ResultMetadataType.STRUCTURED_APPEND_PARITY,
                         decoderResult.getStructuredAppendParity());
    }
    return result;
  }

  @override
  void reset() {
    // do nothing
  }

  /**
   * This method detects a code in a "pure" image -- that is, pure monochrome image
   * which contains only an unrotated, unskewed, image of a code, with some white border
   * around it. This is a specialized method that works exceptionally fast in this special
   * case.
   */
  static BitMatrix extractPureBits(BitMatrix image){

    List<int> leftTopBlack = image.getTopLeftOnBit();
    List<int> rightBottomBlack = image.getBottomRightOnBit();
    if (leftTopBlack == null || rightBottomBlack == null) {
      throw Exception();
    }

    double moduleSize = _moduleSize(leftTopBlack, image);

    int top = leftTopBlack[1];
    int bottom = rightBottomBlack[1];
    int left = leftTopBlack[0];
    int right = rightBottomBlack[0];

    // Sanity check!
    if (left >= right || top >= bottom) {
      throw Exception();
    }

    if (bottom - top != right - left) {
      // Special case, where bottom-right module wasn't black so we found something else in the last row
      // Assume it's a square, so use height as the width
      right = left + (bottom - top);
      if (right >= image.getWidth()) {
        // Abort if that would not make sense -- off image
        throw Exception();
      }
    }

    int matrixWidth = ((right - left + 1).round() ~/ moduleSize);
    int matrixHeight = ((bottom - top + 1).round() ~/ moduleSize);
    if (matrixWidth <= 0 || matrixHeight <= 0) {
      throw Exception();
    }
    if (matrixHeight != matrixWidth) {
      // Only possibly decode square regions
      throw Exception();
    }

    // Push in the "border" by half the module width so that we start
    // sampling in the middle of the module. Just in case the image is a
    // little off, this will help recover.
    int nudge = (moduleSize / 2.0) as int;
    top += nudge;
    left += nudge;

    // But careful that this does not sample off the edge
    // "right" is the farthest-right valid pixel location -- right+1 is not necessarily
    // This is positive by how much the inner x loop below would be too large
    int nudgedTooFarRight = left + ((matrixWidth - 1) * moduleSize).toInt() - right;
    if (nudgedTooFarRight > 0) {
      if (nudgedTooFarRight > nudge) {
        // Neither way fits; abort
        throw Exception();
      }
      left -= nudgedTooFarRight;
    }
    // See logic above
    int nudgedTooFarDown = top + ((matrixHeight - 1) * moduleSize).toInt() - bottom;
    if (nudgedTooFarDown > 0) {
      if (nudgedTooFarDown > nudge) {
        // Neither way fits; abort
        throw Exception();
      }
      top -= nudgedTooFarDown;
    }

    // Now just read off the bits
    BitMatrix bits = new BitMatrix(matrixWidth, matrixHeight);
    for (int y = 0; y < matrixHeight; y++) {
      int iOffset = top + (y * moduleSize).toInt();
      for (int x = 0; x < matrixWidth; x++) {
        if (image.get(left + (x * moduleSize).toInt(), iOffset)) {
          bits.set(x, y);
        }
      }
    }
    return bits;
  }

  static double _moduleSize(List<int> leftTopBlack, BitMatrix image) {
    int height = image.getHeight();
    int width = image.getWidth();
    int x = leftTopBlack[0];
    int y = leftTopBlack[1];
    bool inBlack = true;
    int transitions = 0;
    while (x < width && y < height) {
      if (inBlack != image.get(x, y)) {
        if (++transitions == 5) {
          break;
        }
        inBlack = !inBlack;
      }
      x++;
      y++;
    }
    if (x == width || y == height) {
      throw Exception();
    }
    return (x - leftTopBlack[0]) / 7.0;
  }

}
