import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

class Utils {
  String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (diff.inDays < 365) {
      final months = (diff.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (diff.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  String cleanUrl(String url) {
    return url.replaceAllMapped(RegExp(r'([^:])/+'), (match) {
      return '${match.group(1)}/';
    });
  }

  String formatPhoneNumber(String input) {
    input = input.trim();
    if (input.startsWith('0') && input.length == 10) {
      return '254${input.substring(1)}';
    } else if (input.startsWith('254') && input.length == 12) {
      return input;
    } else {
      throw FormatException("Invalid phone number format");
    }
  }

  String formatUtcToLocal(String utcDateString) {
    try {
      DateTime utcDate = DateTime.parse(utcDateString).toUtc();
      DateTime localDate = utcDate.toLocal();
      return DateFormat('MMMM dd, yyyy – h:mm a').format(localDate);
    } catch (e) {
      return "Invalid Date";
    }
  }

  Future<bool> _checkImageSize(File imageFile) async {
    int sizeInBytes = imageFile.lengthSync();
    double sizeInMb = sizeInBytes / (1024 * 1024);

    if (sizeInMb > 5) {
      return true;
    } else {
      return false;
    }
  }

  Future<String?> uploadPicture(image) async {
    try {
      File imageFile = File(image.path);
      String fileExtension = imageFile.path.split('.').last.toLowerCase();

      final bytes = await imageFile.readAsBytes();

      if (fileExtension == 'jpg' ||
          fileExtension == 'jpeg' ||
          fileExtension == 'png') {
        // This is an image
        bool isLarge = await _checkImageSize(imageFile);

        img.Image? originalImage = img.decodeImage(Uint8List.fromList(bytes));
        if (originalImage != null) {
          img.Image compressedImage = img.copyResize(
            originalImage,
            width: 800,
            height: 800,
          );

          List<int> compressedBytes =
              isLarge
                  ? img.encodeJpg(compressedImage, quality: 50)
                  : img.encodeJpg(originalImage, quality: 70);

          final base64Image =
              'data:image/jpeg;base64, ${base64Encode(compressedBytes)}';

          var request = http.MultipartRequest(
            'POST',
            Uri.parse('https://bucket.ndai.africa/single_image.php'),
          );
          request.fields['image'] = base64Image;

          var response = await request.send();

          if (response.statusCode == 200) {
            var responseBody = await response.stream.bytesToString();
            var decodedResponse = jsonDecode(responseBody);
            return decodedResponse['url'];
          } else {
            print("Image upload failed");
          }
        } else {
          print('Error: Invalid image format');
        }
      } else if (fileExtension == 'pdf') {
        // This is a PDF
        final base64PDF = 'data:application/pdf;base64,${base64Encode(bytes)}';

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('https://bucket.ndai.africa/single_image.php'),
        );
        request.fields['image'] = base64PDF;

        var response = await request.send();

        if (response.statusCode == 200) {
          var responseBody = await response.stream.bytesToString();
          var decodedResponse = jsonDecode(responseBody);
          return decodedResponse['url'];
        } else {
          print("PDF upload failed");
        }
      } else {
        print("Unsupported file type");
      }
    } catch (e) {
      print("An error occurred: $e");
    }

    return null;
  }
}
