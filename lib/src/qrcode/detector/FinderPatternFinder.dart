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


import '../../DecodeHintType.dart';
import '../../ResultPoint.dart';
import '../../ResultPointCallback.dart';
import '../../common/BitMatrix.dart';
import 'FinderPattern.dart';
import 'FinderPatternInfo.dart';

// import com.google.zxing.NotFoundException;


/**
 * <p>This class attempts to find finder patterns in a QR Code. Finder patterns are the square
 * markers at three corners of a QR Code.</p>
 *
 * <p>This class is thread-safe but not reentrant. Each thread must allocate its own object.
 *
 * @author Sean Owen
 */
class FinderPatternFinder {

  static final int _CENTER_QUORUM = 2;
  static final EstimatedModuleComparator _moduleComparator = new EstimatedModuleComparator();
  static final int _MIN_SKIP = 3; // 1 pixel/module times 3 modules/center
  static final int _MAX_MODULES = 97; // support up to version 20 for mobile clients

  BitMatrix _image;
  List<FinderPattern> _possibleCenters;
  bool _hasSkipped = false;
  List<int> _crossCheckStateCount;
  ResultPointCallback _resultPointCallback;

  /**
   * <p>Creates a finder that will search the image for three finder patterns.</p>
   *
   * @param image image to search
   */

  FinderPatternFinder(BitMatrix image, [ResultPointCallback resultPointCallback]) {
    this._image = image;
    this._possibleCenters = new List();
    this._crossCheckStateCount = new List<int>(5);
    this._resultPointCallback = resultPointCallback;
  }

  BitMatrix getImage() {
    return _image;
  }

  List<FinderPattern> getPossibleCenters() {
    return _possibleCenters;
  }

  FinderPatternInfo find(Map<DecodeHintType,Object> hints) {
    bool tryHarder = hints != null && hints.containsKey(DecodeHintType.TRY_HARDER);
    int maxI = _image.getHeight();
    int maxJ = _image.getWidth();
    // We are looking for black/white/black/white/black modules in
    // 1:1:3:1:1 ratio; this tracks the number of such modules seen so far

    // Let's assume that the maximum version QR Code we support takes up 1/4 the height of the
    // image, and then account for the center being 3 modules in size. This gives the smallest
    // number of pixels the center could be, so skip this often. When trying harder, look for all
    // QR versions regardless of how dense they are.
    int iSkip = (3 * maxI) ~/ (4 * _MAX_MODULES);
    if (iSkip < _MIN_SKIP || tryHarder) {
      iSkip = _MIN_SKIP;
    }

    bool done = false;
    List<int> stateCount = new List<int>(5);
    for (int i = iSkip - 1; i < maxI && !done; i += iSkip) {
      // Get a row of black/white values
      clearCounts(stateCount);
      int currentState = 0;
      for (int j = 0; j < maxJ; j++) {
        if (_image.get(j, i)) {
          // Black pixel
          if ((currentState & 1) == 1) { // Counting white pixels
            currentState++;
          }
          stateCount[currentState]++;
        } else { // White pixel
          if ((currentState & 1) == 0) { // Counting black pixels
            if (currentState == 4) { // A winner?
              if (foundPatternCross(stateCount)) { // Yes
                bool confirmed = handlePossibleCenter(stateCount, i, j);
                if (confirmed) {
                  // Start examining every other line. Checking each line turned out to be too
                  // expensive and didn't improve performance.
                  iSkip = 2;
                  if (_hasSkipped) {
                    done = _haveMultiplyConfirmedCenters();
                  } else {
                    int rowSkip = _findRowSkip();
                    if (rowSkip > stateCount[2]) {
                      // Skip rows between row of lower confirmed center
                      // and top of presumed third confirmed center
                      // but back up a bit to get a full chance of detecting
                      // it, entire width of center of finder pattern

                      // Skip by rowSkip, but back off by stateCount[2] (size of last center
                      // of pattern we saw) to be conservative, and also back off by iSkip which
                      // is about to be re-added
                      i += rowSkip - stateCount[2] - iSkip;
                      j = maxJ - 1;
                    }
                  }
                } else {
                  shiftCounts2(stateCount);
                  currentState = 3;
                  continue;
                }
                // Clear state to start looking again
                currentState = 0;
                clearCounts(stateCount);
              } else { // No, shift counts back by two
                shiftCounts2(stateCount);
                currentState = 3;
              }
            } else {
              stateCount[++currentState]++;
            }
          } else { // Counting white pixels
            stateCount[currentState]++;
          }
        }
      }
      if (foundPatternCross(stateCount)) {
        bool confirmed = handlePossibleCenter(stateCount, i, maxJ);
        if (confirmed) {
          iSkip = stateCount[0];
          if (_hasSkipped) {
            // Found a third one
            done = _haveMultiplyConfirmedCenters();
          }
        }
      }
    }

    List<FinderPattern> patternInfo = _selectBestPatterns();
    ResultPoint.orderBestPatterns(patternInfo);

    return new FinderPatternInfo(patternInfo);
  }

