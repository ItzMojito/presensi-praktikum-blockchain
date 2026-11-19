import 'package:web3dart/web3dart.dart';

class PresensiModel {
  final int id;
  final String nimHashHex;
  final int pertemuanKe;
  final DateTime waktuHadir;
  final EthereumAddress pengirim;
  final bool terverifikasi;

  PresensiModel({
    required this.id,
    required this.nimHashHex,
    required this.pertemuanKe,
    required this.waktuHadir,
    required this.pengirim,
    required this.terverifikasi,
  });

  String get shortHash =>
      '${nimHashHex.substring(0, 10)}...${nimHashHex.substring(nimHashHex.length - 6)}';

  String get shortPengirim {
    final hex = pengirim.hexEip55;
    return '${hex.substring(0, 6)}...${hex.substring(hex.length - 4)}';
  }
}