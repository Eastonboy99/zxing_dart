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

import 'BarcodeFormat.dart';
import 'ResultPoint.dart';
import 'ResultMetadataType.dart';

/**
 * <p>Encapsulates the result of decoding a barcode within an image.</p>
 *
 * @author Sean Owen
 */
class Result {
  final String _text;
  final Uint8List _rawBytes;
  int _numBits;
  List<ResultPoint> _resultPoints;
  final BarcodeFormat _format;
  Map<ResultMetadataType, Object> _resultMetadata;
  int timestamp;

  Result(this._text, this._rawBytes, this._resultPoints, this._format,
      {this.timestamp}) {
    this._numBits = this._rawBytes == null ? 0 : 8 * this._rawBytes.length;
    this._resultMetadata = null;
    this.timestamp = this.timestamp == null ? getTimestamp() : this.timestamp;
  }

  /**
   * @return raw text encoded by the barcode
   */
  String getText() {
    return this._text;
  }

  /**
   * @return raw bytes encoded by the barcode, if applicable, otherwise
   *         {@code null}
   */
  Uint8List getRawBytes() {
    return this._rawBytes;
  }

  /**
   * @return how many bits of {@link #getRawBytes()} are valid; typically 8 times
   *         its length
   * @since 3.3.0
   */
  int getNumBits() {
    return this._numBits;
  }

  /**
   * @return points related to the barcode in the image. These are typically
   *         points identifying finder patterns or the corners of the barcode. The
   *         exact meaning is specific to the type of barcode that was decoded.
   */
  List<ResultPoint> getResultPoints() {
    return this._resultPoints;
  }

  /**
   * @return {@link BarcodeFormat} representing the format of the barcode that was
   *         decoded
   */
  BarcodeFormat getBarcodeFormat() {
    return this._format;
  }

  /**
   * @return {@link Map} mapping {@link ResultMetadataType} keys to values. May be
   *         {@code null}. This contains optional metadata about what was detected
   *         about the barcode, like orientation.
   */
  Map<ResultMetadataType, Object> getResultMetadata() {
    return this._resultMetadata;
  }

  void putMetadata(ResultMetadataType type, Object value) {
    if (this._resultMetadata == null) {
      this._resultMetadata = new Map<ResultMetadataType, Object>();
    }
    this._resultMetadata.putIfAbsent(type, value);
  }

  void putAllMetadata(Map<ResultMetadataType, Object> metadata) {
    if (metadata != null) {
      if (this._resultMetadata == null) {
        this._resultMetadata = metadata;
      } else {
        this._resultMetadata.addAll(metadata);
      }
    }
  }

  void addResultPoints(List<ResultPoint> newPoints) {
    List<ResultPoint> oldPoints = this._resultPoints;
    if (oldPoints == null) {
      this._resultPoints = newPoints;
    } else if (newPoints != null && newPoints.length > 0) {
      List<ResultPoint> allPoints =
          new List<ResultPoint>(oldPoints.length + newPoints.length);
      allPoints.addAll(oldPoints);
      allPoints.addAll(newPoints);
      this._resultPoints = allPoints;
    }
  }

  int getTimestamp() {
    return this.timestamp;
  }

  @override
  String toString() {
    return this._text;
  }
}
