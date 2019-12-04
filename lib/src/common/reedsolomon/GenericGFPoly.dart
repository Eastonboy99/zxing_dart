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

import '../../utils.dart';

import './GenericGF.dart';

/**
 * <p>Represents a polynomial whose coefficients are elements of a GF.
 * Instances of this class are immutable.</p>
 *
 * <p>Much credit is due to William Rucklidge since portions of this code are an indirect
 * port of his C++ Reed-Solomon implementation.</p>
 *
 * @author Sean Owen
 */
class GenericGFPoly {
  final GenericGF _field;
  List<int> _coefficients;

  /**
   * @param field the {@link GenericGF} instance representing the field to use
   * to perform computations
   * @param coefficients coefficients as ints representing elements of GF(size), arranged
   * from most significant (highest-power term) coefficient to least significant
   * @throws Exception if argument is null or empty,
   * or if leading coefficient is 0 and this is not a
   * constant polynomial (that is, it is not the monomial "0")
   */
  GenericGFPoly(this._field, List<int> coefficients) {
    if (coefficients.isEmpty) {
      throw Exception();
    }
    int coefficientsLength = coefficients.length;
    if (coefficientsLength > 1 && coefficients[0] == 0) {
      // Leading term must be non-zero for anything except the constant polynomial "0"
      int firstNonZero = 1;
      while (firstNonZero < coefficientsLength &&
          coefficients[firstNonZero] == 0) {
        firstNonZero++;
      }
      if (firstNonZero == coefficientsLength) {
        this._coefficients = List.from({0});
      } else {
        this._coefficients = List<int>(coefficientsLength - firstNonZero);
        this._coefficients = arraycopy(coefficients, firstNonZero, this._coefficients, 0,
            this._coefficients.length);
            print(this._coefficients);
      }
    }else{
      this._coefficients = coefficients;
    }
  }

  List<int> getCoefficients() {
    return this._coefficients;
  }

  /**
   * @return degree of this polynomial
   */
  int getDegree() {
    return this._coefficients.length - 1;
  }

  /**
   * @return true iff this polynomial is the monomial "0"
   */
  bool isZero() {
    return this._coefficients[0] == 0;
  }

  /**
   * @return coefficient of x^degree term in this polynomial
   */
  int getCoefficient(int degree) {
    return this._coefficients[this._coefficients.length - 1 - degree];
  }

  /**
   * @return evaluation of this polynomial at a given point
   */
  int evaluateAt(int a) {
    if (a == 0) {
      // Just return the x^0 coefficient
      return getCoefficient(0);
    }
    if (a == 1) {
      // Just the sum of the coefficients
      int result = 0;
      this._coefficients.forEach((coefficient) =>
          {result = GenericGF.addOrSubtract(result, coefficient)});

      return result;
    }
    int result = this._coefficients[0];
    int size = this._coefficients.length;
    for (int i = 1; i < size; i++) {
      result = GenericGF.addOrSubtract(
          this._field.multiply(a, result), this._coefficients[i]);
    }
    return result;
  }

  GenericGFPoly addOrSubtract(GenericGFPoly other) {
    if (!(this._field == other._field)) {
      throw Exception("GenericGFPolys do not have same GenericGF field");
    }
    if (isZero()) {
      return other;
    }
    if (other.isZero()) {
      return this;
    }

    List<int> smallerCoefficients = this._coefficients;
    List<int> largerCoefficients = other._coefficients;
    if (smallerCoefficients.length > largerCoefficients.length) {
      List<int> temp = smallerCoefficients;
      smallerCoefficients = largerCoefficients;
      largerCoefficients = temp;
    }
    List<int> sumDiff = List<int>(largerCoefficients.length);
    int lengthDiff = largerCoefficients.length - smallerCoefficients.length;
    // Copy high-order terms only found in higher-degree polynomial's coefficients
    arraycopy(largerCoefficients, 0, sumDiff, 0, lengthDiff);
    print("#51");
    print(smallerCoefficients);
    for (int i = lengthDiff; i < largerCoefficients.length; i++) {
      sumDiff[i] = GenericGF.addOrSubtract(
          smallerCoefficients[i - lengthDiff], largerCoefficients[i]);
    }

    print("#52");


    return GenericGFPoly(this._field, sumDiff);
  }