  /**
   * Given a count of black/white/black/white/black pixels just seen and an end position,
   * figures the location of the center of this run.
   */
  static double _centerFromEnd(List<int> stateCount, int end) {
    return (end - stateCount[4] - stateCount[3]) - stateCount[2] / 2.0;
  }

  /**
   * @param stateCount count of black/white/black/white/black pixels just read
   * @return true iff the proportions of the counts is close enough to the 1/1/3/1/1 ratios
   *         used by finder patterns to be considered a match
   */
  static bool foundPatternCross(List<int> stateCount) {
    int totalModuleSize = 0;
    for (int i = 0; i < 5; i++) {
      int count = stateCount[i];
      if (count == 0) {
        return false;
      }
      totalModuleSize += count;
    }
    if (totalModuleSize < 7) {
      return false;
    }
    double moduleSize = totalModuleSize / 7.0;
    double maxVariance = moduleSize / 2.0;
    // Allow less than 50% variance from 1-1-3-1-1 proportions
    return
        (moduleSize - stateCount[0]).abs() < maxVariance &&
        (moduleSize - stateCount[1]).abs() < maxVariance &&
        (3.0 * moduleSize - stateCount[2]).abs() < 3 * maxVariance &&
        (moduleSize - stateCount[3]).abs() < maxVariance &&
        (moduleSize - stateCount[4]).abs() < maxVariance;
  }

  /**
   * @param stateCount count of black/white/black/white/black pixels just read
   * @return true iff the proportions of the counts is close enough to the 1/1/3/1/1 ratios
   *         used by finder patterns to be considered a match
   */
  static bool foundPatternDiagonal(List<int> stateCount) {
    int totalModuleSize = 0;
    for (int i = 0; i < 5; i++) {
      int count = stateCount[i];
      if (count == 0) {
        return false;
      }
      totalModuleSize += count;
    }
    if (totalModuleSize < 7) {
      return false;
    }
    double moduleSize = totalModuleSize / 7.0;
    double maxVariance = moduleSize / 1.333;
    // Allow less than 75% variance from 1-1-3-1-1 proportions
    return
            (moduleSize - stateCount[0]).abs() < maxVariance &&
                    (moduleSize - stateCount[1]).abs() < maxVariance &&
                    (3.0 * moduleSize - stateCount[2]).abs() < 3 * maxVariance &&
                    (moduleSize - stateCount[3]).abs() < maxVariance &&
                    (moduleSize - stateCount[4]).abs() < maxVariance;
  }

  List<int> _getCrossCheckStateCount() {
    clearCounts(_crossCheckStateCount);
    return _crossCheckStateCount;
  }

  void clearCounts(List<int> counts) {
    counts.fillRange(0, counts.length, 0);
  }

  void shiftCounts2(List<int> stateCount) {
    stateCount[0] = stateCount[2];
    stateCount[1] = stateCount[3];
    stateCount[2] = stateCount[4];
    stateCount[3] = 1;
    stateCount[4] = 0;
  }

  /**
   * After a vertical and horizontal scan finds a potential finder pattern, this method
   * "cross-cross-cross-checks" by scanning down diagonally through the center of the possible
   * finder pattern to see if the same proportion is detected.
   *
   * @param centerI row where a finder pattern was detected
   * @param centerJ center of the section that appears to cross a finder pattern
   * @return true if proportions are withing expected limits
   */
  bool _crossCheckDiagonal(int centerI, int centerJ) {
    List<int> stateCount = _getCrossCheckStateCount();

    // Start counting up, left from center finding black center mass
    int i = 0;
    while (centerI >= i && centerJ >= i && _image.get(centerJ - i, centerI - i)) {
      stateCount[2]++;
      i++;
    }
    if (stateCount[2] == 0) {
      return false;
    }

    // Continue up, left finding white space
    while (centerI >= i && centerJ >= i && !_image.get(centerJ - i, centerI - i)) {
      stateCount[1]++;
      i++;
    }
    if (stateCount[1] == 0) {
      return false;
    }

    // Continue up, left finding black border
    while (centerI >= i && centerJ >= i && _image.get(centerJ - i, centerI - i)) {
      stateCount[0]++;
      i++;
    }
    if (stateCount[0] == 0) {
      return false;
    }

    int maxI = _image.getHeight();
    int maxJ = _image.getWidth();

    // Now also count down, right from center
    i = 1;
    while (centerI + i < maxI && centerJ + i < maxJ && _image.get(centerJ + i, centerI + i)) {
      stateCount[2]++;
      i++;
    }

    while (centerI + i < maxI && centerJ + i < maxJ && !_image.get(centerJ + i, centerI + i)) {
      stateCount[3]++;
      i++;
    }
    if (stateCount[3] == 0) {
      return false;
    }

    while (centerI + i < maxI && centerJ + i < maxJ && _image.get(centerJ + i, centerI + i)) {
      stateCount[4]++;
      i++;
    }
    if (stateCount[4] == 0) {
      return false;
    }

    return foundPatternDiagonal(stateCount);
  }

