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

import 'FinderPattern.dart';

package com.google.zxing.qrcode.detector;

/**
 * <p>Encapsulates information about finder patterns in an image, including the location of
 * the three finder patterns, and their estimated module size.</p>
 *
 * @author Sean Owen
 */
class FinderPatternInfo {

  FinderPattern _bottomLeft;
  FinderPattern _topLeft;
  FinderPattern _topRight;

  FinderPatternInfo(List<FinderPattern> patternCenters) {
    this._bottomLeft = patternCenters[0];
    this._topLeft = patternCenters[1];
    this._topRight = patternCenters[2];
  }

  FinderPattern getBottomLeft() {
    return _bottomLeft;
  }

  FinderPattern getTopLeft() {
    return _topLeft;
  }

  FinderPattern getTopRight() {
    return _topRight;
  }

}