  GenericGFPoly multiply({GenericGFPoly other, int scalar}) {
    if (other != null) {
      if (!(this._field == other._field)) {
        throw Exception("GenericGFPolys do not have same GenericGF field");
      }
      if (isZero() || other.isZero()) {
        return this._field.getZero();
      }
      List<int> aCoefficients = this._coefficients;
      int aLength = aCoefficients.length;
      List<int> bCoefficients = other._coefficients;
      int bLength = bCoefficients.length;
      List<int> product = List<int>.filled(aLength + bLength - 1, 0);
      for (int i = 0; i < aLength; i++) {
        int aCoeff = aCoefficients[i];
        for (int j = 0; j < bLength; j++) {
          product[i + j] = GenericGF.addOrSubtract(
              product[i + j], this._field.multiply(aCoeff, bCoefficients[j]));
        }
      }
      return GenericGFPoly(this._field, product);
    } else {
      if (scalar == 0) {
        return this._field.getZero();
      }
      if (scalar == 1) {
        return this;
      }
      int size = this._coefficients.length;
      List<int> product = List<int>(size);
      for (int i = 0; i < size; i++) {
        product[i] = this._field.multiply(this._coefficients[i], scalar);
      }
      return GenericGFPoly(this._field, product);
    }
  }

  GenericGFPoly multiplyByMonomial(int degree, int coefficient) {
    if (degree < 0) {
      throw Exception();
    }
    if (coefficient == 0) {
      return this._field.getZero();
    }
    int size = this._coefficients.length;
    List<int> product = List<int>.filled(size + degree, 0);
    for (int i = 0; i < size; i++) {
      product[i] = this._field.multiply(this._coefficients[i], coefficient);
    }
    return GenericGFPoly(this._field, product);
  }

  List<GenericGFPoly> divide(GenericGFPoly other) {
    if (!(this._field == other._field)) {
      throw Exception("GenericGFPolys do not have same GenericGF field");
    }
    if (other.isZero()) {
      throw Exception("Divide by 0");
    }

    GenericGFPoly quotient = this._field.getZero();
    GenericGFPoly remainder = this;

    int denominatorLeadingTerm = other.getCoefficient(other.getDegree());
    int inverseDenominatorLeadingTerm =
        this._field.inverse(denominatorLeadingTerm);

    while (remainder.getDegree() >= other.getDegree() && !remainder.isZero()) {
      int degreeDifference = remainder.getDegree() - other.getDegree();
      int scale = this._field.multiply(
          remainder.getCoefficient(remainder.getDegree()),
          inverseDenominatorLeadingTerm);
      GenericGFPoly term = other.multiplyByMonomial(degreeDifference, scale);
      GenericGFPoly iterationQuotient =
          this._field.buildMonomial(degreeDifference, scale);
      quotient = quotient.addOrSubtract(iterationQuotient);
      remainder = remainder.addOrSubtract(term);
    }

    return List.from({quotient, remainder});
  }

  @override
  String toString() {
    if (isZero()) {
      return "0";
    }
    String result;
    for (int degree = getDegree(); degree >= 0; degree--) {
      int coefficient = getCoefficient(degree);
      if (coefficient != 0) {
        if (coefficient < 0) {
          if (degree == getDegree()) {
            result += "-";
          } else {
            result += " - ";
          }
          coefficient = -coefficient;
        } else {
          if (result.isNotEmpty) {
            result += " + ";
          }
        }
        if (degree == 0 || coefficient != 1) {
          int alphaPower = this._field.log(coefficient);
          if (alphaPower == 0) {
            result += '1';
          } else if (alphaPower == 1) {
            result += 'a';
          } else {
            result += "a^";
            result += alphaPower.toString();
          }
        }
        if (degree != 0) {
          if (degree == 1) {
            result += 'x';
          } else {
            result += "x^";
            result += degree.toString();
          }
        }
      }
    }
    return result.toString();
  }
}