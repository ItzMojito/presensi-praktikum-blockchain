# Presensi Praktikum On-Chain (Flutter + Ethereum Sepolia)

Aplikasi Flutter untuk mencatat dan memverifikasi presensi praktikum secara terdesentralisasi menggunakan smart contract Solidity di jaringan uji Ethereum Sepolia.

## Anggota Kelompok
- Juliandi Rahman Anwar (246661018)
- Syahla Nabillah (246661011)

## Informasi Smart Contract
- **Jaringan:** Ethereum Sepolia Testnet (Chain ID: `11155111`)
- **Alamat Kontrak:** `0xBf29312EB86a091Fc6DE8dc7C12169F21277f67e`
- **Link Etherscan (Terverifikasi):** https://sepolia.etherscan.io/address/0xBf29312EB86a091Fc6DE8dc7C12169F21277f67e
- **File Sumber:** `contracts/PresensiPraktikum.sol`

## Versi Paket & SDK
- Flutter SDK: `3.x.x`
- `web3dart`: `2.7.3`
- `http`: `1.2.2`
- `flutter_dotenv`: `5.1.0`
- `intl`: `0.19.0`

## Cara Menjalankan Proyek
1. Clone repositori ini.
2. Salin `.env.example` menjadi `.env`, lalu isi `RPC_URL`, `CONTRACT_ADDRESS`, `CHAIN_ID`, dan `PRIVATE_KEY` (gunakan wallet khusus testnet Sepolia).
3. Jalankan `flutter pub get`.
4. Jalankan aplikasi dengan `flutter run` di emulator atau perangkat Android.

## Fitur yang Diimplementasikan
- [x] Pencatatan presensi dengan NIM di-hash lokal (Keccak-256)
- [x] Pembacaan daftar presensi on-chain & indikator status transaksi
- [x] Verifikasi presensi on-chain & pembedaan tampilan item terverifikasi
- [x] Pull-to-refresh & konfigurasi terpusat
- [x] Bonus: Filter status/wallet, validasi anti-duplikasi presensi, ubah pertemuan, & fitur Cek NIM lokal

## Sumber Kode yang Diadaptasi
- Kerangka smart contract diadaptasi dari `ChainTodo.sol` pada dokumen Tugas Proyek Pemrograman Mobile 2.
- Referensi integrasi `web3dart` mengikuti dokumentasi resmi Ethereum untuk pengembang Dart dan `pub.dev/packages/web3dart`.