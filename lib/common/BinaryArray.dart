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

library zxing_dart;

import 'dart:core';
import 'dart:math';

import 'package:fixnum/fixnum.dart';

class BitArray {
  List<Int64> _bits;
  int _size;

  BitArray({int size = 0}) {
    this._size = size;
    if (size != 0) {
      this._bits = makeArray(size);
    } else {
      this._bits = new List(1);
    }
  }

  int getSize() => this._size;

  int getSizeInBytes() => (this._size + 7) ~/ 8;

  void _ensureCapacity(int size) {
    if (size > this._bits.length * 32) {
      List<Int64> newBits = makeArray(size);
      newBits.addAll(this._bits);
      this._bits = newBits;
    }
  }

  /**
   * @param i bit to get
   * @return true iff bit i is set
   */
  bool get(int i) {
    return (this._bits[i ~/ 32] & (1 << (i & 0x1F))) != 0;
  }

  /**
   * Sets bit i.
   *
   * @param i bit to set
   */
  void set(int i) {
    this._bits[i ~/ 32] |= 1 << (i & 0x1F);
  }

  /**
   * Flips bit i.
   *
   * @param i bit to set
   */
  void flip(int i) {
    this._bits[i ~/ 32] ^= 1 << (i & 0x1F);
  }

  /**
   * @param from first bit to check
   * @return index of first bit that is set, starting from the given index, or size if none are set
   *  at or beyond this given index
   * @see #getNextUnset(int)
   */
  int getNextSet(int from) {
    if (from >= this._size) {
      return this._size;
    }
    int bitsOffset = from ~/ 32;
    Int64 currentBits = this._bits[bitsOffset];
    // mask off lesser bits first
    currentBits &= -(1 << (from & 0x1F));
    while (currentBits == 0) {
      if (++bitsOffset == this._bits.length) {
        return this._size;
      }
      currentBits = this._bits[bitsOffset];
    }
    int result = (bitsOffset * 32) + currentBits.numberOfTrailingZeros();
    return min(result, this._size);
  }

  /**
   * @param from index to start looking for unset bit
   * @return index of next unset bit, or {@code size} if none are unset until the end
   * @see #getNextSet(int)
   */
  int getNextUnset(int from) {
    if (from >= this._size) {
      return this._size;
    }
    int bitsOffset = from ~/ 32;
    Int64 currentBits = ~this._bits[bitsOffset];
    // mask off lesser bits first
    currentBits &= -(1 << (from & 0x1F));
    while (currentBits == 0) {
      if (++bitsOffset == this._bits.length) {
        return this._size;
      }
      currentBits = ~this._bits[bitsOffset];
    }
    int result = (bitsOffset * 32) + currentBits.numberOfTrailingZeros();
    return min(result, this._size);
  }

  /**
   * Sets a block of 32 bits, starting at bit i.
   *
   * @param i first bit to set
   * @param newBits the new value of the next 32 bits. Note again that the least-significant bit
   * corresponds to bit i, the next-least-significant to i+1, and so on.
   */
  void setBulk(int i, Int64 newBits) {
    this._bits[i ~/ 32] = newBits;
  }

  /**
   * Sets a range of bits.
   *
   * @param start start of range, inclusive.
   * @param end end of range, exclusive
   */
  void setRange(int start, int end) {
    if (end < start || start < 0 || end > this._size) {
      throw new Exception("Illegal Argument Exception");
    }
    if (end == start) {
      return;
    }
    end--; // will be easier to treat this as the last actually set bit -- inclusive
    int firstInt = start ~/ 32;
    int lastInt = end ~/ 32;
    for (int i = firstInt; i <= lastInt; i++) {
      int firstBit = i > firstInt ? 0 : start & 0x1F;
      int lastBit = i < lastInt ? 31 : end & 0x1F;
      // Ones from firstBit to lastBit, inclusive
      int mask = (2 << lastBit) - (1 << firstBit);
      this._bits[i] |= mask;
    }
  }
}
