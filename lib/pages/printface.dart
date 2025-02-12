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
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(9)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: receiptHeader(),
              ),
              recieptBody(),
            ],
          ),
        ),
      ),
    );
  }

  Container recieptBody() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Previous Reading',
                style: TextStyle(fontSize: 17),
              ),
              Text(
                '0',
                style: TextStyle(fontSize: 17),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Reading',
                style: TextStyle(fontSize: 17),
              ),
              Text(
                '0',
                style: TextStyle(fontSize: 17),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Usage',
                style: TextStyle(fontSize: 17),
              ),
              Text(
                '0',
                style: TextStyle(fontSize: 17),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Bill',
                style: TextStyle(fontSize: 17),
              ),
              Text(
                '0',
                style: TextStyle(fontSize: 17),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Arrears',
                style: TextStyle(fontSize: 17),
              ),
              Text(
                '0',
                style: TextStyle(fontSize: 17),
              )
            ],
          ),
        ],
      ),
    );
  }

  Column receiptHeader() {
    return Column(
      children: [
        Text(
          'Dapitan City Water District',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
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
