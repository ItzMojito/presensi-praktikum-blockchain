import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/presensi_model.dart';
import '../services/presensi_service.dart';
import 'tambah_presensi_screen.dart';

enum FilterPresensi { semua, terverifikasi, belum, milikSaya }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PresensiService _service = PresensiService();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  List<PresensiModel> _semuaPresensi = [];
  FilterPresensi _filterAktif = FilterPresensi.semua;
  String? _highlightNimHash;
  double? _saldoEth;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _muatData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _service.init();
      final data = await _service.ambilSemuaPresensi();
      final saldo = await _service.ambilSaldoEth();

      if (!mounted) return;
      setState(() {
        _semuaPresensi = data;
        _saldoEth = saldo;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<PresensiModel> get _daftarTerfilter {
    return _semuaPresensi.where((item) {
      switch (_filterAktif) {
        case FilterPresensi.semua:
          return true;
        case FilterPresensi.terverifikasi:
          return item.terverifikasi;
        case FilterPresensi.belum:
          return !item.terverifikasi;
        case FilterPresensi.milikSaya:
          return item.pengirim.hex.toLowerCase() ==
              _service.myAddress.hex.toLowerCase();
      }
    }).toList();
  }

  Future<void> _jalankanTransaksi({
    required String judul,
    required Future<String> Function() aksi,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text('$judul...\nMenunggu konfirmasi Sepolia.')),
          ],
        ),
      ),
    );

    try {
      final txHash = await aksi();
      if (!mounted) return;
      Navigator.pop(context); // Tutup dialog loading

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Transaksi Berhasil'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Transaction Hash:'),
              const SizedBox(height: 6),
              SelectableText(
                txHash,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: txHash));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tx Hash disalin')),
                );
              },
              child: const Text('Salin Hash'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      _muatData();
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tutup dialog loading

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Transaksi Gagal'),
            ],
          ),
          content: Text(e.toString()),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _tampilkanDialogEditPertemuan(PresensiModel item) async {
    int pertemuanBaru = item.pertemuanKe;
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: Text('Ubah Pertemuan (ID #${item.id})'),
          content: DropdownButtonFormField<int>(
            value: pertemuanBaru,
            decoration: const InputDecoration(
              labelText: 'Pertemuan Baru',
              border: OutlineInputBorder(),
            ),
            items: List.generate(
              16,
              (i) => DropdownMenuItem(value: i + 1, child: Text('Pertemuan ke-${i + 1}')),
            ),
            onChanged: (v) => setModalState(() => pertemuanBaru = v ?? item.pertemuanKe),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Simpan')),
          ],
        ),
      ),
    );

    if (konfirmasi == true && pertemuanBaru != item.pertemuanKe) {
      _jalankanTransaksi(
        judul: 'Memperbarui pertemuan ke-$pertemuanBaru',
        aksi: () => _service.ubahPertemuan(item.id, pertemuanBaru),
      );
    }
  }

  Future<void> _tampilkanDialogCekNim() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cek NIM di Daftar'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Masukkan NIM',
            hintText: 'Akan dicocokkan dengan hash secara lokal',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _highlightNimHash = null);
              Navigator.pop(ctx);
            },
            child: const Text('Reset'),
          ),
          FilledButton(
            onPressed: () {
              final nim = controller.text.trim();
              setState(() {
                _highlightNimHash = nim.isEmpty ? null : _service.hashNimHex(nim);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Cocokkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = _daftarTerfilter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Praktikum On-Chain'),
        actions: [
          IconButton(
            tooltip: 'Cek NIM',
            onPressed: _tampilkanDialogCekNim,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Muat Ulang',
            onPressed: _muatData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_saldoEth != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.teal.shade50,
              child: Text(
                'Jaringan: Sepolia | Saldo Wallet: ${_saldoEth!.toStringAsFixed(4)} ETH',
                style: TextStyle(fontSize: 12, color: Colors.teal.shade900),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('Semua', FilterPresensi.semua),
                const SizedBox(width: 8),
                _buildFilterChip('Terverifikasi', FilterPresensi.terverifikasi),
                const SizedBox(width: 8),
                _buildFilterChip('Belum Verifikasi', FilterPresensi.belum),
                const SizedBox(width: 8),
                _buildFilterChip('Wallet Saya', FilterPresensi.milikSaya),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center),
                              const SizedBox(height: 12),
                              FilledButton(onPressed: _muatData, child: const Text('Coba Lagi')),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _muatData,
                        child: items.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 120),
                                  Center(child: Text('Belum ada data presensi tercatat.')),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: items.length,
                                itemBuilder: (_, index) => _buildPresensiCard(items[index]),
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => TambahPresensiScreen(service: _service)),
          );
          if (added == true) _muatData();
        },
        icon: const Icon(Icons.add_task),
        label: const Text('Catat Presensi'),
      ),
    );
  }

  Widget _buildFilterChip(String label, FilterPresensi value) {
    return ChoiceChip(
      label: Text(label),
      selected: _filterAktif == value,
      onSelected: (_) => setState(() => _filterAktif = value),
    );
  }

  Widget _buildPresensiCard(PresensiModel item) {
    final isMatchedNim =
        _highlightNimHash != null &&
        item.nimHashHex.toLowerCase() == _highlightNimHash!.toLowerCase();

    return Card(
      color: isMatchedNim
          ? Colors.amber.shade50
          : (item.terverifikasi ? Colors.green.shade50 : null),
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.terverifikasi ? Icons.verified : Icons.hourglass_bottom,
                  color: item.terverifikasi ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pertemuan ke-${item.pertemuanKe} (ID #${item.id})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: item.terverifikasi ? Colors.green.shade900 : null,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    item.terverifikasi ? 'Terverifikasi' : 'Menunggu',
                    style: const TextStyle(fontSize: 11),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Hash NIM: ${item.shortHash}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            Text(
              'Waktu Hadir: ${_dateFormat.format(item.waktuHadir)}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              'Pengirim: ${item.shortPengirim}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (isMatchedNim)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Cocok dengan NIM yang kamu cari',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
            if (!item.terverifikasi) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _tampilkanDialogEditPertemuan(item),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Ubah Pertemuan'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _jalankanTransaksi(
                      judul: 'Memverifikasi presensi #${item.id}',
                      aksi: () => _service.verifikasiPresensi(item.id),
                    ),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Verifikasi'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}