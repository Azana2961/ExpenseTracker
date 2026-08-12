import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final imageBytes = File('d:/HostelExpenseApp/frontend/assets/icon.png').readAsBytesSync();
  final image = img.decodeImage(imageBytes)!;
  
  // Assuming the top-left pixel is the background color
  final bgColor = image.getPixel(0, 0);
  
  for (var p in image) {
    if (p.r == bgColor.r && p.g == bgColor.g && p.b == bgColor.b) {
      // Make background transparent
      p.a = 0;
    } else {
      // Make foreground pure white
      p.r = 255;
      p.g = 255;
      p.b = 255;
      p.a = 255;
    }
  }
  
  // Resize to 48x48 for notification icon (standard hdpi)
  final resized = img.copyResize(image, width: 96, height: 96);
  
  final pngBytes = img.encodePng(resized);
  File('d:/HostelExpenseApp/frontend/android/app/src/main/res/mipmap-hdpi/ic_notification.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(pngBytes);
      
  print('Successfully created transparent notification icon.');
}
