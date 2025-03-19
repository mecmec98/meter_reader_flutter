import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';
//import 'package:path/path.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';

class Databasedrawer extends StatefulWidget {
  @override
  State<Databasedrawer> createState() => _DatabasedrawerState();
}

class _DatabasedrawerState extends State<Databasedrawer> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _currentDate = 'Loading...'; // Initial placeholder
  bool _isLoading = true;
  bool _dataimportSuccess = false;

  @override
  void initState() {
    super.initState();
    _fetchDate(); // Fetch date when the widget initializes
  }

  // Fetch date from the database
  Future<void> _fetchDate() async {
    try {
      final prefsData = await _dbHelper.getPrefsData();
      if (prefsData != null && prefsData.containsKey('billdate')) {
        setState(() {
          _currentDate = prefsData['billdate'] ?? 'No date set';
          _isLoading = false;
          _dataimportSuccess = true;
        });
      } else {
        setState(() {
          _currentDate = 'No date found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentDate = 'Error loading date';
        _isLoading = false;
      });
    }
  }

  Future<void> _importDatabase() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );

    if (result != null) {
      bool success =
          await _dbHelper.importNewDatabase(result.files.single.path!);
      if (success) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database imported successfully!')),
      );
        await _fetchDate();
      } else {
        print('no database selected');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            child: Text(
              'Database Settings',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text('Current Bill Database Version Date'),
          Text(_currentDate), //here
          ElevatedButton(
            onPressed: _importDatabase,
            child: Text('Import Database'),
          ),
        ],
      ),
    );
  }
}
