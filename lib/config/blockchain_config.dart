import 'package:flutter_dotenv/flutter_dotenv.dart';

class BlockchainConfig {
  static String get rpcUrl => dotenv.env['RPC_URL'] ?? '';
  static String get contractAddress => dotenv.env['CONTRACT_ADDRESS'] ?? '';
  static int get chainId => int.tryParse(dotenv.env['CHAIN_ID'] ?? '11155111') ?? 11155111;
  static String get privateKey => dotenv.env['PRIVATE_KEY'] ?? '';
  static const String abiAssetPath = 'assets/abi/presensi_abi.json';
  static const String etherscanTxBase = 'https://sepolia.etherscan.io/tx/';

  static void validate() {
    if (rpcUrl.isEmpty || contractAddress.isEmpty || privateKey.isEmpty) {
      throw Exception(
        'Konfigurasi .env belum lengkap. Pastikan RPC_URL, CONTRACT_ADDRESS, CHAIN_ID, dan PRIVATE_KEY sudah diisi.',
      );
    }
  }
}