import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:meter_reader_flutter/models/printlist_model.dart';

//import 'package:flutter/scheduler.dart';
//import 'package:flutter/foundation.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
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
        await PrintlistModel.getMasterByIDforPrintlist(
            limit: _limit, offset: _offset);

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildPrintlItem(PrintlistModel printl, int index) {
    // Alternate the background color
    final Color tileColor = index % 2 == 0 ? Colors.white : const Color.fromARGB(255, 212, 224, 250);
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/consumercard',
          arguments: printl.printID,
        );
      },
      child: Card(
        color: tileColor,
        margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                printl.printName,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                printl.printMeterno,
                style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w400),
              ),
              Text(
                printl.printAddress,
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          searchBar(),
          SizedBox(
            height: 5.0,
          ),
          Expanded(
            child: printMeterLists(),
          ),
        ],
      ),
    );
  }

  ListView printMeterLists() {
    return ListView.builder(
      shrinkWrap: true,
      controller: _scrollController,
      itemCount: _printl.length + 1, // add one for the loading indicator
      itemBuilder: (context, index) {
        if (index < _printl.length) {
          return _buildPrintlItem(_printl[index], index);
        } else {
          // Show a loading indicator at the bottom if more data is loading
          return _hasMore
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : SizedBox.shrink();
        }
      },
    );
  }

  Container searchBar() {
    return Container(
      margin: EdgeInsets.only(top: 20,bottom: 15, left: 20, right: 20),
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          color: Color.fromARGB(255, 230, 223, 223).withValues(),
          blurRadius: 8,
          spreadRadius: 0.0,
        )
      ]),
      child: TextField(
          decoration: InputDecoration(
        hintText: 'Search',
        hintStyle: TextStyle(color: Color.fromARGB(255, 195, 186, 186)),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SvgPicture.asset(
            'assets/icons/search.svg',
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
          ),
        ),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide.none),
      )),
    );
  }

  AppBar printAppbar(BuildContext context) {
    return AppBar(
      title: Text(
        'Print Bill',
        style: TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/');
        },
        child: Container(
          margin: EdgeInsets.all(10),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/icons/arrow-left.svg',
            height: 25,
            width: 25,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