  /**
   * <p>After a horizontal scan finds a potential finder pattern, this method
   * "cross-checks" by scanning down vertically through the center of the possible
   * finder pattern to see if the same proportion is detected.</p>
   *
   * @param startI row where a finder pattern was detected
   * @param centerJ center of the section that appears to cross a finder pattern
   * @param maxCount maximum reasonable number of modules that should be
   * observed in any reading state, based on the results of the horizontal scan
   * @return vertical center of finder pattern, or {@link Float#NaN} if not found
   */
  double _crossCheckVertical(int startI, int centerJ, int maxCount,
      int originalStateCountTotal) {
    BitMatrix image = this._image;

    int maxI = image.getHeight();
    List<int> stateCount = _getCrossCheckStateCount();

    // Start counting up from center
    int i = startI;
    while (i >= 0 && image.get(centerJ, i)) {
      stateCount[2]++;
      i--;
    }
    if (i < 0) {
      return double.nan;
    }
    while (i >= 0 && !image.get(centerJ, i) && stateCount[1] <= maxCount) {
      stateCount[1]++;
      i--;
    }
    // If already too many modules in this state or ran off the edge:
    if (i < 0 || stateCount[1] > maxCount) {
      return double.nan;
    }
    while (i >= 0 && image.get(centerJ, i) && stateCount[0] <= maxCount) {
      stateCount[0]++;
      i--;
    }
    if (stateCount[0] > maxCount) {
      return double.nan;
    }

    // Now also count down from center
    i = startI + 1;
    while (i < maxI && image.get(centerJ, i)) {
      stateCount[2]++;
      i++;
    }
    if (i == maxI) {
      return double.nan;
    }
    while (i < maxI && !image.get(centerJ, i) && stateCount[3] < maxCount) {
      stateCount[3]++;
      i++;
    }
    if (i == maxI || stateCount[3] >= maxCount) {
      return double.nan;
    }
    while (i < maxI && image.get(centerJ, i) && stateCount[4] < maxCount) {
      stateCount[4]++;
      i++;
    }
    if (stateCount[4] >= maxCount) {
      return double.nan;
    }

    // If we found a finder-pattern-like section, but its size is more than 40% different than
    // the original, assume it's a false positive
    int stateCountTotal = stateCount[0] + stateCount[1] + stateCount[2] + stateCount[3] +
        stateCount[4];
    if (5 * (stateCountTotal - originalStateCountTotal).abs() >= 2 * originalStateCountTotal) {
      return double.nan;
    }

    return foundPatternCross(stateCount) ? _centerFromEnd(stateCount, i) : double.nan;
  }

