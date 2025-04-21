import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import '../utils/decrypt.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool scanned = false;

  Future<void> _showDialog(String title, String content) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    controller.start();
  }

  bool _isValidQR(String qr) {
    final regex = RegExp(r'^[a-fA-F0-9]{64}$'); // Para un hash SHA-256
    return regex.hasMatch(qr);
  }

  Future<void> _manageCode(String hash) async {
    if (!_isValidQR(hash)) {
      _showDialog('⛔ QR inválido', 'Este QR no está registrado.');
      return;
    }

    final docRef = firestore.FirebaseFirestore.instance.collection('users').doc(hash);
    final doc = await docRef.get(const firestore.GetOptions(source: firestore.Source.server));

    if (!doc.exists) {
      _showDialog('⛔ QR inválido', 'Este QR no está registrado.');
      return;
    }

    final data = doc.data()!;

    final dni = decrypt(data['dni']).toUpperCase();
    final userName = data['name'];
    final used = data['used'] ?? false;

    if (used) {
      _showDialog('⚠️ QR ya utilizado', 'Este QR ya fue validado anteriormente.');
      return;
    }

    await docRef.update({ 'used': true, 'scanTimestamp': DateTime.now().millisecondsSinceEpoch });

    final player = AudioPlayer();
    await player.play(AssetSource('sounds/success.mp3'));

    await _showDialog('✅ Acceso válido', 'Nombre: $userName\nDNI: $dni');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EAFF),
      appBar: AppBar(
        backgroundColor: Color(0xFFFFFFFF),
        title: const Text('Escáner de QR'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: controller,
              onDetect: (BarcodeCapture capture) {
                if (capture.barcodes.isEmpty || scanned) return;

                final barcode = capture.barcodes.first;

                if (barcode.rawValue == null) return;

                final String code = barcode.rawValue ?? '';

                controller.stop();
                _manageCode(code);
              },
            ),
          ),

          Expanded(
            flex: 1,
            child: Center(
              child: const Text('Escanea un código QR', style: TextStyle(fontSize: 18)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: () {
                controller.start();
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Color(0xFF8A5991),
                backgroundColor: Color(0xFFFFFFFF),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Reiniciar Escaneo',
                style: TextStyle(fontSize: 18)
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}