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

import './GenericGF.dart';
import 'GenericGFPoly.dart';

/**
 * <p>Implements Reed-Solomon decoding, as the name implies.</p>
 *
 * <p>The algorithm will not be explained here, but the following references were helpful
 * in creating this implementation:</p>
 *
 * <ul>
 * <li>Bruce Maggs.
 * <a href="http://www.cs.cmu.edu/afs/cs.cmu.edu/project/pscico-guyb/realworld/www/rs_decode.ps">
 * "Decoding Reed-Solomon Codes"</a> (see discussion of Forney's Formula)</li>
 * <li>J.I. Hall. <a href="www.mth.msu.edu/~jhall/classes/codenotes/GRS.pdf">
 * "Chapter 5. Generalized Reed-Solomon Codes"</a>
 * (see discussion of Euclidean algorithm)</li>
 * </ul>
 *
 * <p>Much credit is due to William Rucklidge since portions of this code are an indirect
 * port of his C++ Reed-Solomon implementation.</p>
 *
 * @author Sean Owen
 * @author William Rucklidge
 * @author sanfordsquires
 */
class ReedSolomonDecoder {

  final GenericGF _field;

  ReedSolomonDecoder(this._field) {
  }

  /**
   * <p>Decodes given set of received codewords, which include both data and error-correction
   * codewords. Really, this means it uses Reed-Solomon to detect and correct errors, in-place,
   * in the input.</p>
   *
   * @param received data and error-correction codewords
   * @param twoS number of error-correction codewords available
   * @throws ReedSolomonException if decoding fails for any reason
   */
  void decode(List<int> received, int twoS) {
    GenericGFPoly poly = new GenericGFPoly(this._field, received);
    List<int> syndromeCoefficients = new List<int>(twoS);
    bool noError = true;
    for (int i = 0; i < twoS; i++) {
      int eval = poly.evaluateAt(this._field.exp(i + this._field.getGeneratorBase()));
      syndromeCoefficients[syndromeCoefficients.length - 1 - i] = eval;
      if (eval != 0) {
        noError = false;
      }
    }
    if (noError) {
      return;
    }
    GenericGFPoly syndrome = new GenericGFPoly(this._field, syndromeCoefficients);
    List<GenericGFPoly> sigmaOmega =
        _runEuclideanAlgorithm(this._field.buildMonomial(twoS, 1), syndrome, twoS);
    GenericGFPoly sigma = sigmaOmega[0];
    GenericGFPoly omega = sigmaOmega[1];
    List<int> errorLocations = _findErrorLocations(sigma);
    List<int> errorMagnitudes = _findErrorMagnitudes(omega, errorLocations);
    for (int i = 0; i < errorLocations.length; i++) {
      int position = received.length - 1 - this._field.log(errorLocations[i]);
      if (position < 0) {
        throw new Exception("Bad error location");
      }
      received[position] = GenericGF.addOrSubtract(received[position], errorMagnitudes[i]);
    }
  }

  List<GenericGFPoly> _runEuclideanAlgorithm(GenericGFPoly a, GenericGFPoly b, int R)
   {
    // Assume a's degree is >= b's
    if (a.getDegree() < b.getDegree()) {
      GenericGFPoly temp = a;
      a = b;
      b = temp;
    }

    GenericGFPoly rLast = a;
    GenericGFPoly r = b;
    GenericGFPoly tLast = this._field.getZero();
    GenericGFPoly t = this._field.getOne();

    // Run Euclidean algorithm until r's degree is less than R/2
    while (r.getDegree() >= R / 2) {
      GenericGFPoly rLastLast = rLast;
      GenericGFPoly tLastLast = tLast;
      rLast = r;
      tLast = t;

      // Divide rLastLast by rLast, with quotient in q and remainder in r
      if (rLast.isZero()) {
        // Oops, Euclidean algorithm already terminated?
        throw new Exception("r_{i-1} was zero");
      }
      r = rLastLast;
      GenericGFPoly q = this._field.getZero();
      int denominatorLeadingTerm = rLast.getCoefficient(rLast.getDegree());
      int dltInverse = this._field.inverse(denominatorLeadingTerm);
      while (r.getDegree() >= rLast.getDegree() && !r.isZero()) {
        int degreeDiff = r.getDegree() - rLast.getDegree();
        int scale = this._field.multiply(r.getCoefficient(r.getDegree()), dltInverse);
        q = q.addOrSubtract(this._field.buildMonomial(degreeDiff, scale));
        r = r.addOrSubtract(rLast.multiplyByMonomial(degreeDiff, scale));
      }

      t = q.multiply(other: tLast).addOrSubtract(tLastLast);

      if (r.getDegree() >= rLast.getDegree()) {
        throw new Exception("Division algorithm failed to reduce polynomial?");
      }
    }

    int sigmaTildeAtZero = t.getCoefficient(0);
    if (sigmaTildeAtZero == 0) {
      throw new Exception("sigmaTilde(0) was zero");
    }

    int inverse = this._field.inverse(sigmaTildeAtZero);
    GenericGFPoly sigma = t.multiply(scalar: inverse);
    GenericGFPoly omega = r.multiply(scalar: inverse);
    return new List.from({sigma, omega});
  }

  List<int> _findErrorLocations(GenericGFPoly errorLocator) {
    // This is a direct application of Chien's search
    int numErrors = errorLocator.getDegree();
    if (numErrors == 1) { // shortcut
      return new List.from({ errorLocator.getCoefficient(1) });
    }
    List<int> result = new List<int>(numErrors);
    int e = 0;
    for (int i = 1; i < this._field.getSize() && e < numErrors; i++) {
      if (errorLocator.evaluateAt(i) == 0) {
        result[e] = this._field.inverse(i);
        e++;
      }
    }
    if (e != numErrors) {
      throw new Exception("Error locator degree does not match number of roots");
    }
    return result;
  }

  List<int> _findErrorMagnitudes(GenericGFPoly errorEvaluator, List<int> errorLocations) {
    // This is directly applying Forney's Formula
    int s = errorLocations.length;
    List<int> result = new List<int>(s);
    for (int i = 0; i < s; i++) {
      int xiInverse = this._field.inverse(errorLocations[i]);
      int denominator = 1;
      for (int j = 0; j < s; j++) {
        if (i != j) {
          //denominator = field.multiply(denominator,
          //    GenericGF.addOrSubtract(1, field.multiply(errorLocations[j], xiInverse)));
          // Above should work but fails on some Apple and Linux JDKs due to a Hotspot bug.
          // Below is a funny-looking workaround from Steven Parkes
          int term = this._field.multiply(errorLocations[j], xiInverse);
          int termPlus1 = (term & 0x1) == 0 ? term | 1 : term & ~1;
          denominator = this._field.multiply(denominator, termPlus1);
        }
      }
      result[i] = this._field.multiply(errorEvaluator.evaluateAt(xiInverse),
          this._field.inverse(denominator));
      if (this._field.getGeneratorBase() != 0) {
        result[i] = this._field.multiply(result[i], xiInverse);
      }
    }
    return result;
  }

}