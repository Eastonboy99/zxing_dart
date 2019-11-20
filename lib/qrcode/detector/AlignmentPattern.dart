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

import '../../ResultPoint.dart';

/**
 * <p>Encapsulates an alignment pattern, which are the smaller square patterns found in
 * all but the simplest QR Codes.</p>
 *
 * @author Sean Owen
 */
class AlignmentPattern extends ResultPoint {

  final double estimatedModuleSize;

  AlignmentPattern(double posX, double posY, this.estimatedModuleSize) : super(posX, posY);

  /**
   * <p>Determines if this alignment pattern "about equals" an alignment pattern at the stated
   * position and size -- meaning, it is at nearly the same center with nearly the same size.</p>
   */
  bool aboutEquals(double moduleSize, double i, double j) {
    if ((i - getY()).abs() <= moduleSize && (j - getX()).abs() <= moduleSize) {
      double moduleSizeDiff = (moduleSize - estimatedModuleSize).abs();
      return moduleSizeDiff <= 1.0 || moduleSizeDiff <= estimatedModuleSize;
    }
    return false;
  }

  /**
   * Combines this object's current estimate of a finder pattern position and module size
   * with a new estimate. It returns a new {@code FinderPattern} containing an average of the two.
   */
  AlignmentPattern combineEstimate(double i, double j, double newModuleSize) {
    double combinedX = (getX() + j) / 2.0;
    double combinedY = (getY() + i) / 2.0;
    double combinedModuleSize = (estimatedModuleSize + newModuleSize) / 2.0;
    return new AlignmentPattern(combinedX, combinedY, combinedModuleSize);
  }

}