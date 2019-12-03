/*
 * Copyright 2013 ZXing authors
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

import 'LuminanceSource.dart';

/**
 * A wrapper implementation of {@link LuminanceSource} which inverts the luminances it returns -- black becomes
 * white and vice versa, and each value becomes (255-value).
 *
 * @author Sean Owen
 */
class InvertedLuminanceSource extends LuminanceSource {
  final LuminanceSource _delegate;

  InvertedLuminanceSource(this._delegate)
      : super(_delegate.getWidth(), _delegate.getHeight());

  @override
  Uint8ClampedList getRow(int y, Uint8ClampedList row) {
    row = this._delegate.getRow(y, row);
    int width = getWidth();
    for (int i = 0; i < width; i++) {
      row[i] = (255 - (row[i] & 0xFF));
    }
    return row;
  }

  @override
  Uint8ClampedList getMatrix() {
    Uint8ClampedList matrix = this._delegate.getMatrix();
    int length = getWidth() * getHeight();
    Uint8ClampedList invertedMatrix = new Uint8ClampedList(length);
    for (int i = 0; i < length; i++) {
      invertedMatrix[i] = (255 - (matrix[i] & 0xFF));
    }
    return invertedMatrix;
  }

  @override
  bool isCropSupported() {
    return this._delegate.isCropSupported();
  }

  @override
  LuminanceSource crop(int left, int top, int width, int height) {
    return new InvertedLuminanceSource(this._delegate.crop(left, top, width, height));
  }

  @override
  bool isRotateSupported() {
    return this._delegate.isRotateSupported();
  }

  /**
   * @return original delegate {@link LuminanceSource} since invert undoes itself
   */
  @override
  LuminanceSource invert() {
    return this._delegate;
  }

  @override
  LuminanceSource rotateCounterClockwise() {
    return new InvertedLuminanceSource(this._delegate.rotateCounterClockwise());
  }

  @override
  LuminanceSource rotateCounterClockwise45() {
    return new InvertedLuminanceSource(this._delegate.rotateCounterClockwise45());
  }
}
