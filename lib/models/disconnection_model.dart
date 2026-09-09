class DisconnectionModel {
  final int? id;
  final String accNo;
  final String name;
  final String address;
  final String metNo;
  final String brand;
  final int lrdg;
  final int months;
  final String? oldest;
  final double balance;
  final String? others;
  final String? payDate;
  final double payAmt;
  final int? months2;
  final String? oldest1;
  final int masCode;
  final String metStat;
  final int disconReading;
  final String remarks;
  final String disconDate;
  final String optionType;

  DisconnectionModel({
    this.id,
    required this.accNo,
    required this.name,
    required this.address,
    required this.metNo,
    required this.brand,
    required this.lrdg,
    required this.months,
    this.oldest,
    required this.balance,
    this.others,
    this.payDate,
    required this.payAmt,
    this.months2,
    this.oldest1,
    required this.masCode,
    required this.metStat,
    required this.disconReading,
    required this.remarks,
    required this.disconDate,
    required this.optionType,
  });

  DisconnectionModel copyWith({
    int? disconReading,
    String? metStat,
    String? remarks,
  }) {
    return DisconnectionModel(
      id: id,
      accNo: accNo,
      name: name,
      address: address,
      metNo: metNo,
      brand: brand,
      lrdg: lrdg,
      months: months,
      oldest: oldest,
      balance: balance,
      others: others,
      payDate: payDate,
      payAmt: payAmt,
      months2: months2,
      oldest1: oldest1,
      masCode: masCode,
      metStat: metStat ?? this.metStat,
      disconReading: disconReading ?? this.disconReading,
      remarks: remarks ?? this.remarks,
      disconDate: disconDate,
      optionType: optionType,
    );
  }

  static String? _dateOnly(dynamic value) {
    if (value == null) return null;
    final date = value.toString();
    return date.length > 10 ? date.substring(0, 10) : date;
  }

  factory DisconnectionModel.fromMap(Map<String, dynamic> map) {
    return DisconnectionModel(
      id: map['_id'] as int?,
      accNo: (map['ACCNO'] ?? map['acc_no']) as String,
      name: (map['NAME'] ?? map['name']) as String,
      address: (map['ADDRESS'] ?? map['address']) as String,
      metNo: (map['METNO'] ?? map['met_no']) as String,
      brand: (map['BRAND'] ?? map['brand']) as String,
      lrdg: (map['LRDG'] ?? map['lrdg']) as int,
      months: (map['MONTHS'] ?? map['months']) as int,
      oldest: _dateOnly(map['OLDEST'] ?? map['oldest']),
      balance: ((map['BALANCE'] ?? map['balance']) as num).toDouble(),
      others: map['OTHERS'] ?? map['others'] as String?,
      payDate: map['PAYDATE'] ?? map['pay_date'] as String?,
      payAmt: ((map['PAY_AMT'] ?? map['pay_amt']) as num).toDouble(),
      months2: map['MONTHS2'] ?? map['months2'] as int?,
      oldest1: _dateOnly(map['OLDEST1'] ?? map['oldest1']),
      masCode: (map['MASCODE'] ?? map['mas_code']) as int,
      metStat: (map['METSTAT'] ?? map['met_stat']) as String,
      disconReading: (map['DISCONREADING'] ?? map['discon_reading']) as int,
      remarks: (map['REMARKS'] ?? map['remarks']) as String,
      disconDate: _dateOnly(map['DISCONDATE'] ?? map['discon_date']) ?? '',
      optionType: (map['OPTIONTYPE'] ?? map['option_type']) as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'acc_no': accNo,
      'name': name,
      'address': address,
      'met_no': metNo,
      'brand': brand,
      'lrdg': lrdg,
      'months': months,
      'oldest': oldest,
      'balance': balance,
      'others': others,
      'pay_date': payDate,
      'pay_amt': payAmt,
      'months2': months2,
      'oldest1': oldest1,
      'mas_code': masCode,
      'met_stat': metStat,
      'discon_reading': disconReading,
      'remarks': remarks,
      'discon_date': disconDate,
      'option_type': optionType,
    };
  }
}
