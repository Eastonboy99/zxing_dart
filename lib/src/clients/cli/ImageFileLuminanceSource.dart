import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart';

import '../../InvertedLuminanceSource.dart';
import '../../LuminanceSource.dart';

class ImageFileLuminanceSource extends LuminanceSource {
  Uint8ClampedList _buffer;

  static const _DEGREE_TO_RADIANS = pi / 180;

  ImageFileLuminanceSource(Image image, int width, int height)
      : super(width, height) {
        this._buffer = ImageFileLuminanceSource.makeBufferFromImage(image);
      }

  static Uint8ClampedList makeBufferFromImage(Image image) {
    Uint8ClampedList imageData = Uint8ClampedList.fromList(image.getBytes());
    return ImageFileLuminanceSource.toGrayscaleBuffer(
        imageData, image.width, image.height);
  }

  static Uint8ClampedList toGrayscaleBuffer(
      Uint8ClampedList imageBuffer, int width, int height) {
    Uint8ClampedList grayscaleBuffer = new Uint8ClampedList(width * height);

    for (var i = 0, j = 0, length = imageBuffer.length;
        i < length;
        i += 4, j++) {
      var gray;

      var alpha = imageBuffer[i + 3];

      if (alpha == 0) {
        gray = 0xFF;
      } else {
        var pixelR = imageBuffer[i];
        var pixelG = imageBuffer[i + 1];
        var pixelB = imageBuffer[i + 2];

        gray = (306 * pixelR + 601 * pixelG + 117 * pixelB + 0x200) >> 10;
      }

      grayscaleBuffer[j] = gray;
    }

    return grayscaleBuffer;
  }

  @override
  Uint8ClampedList getMatrix() {
    return this._buffer;
  }

  @override
  Uint8ClampedList getRow(int y, Uint8ClampedList row) {
    if (y < 0 || y >= this.getHeight()) {
      throw Exception("Illegal Argument Exception");
    }

    var width = this.getWidth();
    var start = y * width;

    if (row == null) {
      row = this._buffer.sublist(start, start + width);
    } else {
      if (row.length < width) {
        row = new Uint8ClampedList(width);
      }

      row.setAll(0, this._buffer.sublist(start, start + width));
    }

    return row;
  }
}
