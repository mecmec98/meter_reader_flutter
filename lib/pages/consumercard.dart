import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

//comments
class Consumercard extends StatefulWidget {
  const Consumercard({super.key});

  @override
  State<Consumercard> createState() => _ConsumercardState();
}
//usage = cardCurrreading - cardPrevreading
class _ConsumercardState extends State<Consumercard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: cardappBar(context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 10,
            ),
            Center(
              child: userInformationCard(),
            ),
            SizedBox(
              height: 2,
            ),
            Center(
              child: readersField(),
            ),
            SizedBox(
              height: 2,
            ),
            Center(
              child: particularsContainer(),
            )
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        padding: EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {},
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.blue),
                padding: WidgetStateProperty.all<EdgeInsets>(
                    EdgeInsets.only(top: 15, bottom: 15, left: 60, right: 60)),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        10.0), // adjust the value as needed
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SvgPicture.asset(
                    'assets/icons/print.svg',
                    height: 20,
                    width: 20,
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Print',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  )
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {},
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.green),
                padding: WidgetStateProperty.all<EdgeInsets>(
                    EdgeInsets.only(top: 15, bottom: 15, left: 60, right: 60)),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        10.0), // adjust the value as needed
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SvgPicture.asset(
                    'assets/icons/save.svg',
                    height: 20,
                    width: 20,
                    colorFilter:
                        const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container particularsContainer() {
    return Container(
      width: 320,
      padding: EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Column(
        children: [
          Row(
            //start Current Bill
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Bill'),
              Text(
                '252.00', //result of bill_helper calculation
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          Divider(
            color: Colors.grey,
            thickness: 0.5,
          ),
          Row(
            //start Less Discount
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Less Discount'),
              Text(
                '0.00',
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          Divider(
            color: Colors.grey,
            thickness: 0.5,
          ),
          Row(
            //start Arrears
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Arrears'), 
              Text(
                '252.00', //cardArrears
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          Divider(
            color: Colors.grey,
            thickness: 0.5,
          ),
          Row(
            //start Others
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Others'),
              Text(
                '0.00', //cardOthers
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          Divider(
            color: Colors.grey,
            thickness: 0.5,
          ),
          Row(
            //start b4duedate 
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Before Due Date',
                style: TextStyle(color: Colors.blue),
              ),
              Text(
                '504.00', //calculation after cardCurrbill + Arrears
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Divider(
            color: Colors.grey,
            thickness: 0.5,
          ),
          Row(
            //start penalty
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Penalty', 
                style: TextStyle(color: Colors.red),
              ),
              Text(
                '0.00', //if it applies
                style: TextStyle(fontWeight: FontWeight.w400),
              ),
            ],
          ),
          Divider(
            color: Colors.grey,
            thickness: 0.5,
          ),
          Row(
            //start afterduedate
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total After Due Date',
                style: TextStyle(color: Colors.green),
              ),
              Text(
                '504.00', //5% increase from finalresult of bill_helper
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Divider(
            color: Colors.grey,
            thickness: 0.5,
          ),
        ],
      ),
    );
  }

  Container readersField() {
    return Container(
      padding: EdgeInsets.only(top: 5, bottom: 10, left: 40, right: 40),
      child: Column(
        children: [
          Text(
            'Current Reading',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          TextField( //use for  cardCurbill
            textAlign: TextAlign.center,
            decoration: InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(5))),
          ),
          SizedBox(
            height: 12,
          ),
          Text(
            'Previous Reading',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w400,
              fontSize: 10,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          TextField(
            readOnly: true,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '32', //cardPrevreading
              hintStyle:
                  TextStyle(color: const Color.fromARGB(255, 255, 250, 250)),
              filled: true,
              fillColor: Colors.blue,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container userInformationCard() {
    return Container(
      width: 350,
      padding: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        //color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            'JASON BATAL', //cardName
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          Text(
            '042-102-082', //cardAccno
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: Colors.blue,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            'LINABO, DAPITAN CITY', //cardAddress
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.black,
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Divider(
            color: Colors.grey,
            thickness: 0.5,
          ),
          SizedBox(
            height: 10,
          ),
          Column(
            children: [
              //First Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        '123 23154', //cardMeterno
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w400,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'Meter no.',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: const Color.fromARGB(255, 47, 48, 49),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        'MET', //cardMeterbrand
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'Meter Brand',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: const Color.fromARGB(255, 47, 48, 49),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              //Second Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Text(
                        'RESIDENTIAL', //cardClassification
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w400,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'Classification',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: const Color.fromARGB(255, 47, 48, 49),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '1/2"', //cardMetersize
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w400,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'Meter Size',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: const Color.fromARGB(255, 47, 48, 49),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  AppBar cardappBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Post Meter Reading',
        style: TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      leading: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/postmeterreading');
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
