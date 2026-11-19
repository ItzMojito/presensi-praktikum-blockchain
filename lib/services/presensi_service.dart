import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

import '../config/blockchain_config.dart';
import '../models/presensi_model.dart';

class PresensiService {
  late Web3Client _client;
  late EthPrivateKey _credentials;
  late DeployedContract _contract;

  late ContractFunction _jumlahPresensiFn;
  late ContractFunction _ambilPresensiFn;
  late ContractFunction _catatPresensiFn;
  late ContractFunction _verifikasiPresensiFn;
  late ContractFunction _ubahPertemuanFn;

  bool _isInitialized = false;

  EthereumAddress get myAddress => _credentials.address;

  Future<void> init() async {
    if (_isInitialized) return;
    BlockchainConfig.validate();

    _client = Web3Client(BlockchainConfig.rpcUrl, http.Client());
    _credentials = EthPrivateKey.fromHex(BlockchainConfig.privateKey);

    final abiJson = await rootBundle.loadString(BlockchainConfig.abiAssetPath);
    final abi = ContractAbi.fromJson(abiJson, 'PresensiPraktikum');
    final contractAddr = EthereumAddress.fromHex(BlockchainConfig.contractAddress);

    _contract = DeployedContract(abi, contractAddr);

    _jumlahPresensiFn = _contract.function('jumlahPresensi');
    _ambilPresensiFn = _contract.function('ambilPresensi');
    _catatPresensiFn = _contract.function('catatPresensi');
    _verifikasiPresensiFn = _contract.function('verifikasiPresensi');
    _ubahPertemuanFn = _contract.function('ubahPertemuan');

    _isInitialized = true;
  }

  /// Hash NIM secara lokal dengan Keccak-256 (32 bytes) agar NIM asli tidak pernah ke blockchain
  Uint8List hashNimBytes(String nim) {
    final normalized = nim.trim().toUpperCase();
    return keccakUtf8(normalized);
  }

  String hashNimHex(String nim) {
    return bytesToHex(hashNimBytes(nim), include0x: true);
  }

  /// Membaca saldo Sepolia ETH wallet aktif (untuk membantu debug gas)
  Future<double> ambilSaldoEth() async {
    await init();
    final balance = await _client.getBalance(_credentials.address);
    return balance.getValueInUnit(EtherUnit.ether);
  }

  /// Membaca seluruh daftar presensi (fungsi view - gratis tanpa gas)
  Future<List<PresensiModel>> ambilSemuaPresensi() async {
    await init();

    final countResult = await _client.call(
      contract: _contract,
      function: _jumlahPresensiFn,
      params: [],
    );

    final total = (countResult.first as BigInt).toInt();
    final List<PresensiModel> list = [];

    for (int i = 0; i < total; i++) {
      final res = await _client.call(
        contract: _contract,
        function: _ambilPresensiFn,
        params: [BigInt.from(i)],
      );

      final nimHashBytes = res[0] as Uint8List;
      final pertemuanKe = (res[1] as BigInt).toInt();
      final waktuUnix = (res[2] as BigInt).toInt();
      final pengirim = res[3] as EthereumAddress;
      final terverifikasi = res[4] as bool;

      list.add(
        PresensiModel(
          id: i,
          nimHashHex: bytesToHex(nimHashBytes, include0x: true),
          pertemuanKe: pertemuanKe,
          waktuHadir: DateTime.fromMillisecondsSinceEpoch(waktuUnix * 1000),
          pengirim: pengirim,
          terverifikasi: terverifikasi,
        ),
      );
    }

    // Tampilkan data terbaru di urutan paling atas
    return list.reversed.toList();
  }

  /// Mengirim transaksi catatPresensi (berbayar gas testnet Sepolia)
  Future<String> catatPresensi(String nim, int pertemuanKe) async {
    await init();
    final nimHash = hashNimBytes(nim);

    final txHash = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _catatPresensiFn,
        parameters: [nimHash, BigInt.from(pertemuanKe)],
      ),
      chainId: BlockchainConfig.chainId,
    );

    await _tungguKonfirmasi(txHash);
    return txHash;
  }

  /// Mengirim transaksi verifikasiPresensi
  Future<String> verifikasiPresensi(int id) async {
    await init();

    final txHash = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _verifikasiPresensiFn,
        parameters: [BigInt.from(id)],
      ),
      chainId: BlockchainConfig.chainId,
    );

    await _tungguKonfirmasi(txHash);
    return txHash;
  }

  /// Fitur bonus: ubah nomor pertemuan oleh pengirim
  Future<String> ubahPertemuan(int id, int pertemuanBaru) async {
    await init();

    final txHash = await _client.sendTransaction(
      _credentials,
      Transaction.callContract(
        contract: _contract,
        function: _ubahPertemuanFn,
        parameters: [BigInt.from(id), BigInt.from(pertemuanBaru)],
      ),
      chainId: BlockchainConfig.chainId,
    );

    await _tungguKonfirmasi(txHash);
    return txHash;
  }

  /// Menunggu hingga transaksi masuk blok (receipt tersedia)
  Future<void> _tungguKonfirmasi(String txHash) async {
    const maxAttempts = 30; // ~60 detik
    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final receipt = await _client.getTransactionReceipt(txHash);
      if (receipt != null) {
        if (receipt.status == false) {
          throw Exception('Transaksi gagal dieksekusi di blockchain (reverted).');
        }
        return;
      }
    }
    throw Exception('Transaksi terkirim ($txHash), namun menunggu konfirmasi terlalu lama.');
  }

  void dispose() {
    if (_isInitialized) {
      _client.dispose();
    }
  }
}