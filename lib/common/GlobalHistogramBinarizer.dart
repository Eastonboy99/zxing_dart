/*
 * Copyright 2009 ZXing authors
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

import '../Binarizer.dart';
import '../LuminanceSource.dart';
import 'BitArray.dart';
import 'BitMatrix.dart';

// import com.google.zxing.NotFoundException;

/**
 * This Binarizer implementation uses the old ZXing global histogram approach. It is suitable
 * for low-end mobile devices which don't have enough CPU or memory to use a local thresholding
 * algorithm. However, because it picks a global black point, it cannot handle difficult shadows
 * and gradients.
 *
 * Faster mobile devices and all desktop applications should probably use HybridBinarizer instead.
 *
 * @author dswitkin@google.com (Daniel Switkin)
 * @author Sean Owen
 */
class GlobalHistogramBinarizer extends Binarizer {

  static final int _LUMINANCE_BITS = 5;
  static final int _LUMINANCE_SHIFT = 8 - _LUMINANCE_BITS;
  static final int _LUMINANCE_BUCKETS = 1 << _LUMINANCE_BITS;
  static final Uint8ClampedList _EMPTY = new Uint8ClampedList(0);

  Uint8ClampedList _luminances;
  List<int> _buckets;

   GlobalHistogramBinarizer(LuminanceSource source): super(source) {
    _luminances = _EMPTY;
    _buckets = new List<int>(_LUMINANCE_BUCKETS);
  }

  // Applies simple sharpening to the row data to improve performance of the 1D Readers.
  @override
  BitArray getBlackRow(int y, BitArray row){
    LuminanceSource source = getLuminanceSource();
    int width = source.getWidth();
    if (row == null || row.getSize() < width) {
      row = new BitArray(width);
    } else {
      row.clear();
    }

    _initArrays(width);
    Uint8ClampedList localLuminances = source.getRow(y, _luminances);
    List<int> localBuckets = _buckets;
    for (int x = 0; x < width; x++) {
      localBuckets[(localLuminances[x] & 0xff) >> _LUMINANCE_SHIFT]++;
    }
    int blackPoint = _estimateBlackPoint(localBuckets);

    if (width < 3) {
      // Special case for very small images
      for (int x = 0; x < width; x++) {
        if ((localLuminances[x] & 0xff) < blackPoint) {
          row.set(x);
        }
      }
    } else {
      int left = localLuminances[0] & 0xff;
      int center = localLuminances[1] & 0xff;
      for (int x = 1; x < width - 1; x++) {
        int right = localLuminances[x + 1] & 0xff;
        // A simple -1 4 -1 box filter with a weight of 2.
        if (((center * 4) - left - right) / 2 < blackPoint) {
          row.set(x);
        }
        left = center;
        center = right;
      }
    }
    return row;
  }

  // Does not sharpen the data, as this call is intended to only be used by 2D Readers.
  @override
  BitMatrix getBlackMatrix() {
    LuminanceSource source = getLuminanceSource();
    int width = source.getWidth();
    int height = source.getHeight();
    BitMatrix matrix = new BitMatrix(width, height);

    // Quickly calculates the histogram by sampling four rows from the image. This proved to be
    // more robust on the blackbox tests than sampling a diagonal as we used to do.
    _initArrays(width);
    List<int> localBuckets = _buckets;
    for (int y = 1; y < 5; y++) {
      int row = height * y ~/ 5;
      Uint8ClampedList localLuminances = source.getRow(row, _luminances);
      int right = (width * 4) ~/ 5;
      for (int x = width ~/ 5; x < right; x++) {
        int pixel = localLuminances[x] & 0xff;
        localBuckets[pixel >> _LUMINANCE_SHIFT]++;
      }
    }
    int blackPoint = _estimateBlackPoint(localBuckets);

    // We delay reading the entire image luminance until the black point estimation succeeds.
    // Although we end up reading four rows twice, it is consistent with our motto of
    // "fail quickly" which is necessary for continuous scanning.
    Uint8ClampedList localLuminances = source.getMatrix();
    for (int y = 0; y < height; y++) {
      int offset = y * width;
      for (int x = 0; x < width; x++) {
        int pixel = localLuminances[offset + x] & 0xff;
        if (pixel < blackPoint) {
          matrix.set(x, y);
        }
      }
    }

    return matrix;
  }

  @override
  Binarizer createBinarizer(LuminanceSource source) {
    return new GlobalHistogramBinarizer(source);
  }

  void _initArrays(int luminanceSize) {
    if (_luminances.length < luminanceSize) {
      _luminances = new Uint8ClampedList(luminanceSize);
    }
    for (int x = 0; x < _LUMINANCE_BUCKETS; x++) {
      _buckets[x] = 0;
    }
  }

  static int _estimateBlackPoint(List<int> buckets) {
    // Find the tallest peak in the histogram.
    int numBuckets = buckets.length;
    int maxBucketCount = 0;
    int firstPeak = 0;
    int firstPeakSize = 0;
    for (int x = 0; x < numBuckets; x++) {
      if (buckets[x] > firstPeakSize) {
        firstPeak = x;
        firstPeakSize = buckets[x];
      }
      if (buckets[x] > maxBucketCount) {
        maxBucketCount = buckets[x];
      }
    }

    // Find the second-tallest peak which is somewhat far from the tallest peak.
    int secondPeak = 0;
    int secondPeakScore = 0;
    for (int x = 0; x < numBuckets; x++) {
      int distanceToBiggest = x - firstPeak;
      // Encourage more distant second peaks by multiplying by square of distance.
      int score = buckets[x] * distanceToBiggest * distanceToBiggest;
      if (score > secondPeakScore) {
        secondPeak = x;
        secondPeakScore = score;
      }
    }

    // Make sure firstPeak corresponds to the black peak.
    if (firstPeak > secondPeak) {
      int temp = firstPeak;
      firstPeak = secondPeak;
      secondPeak = temp;
    }

    // If there is too little contrast in the image to pick a meaningful black point, throw rather
    // than waste time trying to decode the image, and risk false positives.
    if (secondPeak - firstPeak <= numBuckets / 16) {
      throw Exception("Not Found Exception");
    }

    // Find a valley between them that is low and closer to the white peak.
    int bestValley = secondPeak - 1;
    int bestValleyScore = -1;
    for (int x = secondPeak - 1; x > firstPeak; x--) {
      int fromFirst = x - firstPeak;
      int score = fromFirst * fromFirst * (secondPeak - x) * (maxBucketCount - buckets[x]);
      if (score > bestValleyScore) {
        bestValley = x;
        bestValleyScore = score;
      }
    }

    return bestValley << _LUMINANCE_SHIFT;
  }

}