  /**
   * <p>Like {@link #crossCheckVertical(int, int, int, int)}, and in fact is basically identical,
   * except it reads horizontally instead of vertically. This is used to cross-cross
   * check a vertical cross check and locate the real center of the alignment pattern.</p>
   */
  double _crossCheckHorizontal(int startJ, int centerI, int maxCount,
      int originalStateCountTotal) {
    BitMatrix image = this._image;

    int maxJ = image.getWidth();
    List<int> stateCount = _getCrossCheckStateCount();

    int j = startJ;
    while (j >= 0 && image.get(j, centerI)) {
      stateCount[2]++;
      j--;
    }
    if (j < 0) {
      return double.nan;
    }
    while (j >= 0 && !image.get(j, centerI) && stateCount[1] <= maxCount) {
      stateCount[1]++;
      j--;
    }
    if (j < 0 || stateCount[1] > maxCount) {
      return double.nan;
    }
    while (j >= 0 && image.get(j, centerI) && stateCount[0] <= maxCount) {
      stateCount[0]++;
      j--;
    }
    if (stateCount[0] > maxCount) {
      return double.nan;
    }

    j = startJ + 1;
    while (j < maxJ && image.get(j, centerI)) {
      stateCount[2]++;
      j++;
    }
    if (j == maxJ) {
      return double.nan;
    }
    while (j < maxJ && !image.get(j, centerI) && stateCount[3] < maxCount) {
      stateCount[3]++;
      j++;
    }
    if (j == maxJ || stateCount[3] >= maxCount) {
      return double.nan;
    }
    while (j < maxJ && image.get(j, centerI) && stateCount[4] < maxCount) {
      stateCount[4]++;
      j++;
    }
    if (stateCount[4] >= maxCount) {
      return double.nan;
    }

    // If we found a finder-pattern-like section, but its size is significantly different than
    // the original, assume it's a false positive
    int stateCountTotal = stateCount[0] + stateCount[1] + stateCount[2] + stateCount[3] +
        stateCount[4];
    if (5 * (stateCountTotal - originalStateCountTotal).abs() >= originalStateCountTotal) {
      return double.nan;
    }

    return foundPatternCross(stateCount) ? _centerFromEnd(stateCount, j) : double.nan;
  }

  // /**
  //  * @param stateCount reading state module counts from horizontal scan
  //  * @param i row where finder pattern may be found
  //  * @param j end of possible finder pattern in row
  //  * @param pureBarcode ignored
  //  * @return true if a finder pattern candidate was found this time
  //  * @deprecated only exists for backwards compatibility
  //  * @see #handlePossibleCenter(int[], int, int)
  //  */
  // @deprecated
  // bool handlePossibleCenter(List<int> stateCount, int i, int j, bool pureBarcode) {
  //   return handlePossibleCenter(stateCount, i, j);
  // }

  /**
   * <p>This is called when a horizontal scan finds a possible alignment pattern. It will
   * cross check with a vertical scan, and if successful, will, ah, cross-cross-check
   * with another horizontal scan. This is needed primarily to locate the real horizontal
   * center of the pattern in cases of extreme skew.
   * And then we cross-cross-cross check with another diagonal scan.</p>
   *
   * <p>If that succeeds the finder pattern location is added to a list that tracks
   * the number of times each location has been nearly-matched as a finder pattern.
   * Each additional find is more evidence that the location is in fact a finder
   * pattern center
   *
   * @param stateCount reading state module counts from horizontal scan
   * @param i row where finder pattern may be found
   * @param j end of possible finder pattern in row
   * @return true if a finder pattern candidate was found this time
   */
  bool handlePossibleCenter(List<int> stateCount, int i, int j, [bool pureBarcode]) {
    int stateCountTotal = stateCount[0] + stateCount[1] + stateCount[2] + stateCount[3] +
        stateCount[4];
    double centerJ = _centerFromEnd(stateCount, j);
    double centerI = _crossCheckVertical(i, centerJ.toInt(), stateCount[2], stateCountTotal);
    if (!(centerI).isNaN) {
      // Re-cross check
      centerJ = _crossCheckHorizontal(centerJ.toInt(), centerI.toInt(), stateCount[2], stateCountTotal);
      if (!(centerJ).isNaN && _crossCheckDiagonal(centerI.toInt(), centerJ.toInt())) {
        double estimatedModuleSize = stateCountTotal / 7.0;
        bool found = false;
        for (int index = 0; index < _possibleCenters.length; index++) {
          FinderPattern center = _possibleCenters[index];
          // Look for about the same center and module size:
          if (center.aboutEquals(estimatedModuleSize, centerI, centerJ)) {
            _possibleCenters[index] = center.combineEstimate(centerI, centerJ, estimatedModuleSize);
            found = true;
            break;
          }
        }
        if (!found) {
          FinderPattern point = new FinderPattern(centerJ, centerI, estimatedModuleSize);
          _possibleCenters.add(point);
          if (_resultPointCallback != null) {
            _resultPointCallback.foundPossibleResultPoint(point);
          }
        }
        return true;
      }
    }
    return false;
  }

  /**
   * @return number of rows we could safely skip during scanning, based on the first
   *         two finder patterns that have been located. In some cases their position will
   *         allow us to infer that the third pattern must lie below a certain point farther
   *         down in the image.
   */
  int _findRowSkip() {
    int max = _possibleCenters.length;
    if (max <= 1) {
      return 0;
    }
    ResultPoint firstConfirmedCenter = null;
    for (FinderPattern center in _possibleCenters) {
      if (center.getCount() >= _CENTER_QUORUM) {
        if (firstConfirmedCenter == null) {
          firstConfirmedCenter = center;
        } else {
          // We have two confirmed centers
          // How far down can we skip before resuming looking for the next
          // pattern? In the worst case, only the difference between the
          // difference in the x / y coordinates of the two centers.
          // This is the case where you find top left last.
          _hasSkipped = true;
          return ((firstConfirmedCenter.getX() - center.getX()).abs() - (firstConfirmedCenter.getY() - center.getY()).abs()).toInt() ~/ 2;
        }
      }
    }
    return 0;
  }

