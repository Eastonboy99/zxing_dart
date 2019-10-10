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


import 'dart:core';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';

import 'package:fixnum/fixnum.dart';

class BitArray {
  List<Int64> _bits;
  int _size;

  BitArray({int size = 0}) {
    this._size = size;
    if (size != 0) {
      this._bits = _makeArray(size);
    } else {
      this._bits = new List(1);
    }
  }

  int getSize() => this._size;

  int getSizeInBytes() => (this._size + 7) ~/ 8;

  void _ensureCapacity(int size) {
    if (size > this._bits.length * 32) {
      List<Int64> newBits = _makeArray(size);
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

  /**
   * Clears all bits (sets to false).
   */
  void clear() {
    int max = this._bits.length;
    for (int i = 0; i < max; i++) {
      this._bits[i] = Int64(0);
    }
  }

  /**
   * Efficient method to check if a range of bits is set, or not set.
   *
   * @param start start of range, inclusive.
   * @param end end of range, exclusive
   * @param value if true, checks that bits in range are set, otherwise checks that they are not set
   * @return true iff all bits are set or not set in range, according to value argument
   * @throws IllegalArgumentException if end is less than start or the range is not contained in the array
   */
  bool isRange(int start, int end, bool value) {
    if (end < start || start < 0 || end > this._size) {
      throw new Exception("Illegal Argument Exception");
    }
    if (end == start) {
      return true; // empty range matches
    }
    end--; // will be easier to treat this as the last actually set bit -- inclusive
    int firstInt = start ~/ 32;
    int lastInt = end ~/ 32;
    for (int i = firstInt; i <= lastInt; i++) {
      int firstBit = i > firstInt ? 0 : start & 0x1F;
      int lastBit = i < lastInt ? 31 : end & 0x1F;
      // Ones from firstBit to lastBit, inclusive
      int mask = (2 << lastBit) - (1 << firstBit);

      // Return false if we're looking for 1s and the masked bits[i] isn't all 1s (that is,
      // equals the mask, or we're looking for 0s and the masked portion is not all 0s
      if ((this._bits[i] & mask) != (value ? mask : 0)) {
        return false;
      }
    }
    return true;
  }

  void appendBit(bool bit) {
    this._ensureCapacity(this._size + 1);
    if (bit) {
      this._bits[this._size ~/ 32] |= 1 << (this._size & 0x1F);
    }
    this._size++;
  }

  /**
   * Appends the least-significant bits, from value, in order from most-significant to
   * least-significant. For example, appending 6 bits from 0x000001E will append the bits
   * 0, 1, 1, 1, 1, 0 in that order.
   *
   * @param value {@code int} containing bits to append
   * @param numBits bits from value to append
   */
  void appendBits(int value, int numBits) {
    if (numBits < 0 || numBits > 32) {
      throw new Exception("Num bits must be between 0 and 32");
    }
    this._ensureCapacity(this._size + numBits);
    for (int numBitsLeft = numBits; numBitsLeft > 0; numBitsLeft--) {
      appendBit(((value >> (numBitsLeft - 1)) & 0x01) == 1);
    }
  }

  void appendBitArray(BitArray other) {
    int otherSize = other._size;
    this._ensureCapacity(this._size + otherSize);
    for (int i = 0; i < otherSize; i++) {
      appendBit(other.get(i));
    }
  }

  void xor(BitArray other) {
    if (this._size != other._size) {
      throw new Exception("Sizes don't match");
    }
    for (int i = 0; i < this._bits.length; i++) {
      // The last int could be incomplete (i.e. not have 32 bits in
      // it) but there is no problem since 0 XOR 0 == 0.
      this._bits[i] ^= other._bits[i];
    }
  }

  /**
   *
   * @param bitOffset first bit to start writing
   * @param array array to write into. Bytes are written most-significant byte first. This is the opposite
   *  of the internal representation, which is exposed by {@link #getBitArray()}
   * @param offset position in array to start writing
   * @param numBytes how many bytes to write
   */
  void toBytes(int bitOffset, Uint8List array, int offset, int numBytes) {
    for (int i = 0; i < numBytes; i++) {
      int theByte = 0;
      for (int j = 0; j < 8; j++) {
        if (get(bitOffset)) {
          theByte |= 1 << (7 - j);
        }
        bitOffset++;
      }
      array[offset + i] = theByte;
    }
  }

  /**
   * @return underlying array of ints. The first element holds the first 32 bits, and the least
   *         significant bit is bit 0.
   */
  List<Int64> getBitArray() {
    return this._bits;
  }

  /**
   * Reverses all bits in the array.
   */
  void reverse() {
    List<Int64> newBits = new List(this._bits.length);
    // reverse all int's first
    int len = (this._size - 1) ~/ 32;
    int oldBitsLen = len + 1;
    for (int i = 0; i < oldBitsLen; i++) {
      Int64 x = this._bits[i];
      x = ((x >> 1) & 0x55555555) | ((x & 0x55555555) << 1);
      x = ((x >> 2) & 0x33333333) | ((x & 0x33333333) << 2);
      x = ((x >> 4) & 0x0f0f0f0f) | ((x & 0x0f0f0f0f) << 4);
      x = ((x >> 8) & 0x00ff00ff) | ((x & 0x00ff00ff) << 8);
      x = ((x >> 16) & 0x0000ffff) | ((x & 0x0000ffff) << 16);
      newBits[len - i] = x;
    }
    // now correct the int's if the bit size isn't a multiple of 32
    if (this._size != oldBitsLen * 32) {
      int leftOffset = oldBitsLen * 32 - this._size;
      Int64 currentInt = newBits[0] >> leftOffset;
      for (int i = 1; i < oldBitsLen; i++) {
        int nextInt = newBits[i].toInt();
        currentInt |= nextInt << (32 - leftOffset);
        newBits[i - 1] = currentInt;
        currentInt = (nextInt >> leftOffset) as Int64;
      }
      newBits[oldBitsLen - 1] = currentInt;
    }
    this._bits = newBits;
  }

  static List<Int64> _makeArray(int size) {
    return new List((size + 31) ~/ 32);
  }

  bool operator ==(Object o) {
    if (!(o.runtimeType == BitArray)) {
      return false;
    }
    BitArray other = o as BitArray;
    return this._size == other._size &&
        ListEquality().equals(this._bits, other._bits);
  }

  @override
  int get hashCode => 31 * this._size.hashCode + this._bits.hashCode;

  @override
  String toString() {
    String result = "";
    for (int i = 0; i < this._size; i++) {
      if ((i & 0x07) == 0) {
        result += ' ';
      }
      result += get(i) ? 'X' : '.';
    }
    return result.toString();
  }

}
