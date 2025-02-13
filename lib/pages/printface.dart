import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Printface extends StatefulWidget {
  const Printface({super.key});

  @override
  State<Printface> createState() => _PrintfaceState();
}

class _PrintfaceState extends State<Printface> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: printAppbarface(context),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
            child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(9)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: receiptHeader(),
            ),
            receiptConsumer(),
            recieptBody(),
            receiptFooter()
          ]),
        )),
      ),
    );
  }

  Center receiptFooter() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(1),
        child: Text(
          'Other Messages and Announcements',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Container receiptConsumer() {
    return Container(
      padding: EdgeInsets.only(top: 1, bottom: 1),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'John Doe',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          Text(
            'Address',
            style: TextStyle(fontSize: 16),
          ),
          Text(
            'Meter No. 123-123123',
            style: TextStyle(fontSize: 14),
          ),
          Text(
            'Meter Brand: DapCWD',
            style: TextStyle(fontSize: 14),
          ),
          SizedBox(
            height: 5,
          ),
          Divider(color: Colors.grey, thickness: 0.5),
        ],
      ),
    );
  }

  Container recieptBody() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Previous Reading',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              Text(
                '0',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Reading',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              Text(
                '0',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Usage',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              Text(
                '0',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              )
            ],
          ),
          Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Water Bill',
                style: TextStyle(fontSize: 17),
              ),
              Text(
                '0.00',
                style: TextStyle(fontSize: 17),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Water Maintenance Fee',
                style: TextStyle(fontSize: 17),
              ),
              Text(
                '25.00',
                style: TextStyle(fontSize: 17),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arrears/Advance',
                style: TextStyle(fontSize: 17),
              ),
              Text(
                '0.00',
                style: TextStyle(fontSize: 17),
              )
            ],
          ),
          SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL DUE',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              ),
              Text(
                '0.00',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
              )
            ],
          ),
          Divider(color: Colors.grey, thickness: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DUE DATE: +15 Days from bill release',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL AFTER DUE DATE',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              ),
              Text(
                '0.00 * 1.5',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              )
            ],
          ),
          Divider(color: Colors.grey, thickness: 0.5),
        ],
      ),
    );
  }

  Column receiptHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Dapitan City Water District',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        Center(child: Text('Lorem Ipsum')),
        SizedBox(
          height: 10,
        ),
        Center(
          child: Text(
            'BILLING STATEMENT',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
        ),
        Text('For the month of January 2025'),
        Text('Date Printed: 02/13/2025 10:00 AM'),
        Text('Period Covered: 1/17/2025-02/12/2025'),
        SizedBox(
          height: 5,
        ),
        Divider(color: Colors.grey, thickness: 0.5),
      ],
    );
  }
}

AppBar printAppbarface(BuildContext context) {
  return AppBar(
    title: Text(
      'Print Bill Sample',
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
