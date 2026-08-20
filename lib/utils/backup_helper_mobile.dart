import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

Future<void> saveBackupFile(String jsonStr, String filename) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$filename');
  await file.writeAsString(jsonStr);
  
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/json')],
      subject: 'Khandelwal Boutique Backup',
    ),
  );
}

Future<String?> pickBackupFile() async {
  final files = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (files.isNotEmpty && files.first.path != null) {
    final file = File(files.first.path!);
    return await file.readAsString();
  }
  return null;
}
