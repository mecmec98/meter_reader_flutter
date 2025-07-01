import 'package:flutter/material.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';

class Databasedrawer extends StatefulWidget {
  @override
  State<Databasedrawer> createState() => _DatabasedrawerState();
}

class _DatabasedrawerState extends State<Databasedrawer> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _currentDate = 'Loading...'; // Initial placeholder
  // ignore: unused_field
  bool _isLoading = true;
  bool _dataimportSuccess = false;
  // ignore: unused_field
  bool _dataexportSuccess = false;

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

    if (result != null &&
        result.files.single.path != null &&
        result.files.single.name.toLowerCase().endsWith('.dbi')) {
      bool success =
          await _dbHelper.importNewDatabase(result.files.single.path!);
      if (success) {
        setState(() {
          _dataimportSuccess = true;
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database imported successfully!')),
        );
        await _fetchDate();
      } else {
        setState(() {
          _dataimportSuccess = false;
        });
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import database')),
        );
      }
    }
  }

  Future<void> _exportDatabase() async {
    bool success = await _dbHelper.exportDatabase();
    if (success) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database exported to Downloads folder!')),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export database')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(top: 50, bottom: 40),
            child: Text(
              'Database Settings',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 25),
            ),
          ),
          Text(
            'Current Bill Database Version Date',
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          Container(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                _currentDate,
                style: TextStyle(fontWeight: FontWeight.w500),
              )),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Importing New Database'),
                    content: Text(
                        'Importing a new database will replace the current one, Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          await _importDatabase();
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pop();
                        },
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.all(Colors.green),
                        ),
                        child: Text(
                          'Yes',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pop();
                        },
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(Colors.red),
                        ),
                        child: Text(
                          'No',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  );
                },
              );
            }, //_importDatabase,
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.green),
            ),
            icon: SvgPicture.asset(
              'assets/icons/import-database.svg',
              height: 20,
              width: 20,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            label: Text(
              'Import Database',
              style:
                  TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
          if (_dataimportSuccess) ...[
            Text(
              '',
              style:
                  TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            )
          ],
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Export Database'),
                        content: Text(
                            'Exporting the Database will replace any previously exported database (MRADB.dbo) in your Public Downloads folder'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () async {
                              await _exportDatabase();
                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pop();
                            },
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.all(Colors.green),
                            ),
                            child: Text(
                              'Yes',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              // ignore: use_build_context_synchronously
                              Navigator.of(context).pop();
                            },
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.all(Colors.red),
                            ),
                            child: Text(
                              'No',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    });
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.blue),
              ),
              icon: SvgPicture.asset(
                'assets/icons/export-database.svg',
                height: 20,
                width: 20,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              label: Text(
                'Export Database',
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
          Text(
            'Databases Exported to Public Downloads Folder',
            style: TextStyle(color: Colors.grey, fontSize: 8),
          ),
        ],
      ),
    );
  }
}
