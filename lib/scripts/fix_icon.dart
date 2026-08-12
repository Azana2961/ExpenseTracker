import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final imageBytes = File('d:/HostelExpenseApp/frontend/assets/icon.png').readAsBytesSync();
  final image = img.decodeImage(imageBytes)!;
  
  Map<int, int> colorCounts = {};
  for (var p in image) {
    int r = p.r.toInt();
    int g = p.g.toInt();
    int b = p.b.toInt();
    int color = (r << 16) | (g << 8) | b;
    colorCounts[color] = (colorCounts[color] ?? 0) + 1;
  }
  
  int maxCount = 0;
  int bgColor = 0;
  colorCounts.forEach((color, count) {
    if (count > maxCount) {
      maxCount = count;
      bgColor = color;
    }
  });
  
  int bgR = (bgColor >> 16) & 0xFF;
  int bgG = (bgColor >> 8) & 0xFF;
  int bgB = bgColor & 0xFF;
  
  print('Most common color: R:$bgR G:$bgG B:$bgB (Count: $maxCount / ${image.width * image.height})');
  
  // Now create the silhouette using a color distance threshold
  for (var p in image) {
    // calculate distance
    int r = p.r.toInt();
    int g = p.g.toInt();
    int b = p.b.toInt();
    int dr = r - bgR;
    int dg = g - bgG;
    int db = b - bgB;
    int distSq = dr*dr + dg*dg + db*db;
    
    // If it's close to background, or it's transparent, make it transparent
    if (distSq < 1000 || p.a < 128) {
      p.a = 0;
      p.r = 0;
      p.g = 0;
      p.b = 0;
    } else {
      p.r = 255;
      p.g = 255;
      p.b = 255;
      p.a = 255;
    }
  }
  
  final resized = img.copyResize(image, width: 72, height: 72); // xhdpi
  final pngBytes = img.encodePng(resized);
  File('d:/HostelExpenseApp/frontend/android/app/src/main/res/mipmap-hdpi/ic_notification.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(pngBytes);
      
  print('Created transparent icon.');
}
