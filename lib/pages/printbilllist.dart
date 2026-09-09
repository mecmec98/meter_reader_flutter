import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:meter_reader_flutter/models/printlist_model.dart';
import 'package:meter_reader_flutter/helpers/database_helper.dart';

class PrintbillList extends StatefulWidget {
  @override
  State<PrintbillList> createState() => _PrintbillListState();
}

class _PrintbillListState extends State<PrintbillList> {
  final ScrollController _scrollController = ScrollController();
  List<PrintlistModel> _printl = [];
  bool _isLoading = false;
  int _offset = 0;
  final int _limit = 8;
  bool _hasMore = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore &&
          _searchQuery.isEmpty) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    // Fetch the next page
    List<PrintlistModel> newPrintl =
        await PrintlistModel.getMasterByIDforPrintedlist(offset: _offset);

    setState(() {
      _printl.addAll(newPrintl);
      _offset += newPrintl.length; // update offset
      _isLoading = false;
      // if fewer items were returned than the limit, there are no more items
      if (newPrintl.length < _limit) {
        _hasMore = false;
      }
    });
  }

  /// Search the database using the given query.
  Future<void> _searchData(String query) async {
    setState(() {
      _searchQuery = query;
    });

    // If the search query is empty, reload the paginated data.
    if (query.isEmpty) {
      setState(() {
        _printl.clear();
        _offset = 0;
        _hasMore = true;
      });
      await _loadData();
    } else {
      setState(() {
        _isLoading = true;
      });
      // Query the database using the search function.
      List<Map<String, dynamic>> results =
          await DatabaseHelper().searchPostedMasterData(query);
      // Convert results into your model.
      // Assumes PostmeterlistModel.fromMap exists.
      List<PrintlistModel> searchResults =
          results.map((map) => PrintlistModel.fromMap(map)).toList();
      setState(() {
        _printl = searchResults;
        _isLoading = false;
        // Disable pagination while showing search results.
        _hasMore = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _refreshList() async {
    setState(() {
      _printl.clear();
      _offset = 0;
      _hasMore = true;
    });
    await _loadData();
  }

  Widget _buildPrintlItem(PrintlistModel printl, int index) {
    // Alternate the background color
    final Color tileColor = index % 2 == 0
        ? Colors.white
        : const Color.fromARGB(255, 233, 239, 252);
    return GestureDetector(
      onTap: () async {
        // Navigate and wait for a result
        final shouldRefresh = await Navigator.pushNamed(
          context,
          '/consumercard',
          arguments: printl.printID,
        );
        // Refresh list if needed
        if (shouldRefresh == true) {
          _refreshList();
        }
      },
      child: Card(
        color: tileColor,
        margin: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      printl.printName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      printl.printAddress,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    printl.printMeterno,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: printAppbar(context),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                listCounter(),
                const SizedBox(height: 8),
                searchBar(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: printMeterLists()),
        ],
      ),
    );
  }

  ListView printMeterLists() {
    return ListView.builder(
      shrinkWrap: true,
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _printl.length + 1, // add one for the loading indicator
      itemBuilder: (context, index) {
        if (index < _printl.length) {
          return _buildPrintlItem(_printl[index], index);
        } else {
          // Show a loading indicator at the bottom if more data is loading
          return _hasMore
              ? Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : SizedBox.shrink();
        }
      },
    );
  }

  Container searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name, account no, meter no, or address',
          hintStyle: const TextStyle(
            color: Color.fromARGB(255, 195, 186, 186),
            fontSize: 13,
          ),
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset(
              'assets/icons/search.svg',
              colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) {
          _searchData(value);
        },
      ),
    );
  }

  AppBar printAppbar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color.fromARGB(255, 28, 85, 227),
      foregroundColor: Colors.white,
      title: const Text(
        'Print Bill',
        style: TextStyle(fontWeight: FontWeight.w500),
      ),
      elevation: 0,
      leading: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Container(
          margin: const EdgeInsets.only(left: 8),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/arrow-left.svg',
            height: 25,
            width: 25,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  Padding listCounter() {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_outlined,
                size: 18, color: Colors.blue),
            const SizedBox(width: 10),
            Text(
              '${_printl.length} Not Printed Bills',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
