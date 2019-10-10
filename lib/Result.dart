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

/**
 * <p>Encapsulates the result of decoding a barcode within an image.</p>
 *
 * @author Sean Owen
 */
class Result {

  final String _text;
  final Uint64List _rawBytes;
  final int _numBits;
  List<ResultPoint> _resultPoints;
  final BarcodeFormat _format;
  Map<ResultMetadataType,Object> _resultMetadata;
  final int _timestamp;


  Result(this._text, this._rawBytes, this._numBits, this._format, this._timestamp){
    
  }



}