  /**
   * @return true iff we have found at least 3 finder patterns that have been detected
   *         at least {@link #CENTER_QUORUM} times each, and, the estimated module size of the
   *         candidates is "pretty similar"
   */
  bool _haveMultiplyConfirmedCenters() {
    int confirmedCount = 0;
    double totalModuleSize = 0.0;
    int max = _possibleCenters.length;
    for (FinderPattern pattern in _possibleCenters) {
      if (pattern.getCount() >= _CENTER_QUORUM) {
        confirmedCount++;
        totalModuleSize += pattern.getEstimatedModuleSize();
      }
    }
    if (confirmedCount < 3) {
      return false;
    }
    // OK, we have at least 3 confirmed centers, but, it's possible that one is a "false positive"
    // and that we need to keep looking. We detect this by asking if the estimated module sizes
    // vary too much. We arbitrarily say that when the total deviation from average exceeds
    // 5% of the total module size estimates, it's too much.
    double average = totalModuleSize / max;
    double totalDeviation = 0.0;
    for (FinderPattern pattern in _possibleCenters) {
      totalDeviation += (pattern.getEstimatedModuleSize() - average).abs();
    }
    return totalDeviation <= 0.05 * totalModuleSize;
  }

  /**
   * Get square of distance between a and b.
   */
  static double _squaredDistance(FinderPattern a, FinderPattern b) {
    double x = a.getX() - b.getX();
    double y = a.getY() - b.getY();
    return x * x + y * y;
  }

  /**
   * @return the 3 best {@link FinderPattern}s from our list of candidates. The "best" are
   *         those have similar module size and form a shape closer to a isosceles right triangle.
   * @throws NotFoundException if 3 such finder patterns do not exist
   */
  List<FinderPattern> _selectBestPatterns() {

    int startSize = _possibleCenters.length;
    if (startSize < 3) {
      // Couldn't find enough finder patterns
      throw Exception("Not Found Exception");
    }

    _possibleCenters.sort(_moduleComparator.compare);

    double distortion = double.maxFinite;
    List<double> squares = new List<double>(3);
    List<FinderPattern> bestPatterns = new List<FinderPattern>(3);

    for (int i = 0; i < _possibleCenters.length - 2; i++) {
      FinderPattern fpi = _possibleCenters[i];
      double minModuleSize = fpi.getEstimatedModuleSize();

      for (int j = i + 1; j < _possibleCenters.length - 1; j++) {
        FinderPattern fpj = _possibleCenters[j];
        double squares0 = _squaredDistance(fpi, fpj);

        for (int k = j + 1; k < _possibleCenters.length; k++) {
          FinderPattern fpk = _possibleCenters[k];
          double maxModuleSize = fpk.getEstimatedModuleSize();
          if (maxModuleSize > minModuleSize * 1.4) {
            // module size is not similar
            continue;
          }

          squares[0] = squares0;
          squares[1] = _squaredDistance(fpj, fpk);
          squares[2] = _squaredDistance(fpi, fpk);
          squares.sort();

          // a^2 + b^2 = c^2 (Pythagorean theorem), and a = b (isosceles triangle).
          // Since any right triangle satisfies the formula c^2 - b^2 - a^2 = 0,
          // we need to check both two equal sides separately.
          // The value of |c^2 - 2 * b^2| + |c^2 - 2 * a^2| increases as dissimilarity
          // from isosceles right triangle.
          double d = (squares[2] - 2 * squares[1]).abs() + (squares[2] - 2 * squares[0]).abs();
          if (d < distortion) {
            distortion = d;
            bestPatterns[0] = fpi;
            bestPatterns[1] = fpj;
            bestPatterns[2] = fpk;
          }
        }
      }
    }

    if (distortion == double.maxFinite) {
        throw Exception("Not Found Exception");
    }

    return bestPatterns;
  }

}

  /**
   * <p>Orders by {@link FinderPattern#getEstimatedModuleSize()}</p>
   */
  class EstimatedModuleComparator {
    
    int compare(FinderPattern center1, FinderPattern center2) {
      return center1.getEstimatedModuleSize().compareTo(center2.getEstimatedModuleSize());
    }
  }