import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:meter_reader_flutter/helpers/notice_helper.dart';
import 'package:meter_reader_flutter/models/notice_model.dart';
import 'package:meter_reader_flutter/pages/noticedetails.dart';

class NoticeList extends StatefulWidget {
  const NoticeList({super.key});

  @override
  State<NoticeList> createState() => _NoticeListState();
}

class _NoticeListState extends State<NoticeList> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<NoticeModel> _items = [];
  List<NoticeModel> _filtered = [];
  bool _loading = true;
  String _searchQuery = '';
  double _totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final items = await NoticeHelper().getAllNotices();
    if (!mounted) return;
    final total = items.fold<double>(0.0, (sum, item) => sum + item.balance);
    setState(() {
      _items = items;
      _filtered = items;
      _totalBalance = total;
      _loading = false;
    });
  }

  void _onSearchChanged() {
    _filter(_searchController.text.trim());
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filtered = _items;
      } else {
        final q = query.toLowerCase();
        _filtered = _items.where((item) {
          return item.name.toLowerCase().contains(q) ||
              item.accNo.toLowerCase().contains(q) ||
              item.metNo.toLowerCase().contains(q) ||
              item.address.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: const Text(
          'Notice List',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCounter(),
                const SizedBox(height: 12),
                _buildSearchBar(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildCounter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_outlined,
              size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Text(
            'Notice Count: ${_filtered.length}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade800,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by name, account no, meter no, or address',
          hintStyle: const TextStyle(
              color: Color.fromARGB(255, 195, 186, 186), fontSize: 13),
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
      ),
    );
  }

  Widget _buildList() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'No notice records' : 'No matches found',
          style: const TextStyle(color: Colors.black45, fontSize: 14),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final item = _filtered[index];
          final tileColor = index % 2 == 0
              ? Colors.white
              : const Color.fromARGB(255, 255, 249, 239);
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoticeDetailsPage(item: item),
                ),
              );
            },
            child: Card(
              color: tileColor,
              margin: const EdgeInsets.only(bottom: 8),
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
                          item.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₱${item.balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.accNo,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text(item.address,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                ],
              ),
              ),
            ),
          );
        },
      ),
    );
  }
}