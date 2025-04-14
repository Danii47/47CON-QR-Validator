import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

String decrypt(String encryptedBase64) {
  final secretKey = dotenv.env['SECRET_KEY']!;
  final key = encrypt.Key.fromUtf8(secretKey);

  try {
    final data = base64.decode(encryptedBase64.trim());
    final iv = encrypt.IV(Uint8List.fromList(data.sublist(0, 16)));
    final encryptedData = data.sublist(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
    final decrypted = encrypter.decrypt(encrypt.Encrypted(Uint8List.fromList(encryptedData)), iv: iv);

    return decrypted;
  } catch (e) {
    return "-";
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '47COn QR Validación',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('47CON QR Validación'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScannerPage()),
                );
              },
              child: const Text('Escanear QR'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersPage()),
                );
              },
              child: const Text('Ver Usuarios'),
            ),
          ],
        ),
      ),
    );
  }
}

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

    await docRef.update({ 'used': true });

    final player = AudioPlayer();
    await player.play(AssetSource('sounds/success.mp3'));

    await _showDialog('✅ Acceso válido', 'Nombre: $userName\nDNI: $dni');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () {
                controller.start();
              },
              child: const Text('Reiniciar Escaneo'),
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

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  String searchText = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    final snapshot = await firestore.FirebaseFirestore.instance.collection('users').get();
    final data = snapshot.docs.map((doc) => doc.data()).toList();

    setState(() {
      users = data.cast<Map<String, dynamic>>()
          .map((user) {
              user['dni'] = decrypt(user['dni']);
              return user;
          }).toList();
      filteredUsers = users;
    });
  }

  void _filterUsers(String value) {
    setState(() {
      searchText = value.toLowerCase();
      filteredUsers = users.where((user) {
        final dni = user['dni']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        final name = user['name']?.toString().toLowerCase() ?? '';
        final phone = user['phone']?.toString() ?? '';

        return dni.contains(searchText) || name.contains(searchText) || email.contains(searchText) || phone.contains(searchText);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios registrados'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre, DNI o email',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: StreamBuilder<firestore.QuerySnapshot>(
              stream: firestore.FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text('No hay usuarios'));
                }

                final docs = snapshot.data!.docs;
                users = docs.map((doc) => doc.data() as Map<String, dynamic>)
                    .map((user) {
                      user['dni'] = decrypt(user['dni']);
                      return user;
                    })
                    .toList();

                filteredUsers = searchText.isEmpty
                    ? users
                    : users.where((user) {
                        final dni = user['dni']?.toString().toLowerCase() ?? '';
                        final email = user['email']?.toString().toLowerCase() ?? '';
                        final name = user['name']?.toString().toLowerCase() ?? '';
                        final phone = user['phone']?.toString() ?? '';

                        return dni.contains(searchText) ||
                            name.contains(searchText) ||
                            email.contains(searchText) ||
                            phone.contains(searchText);
                }).toList();

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final dni = user['dni'].toUpperCase();
                    final email = user['email'];
                    final name = user['name'];
                    final phone = user['phone'];
                    final used = user['used'] ?? false;

                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            name,
                            style: TextStyle(
                              color: used ? Colors.grey : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'DNI: $dni\nCorreo: $email\nTeléfono: $phone',
                            style: TextStyle(
                              color: used ? Colors.grey : Colors.black,
                            ),
                          ),
                          trailing: Icon(
                            used ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: used ? Colors.green : Colors.orange,
                          ),
                          tileColor: used ? Colors.grey.shade200 : null,
                        ),
                        const Divider(height: 1)
                      ]
                    );
                  }
                );
              }
            )
          )
        ]
      )
    );
  }
}