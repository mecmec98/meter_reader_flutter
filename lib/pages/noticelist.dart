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
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController();

  List<NoticeModel> _items = [];
  bool _loading = true;
  String _searchQuery = '';
  int _selectedSection = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final items = await NoticeHelper().getAllNotices();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  void _onSearchChanged() {
    _filter(_searchController.text.trim());
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query;
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
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _selectedSection = index);
              },
              children: [
                _buildList(
                  noticeStatus: NoticeModel.noticeStatusPending,
                  emptyMessage: 'No pending notice records',
                ),
                _buildList(
                  noticeStatus: NoticeModel.noticeStatusPrinted,
                  emptyMessage: 'No saved notices awaiting photo proof',
                ),
                _buildList(
                  noticeStatus: NoticeModel.noticeStatusPrintedWithPhoto,
                  emptyMessage: 'No confirmed notices',
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildListNavigation(),
    );
  }

  Widget _buildCounter() {
    final pendingCount = _items
        .where(
          (item) => item.noticeStatus == NoticeModel.noticeStatusPending,
        )
        .length;
    final savedCount = _items
        .where(
          (item) => item.noticeStatus == NoticeModel.noticeStatusPrinted,
        )
        .length;
    final confirmedCount = _items
        .where(
          (item) =>
              item.noticeStatus == NoticeModel.noticeStatusPrintedWithPhoto,
        )
        .length;

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
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusCount('Pending', pendingCount),
                _buildStatusCount('Saved', savedCount),
                _buildStatusCount('Confirmed', confirmedCount),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCount(String label, int count) {
    return Text(
      '$label: $count',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.orange.shade800,
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

  Widget _buildList({
    required int noticeStatus,
    required String emptyMessage,
  }) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    var items =
        _items.where((item) => item.noticeStatus == noticeStatus).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((item) {
        return item.name.toLowerCase().contains(q) ||
            item.accNo.toLowerCase().contains(q) ||
            item.metNo.toLowerCase().contains(q) ||
            item.address.toLowerCase().contains(q);
      }).toList();
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? emptyMessage : 'No matches found',
          style: const TextStyle(color: Colors.black45, fontSize: 14),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final tileColor = index % 2 == 0
              ? Colors.white
              : const Color.fromARGB(255, 255, 249, 239);
          return InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoticeDetailsPage(item: item),
                ),
              );
              if (mounted) await _loadData();
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
                        if (item.noticeStatus ==
                                NoticeModel.noticeStatusPrinted ||
                            item.noticeStatus ==
                                NoticeModel.noticeStatusPrintedWithPhoto) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              item.noticeStatus ==
                                      NoticeModel.noticeStatusPrintedWithPhoto
                                  ? Icons.verified_outlined
                                  : Icons.print_outlined,
                              size: 14,
                              color: item.noticeStatus ==
                                      NoticeModel.noticeStatusPrintedWithPhoto
                                  ? const Color(0xFF2E7D32)
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.accNo,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(item.address,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade800)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListNavigation() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: BottomNavigationBar(
          currentIndex: _selectedSection,
          onTap: (index) {
            setState(() => _selectedSection = index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.orange.shade800,
          unselectedItemColor: const Color(0xFF8A8178),
          selectedLabelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule_outlined),
              activeIcon: Icon(Icons.schedule),
              label: 'Pending',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.print_outlined),
              activeIcon: Icon(Icons.print),
              label: 'Saved',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.verified_outlined),
              activeIcon: Icon(Icons.verified),
              label: 'Confirmed',
            ),
          ],
        ),
      ),
    );
  }
}
