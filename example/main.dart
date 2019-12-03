import 'dart:io';
import 'package:image/image.dart';

import '../lib/zxing_dart.dart';

main(List<String> args) {

    print("Working");

    Image image = decodeImage(File(args[0]).readAsBytesSync());

    ImageFileLuminanceSource source = new ImageFileLuminanceSource(image, image.width, image.height);

    BinaryBitmap bitmap = new BinaryBitmap(new HybridBinarizer(source));

    QRCodeReader reader = new QRCodeReader();

    Result result = reader.decode(bitmap);

    print(result.getText());

}