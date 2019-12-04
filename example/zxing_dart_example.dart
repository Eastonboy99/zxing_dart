import 'dart:io';
import 'package:image/image.dart';

import 'package:zxing_dart/zxing_dart.dart';

main(List<String> args) {

    print("Working");

    // String imageFile = args.isNotEmpty ? args[0] : "./example.png"; 

    Image image = decodeImage(File(args[0]).readAsBytesSync());

    ImageFileLuminanceSource source = ImageFileLuminanceSource(image, image.width, image.height);

    BinaryBitmap bitmap = BinaryBitmap(HybridBinarizer(source));

    QRCodeReader reader = QRCodeReader();

    Result result = reader.decode(bitmap);

    print(result.getText());

}