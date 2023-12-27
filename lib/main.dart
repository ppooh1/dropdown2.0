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

  List<Widget> _buildTreeView(String path) {
    List<Widget> treeView = [];
    if (path != '/Users/poohhh') {
      treeView.add(
        ListTile(
          title: const Text('...'), // Added 'const' keyword
          leading: const Icon(Icons.folder),
          onTap: () {
            var parentDir = p.dirname(selectedPath!);
            _loadDirectories(parentDir);
          },
        ),
      );
    }
    for (var item in fileStructure[path] ?? []) {
      var isDirectory = Directory(item).existsSync();

      treeView.add(
        ListTile(
          title: Text(p.basename(item)),
          leading: Icon(
            isDirectory ? Icons.folder : Icons.insert_drive_file,
            color: isDirectory
                ? const Color.fromRGBO(255, 233, 162, 1)
                : Colors.red,
          ),
          onTap: () {
            if (isDirectory) {
              _loadDirectories(item);
            } else {
              OpenFile.open(item);
            }
          },
        ),
      );
    }
    return treeView;
  }

  List<String> _getSubdirectories(String path) {
    List<String> subdirectories = [];
    for (var item in fileStructure[path] ?? []) {
      if (Directory(item).existsSync()) {
        subdirectories.add(item);
      }
    }
    return subdirectories;
  }

  List<String> _getFiles(String path) {
    List<String> files = [];
    for (var item in fileStructure[path] ?? []) {
      if (File(item).existsSync()) {
        files.add(item);
      }
    }
    return files;
  }

  Widget _buildTreeViewItem(String path) {
    var isDirectory = Directory(path).existsSync();
    var subdirectories = _getSubdirectories(path);
    var files = _getFiles(path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(p.basename(path)),
          leading: Icon(
            isDirectory ? Icons.folder : Icons.insert_drive_file,
            color: isDirectory
                ? const Color.fromRGBO(255, 233, 162, 1)
                : Colors.red,
          ),
          onTap: () {
            if (isDirectory) {
              _loadDirectories(path);
            } else {
              OpenFile.open(path);
            }
          },
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var subdirectory in subdirectories)
                _buildTreeViewItem(subdirectory),
              for (var file in files)
                ListTile(
                  title: Text(p.basename(file)),
                  leading: const Icon(Icons.insert_drive_file),
                  onTap: () {
                    OpenFile.open(file);
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
Widget build(BuildContext context) {
  var treeView = _buildTreeViewItem(selectedPath!);
  return Scaffold(
    appBar: AppBar(
      title: const Text(
        "File explorer",
        style: TextStyle(color: Colors.black, fontSize: 16.0),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () {
          var parentDir = p.dirname(selectedPath!);
          _loadDirectories(parentDir);
        },
      ),
      backgroundColor: Colors.white,
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
          Expanded(
            child: ListView(
              children: [
                if (selectedPath != '/Users/poohhh') ...[
                  ListTile(
                    title: Text(p.basename(p.dirname(selectedPath!))),
                    leading: const Icon(Icons.folder, color: Color.fromRGBO(255, 233, 162, 1)),
                    onTap: () {
                      var parentDir = p.dirname(selectedPath!);
                      _loadDirectories(parentDir);
                    },
                  ),
                ],
                treeView,
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
