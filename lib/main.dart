import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:open_file/open_file.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key); // Added named 'key' parameter

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Explorer App',
      home: FileExplorerScreen(),
    );
  }
}

class FileExplorerScreen extends StatefulWidget {
  const FileExplorerScreen({Key? key}) : super(key: key); // Added named 'key' parameter

  @override
  _FileExplorerScreenState createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  String? selectedPath;
  String fileExtension = '';
  int fileCount = 0;

  Map<String, List<String>> fileStructure = {};

  @override
  void initState() {
    super.initState();
    selectedPath = '/Users/poohhh';
    _loadDirectories(selectedPath!);
  }

  void _loadDirectories(String path) {
    var directory = Directory(path);
    List<String> subdirectories = [];
    List<String> files = [];
    int count = 0;
    try {
      directory.listSync().forEach((item) {
        // Don't add hidden files or directories
        if (p.basename(item.path).startsWith('.')) {
          return;
        }

        if (item is Directory) {
          var dirPath = item.path;
          subdirectories.add(dirPath);
        } else if (item is File) {
          var filePath = item.path;
          files.add(filePath);
          if (p.extension(filePath) == fileExtension) {
            count++;
          }
        }
      });
    } catch (e) {
      debugPrint('Error accessing directory: $e'); // Replaced 'print' with 'debugPrint'
    }

    setState(() {
      fileStructure[path] = [...subdirectories, ...files];
      selectedPath = path;
      fileCount = count;
    });
  }

  List<DropdownMenuItem<String>> _buildMenuItems(String path) {
    List<DropdownMenuItem<String>> items = [];
    if (path != '/Users/poohhh') {
      items.add(
        DropdownMenuItem(
          value: '...',
          child: const Text('...'), // Added 'const' keyword
        ),
      );
    }
    for (var item in fileStructure[path] ?? []) {
      var isDirectory = Directory(item).existsSync();

      items.add(
        DropdownMenuItem(
          value: item,
          child: Row(
            children: [
              Icon(
                isDirectory ? Icons.folder : Icons.insert_drive_file,
                color: isDirectory
                    ? const Color.fromRGBO(255, 233, 162, 1)
                    : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(p.basename(item)),
            ],
          ),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    var items = _buildMenuItems(selectedPath!);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "File explorer",
          style: TextStyle(color: Colors.black, fontSize: 16.0),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Current path: $selectedPath',
              style: const TextStyle(color: Colors.black, fontSize: 16.0),
            ),
            const SizedBox(height: 8),
            Text(
              'File count for $fileExtension: $fileCount',
              style: const TextStyle(color: Colors.black, fontSize: 16.0),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) {
                setState(() {
                  fileExtension = value;
                  _loadDirectories(selectedPath!);
                });
              },
              decoration: const InputDecoration(
                labelText: 'Enter file extension',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              
              child: DropdownButton<String>(
                value: items.any((item) => item.value == selectedPath)
                    ? selectedPath
                    : null,
                items: items,
                onChanged: (String? newValue) {
                  if (newValue == '...') {
                    var parentDir = p.dirname(selectedPath!);
                    _loadDirectories(parentDir);
                  } else if (newValue != null) {
                    if (Directory(newValue).existsSync()) {
                      _loadDirectories(newValue);
                    } else if (File(newValue).existsSync()) {
                      OpenFile.open(newValue);
                    }
                  }
                },
                isExpanded: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}