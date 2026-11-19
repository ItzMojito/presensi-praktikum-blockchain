import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/presensi_service.dart';

class TambahPresensiScreen extends StatefulWidget {
  final PresensiService service;

  const TambahPresensiScreen({super.key, required this.service});

  @override
  State<TambahPresensiScreen> createState() => _TambahPresensiScreenState();
}

class _TambahPresensiScreenState extends State<TambahPresensiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nimController = TextEditingController();

  int _pertemuanKe = 1;
  bool _isSubmitting = false;
  String? _previewHash;
  String? _statusMessage;
  String? _txHash;
  bool _isError = false;

  @override
  void dispose() {
    _nimController.dispose();
    super.dispose();
  }

  void _updatePreviewHash(String value) {
    setState(() {
      _previewHash = value.trim().isEmpty ? null : widget.service.hashNimHex(value);
    });
  }

  Future<void> _submitPresensi() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _isError = false;
      _txHash = null;
      _statusMessage = 'Mengirim transaksi ke Sepolia & menunggu konfirmasi blok...';
    });

    try {
      final txHash = await widget.service.catatPresensi(
        _nimController.text,
        _pertemuanKe,
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isError = false;
        _txHash = txHash;
        _statusMessage = 'Presensi berhasil dicatat on-chain!';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _isError = true;
        _statusMessage = 'Gagal mencatat presensi: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catat Presensi Praktikum')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.teal),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'NIM akan di-hash (Keccak-256) sebelum dikirim ke smart contract agar data pribadi tidak terbuka di blockchain publik.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nimController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'NIM Mahasiswa',
                  hintText: 'Contoh: 246661018',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                onChanged: _updatePreviewHash,
                validator: (v) =>
                    (v == null || v.trim().length < 5) ? 'Masukkan NIM yang valid' : null,
              ),
              if (_previewHash != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pratinjau Hash NIM (yang dikirim on-chain):',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _previewHash!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _pertemuanKe,
                decoration: const InputDecoration(
                  labelText: 'Pertemuan Ke-',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                items: List.generate(
                  16,
                  (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text('Pertemuan ke-${i + 1}'),
                  ),
                ),
                onChanged: _isSubmitting
                    ? null
                    : (val) => setState(() => _pertemuanKe = val ?? 1),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitPresensi,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: Text(_isSubmitting ? 'Memproses Transaksi...' : 'Kirim Presensi On-Chain'),
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _isSubmitting
                        ? Colors.blue.shade50
                        : (_isError ? Colors.red.shade50 : Colors.green.shade50),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isSubmitting
                          ? Colors.blue
                          : (_isError ? Colors.red : Colors.green),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isSubmitting
                              ? Colors.blue.shade900
                              : (_isError ? Colors.red.shade900 : Colors.green.shade900),
                        ),
                      ),
                      if (_txHash != null) ...[
                        const SizedBox(height: 8),
                        const Text('Transaction Hash:', style: TextStyle(fontSize: 12)),
                        SelectableText(
                          _txHash!,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _txHash!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tx Hash disalin ke clipboard')),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Salin Hash'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Kembali ke Daftar'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}