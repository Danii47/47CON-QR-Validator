import 'package:flutter/material.dart';
import 'scanner_page.dart';
import 'users_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5EAFF),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF5EAFF)],
              stops: [
                0.95,
                1.0  // pinkAccent del 50% al 100%
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text('47CON QR Validación'),
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.35,
            child: Center(
              child: Image.asset(
                'assets/imgs/sugus_icon.png',
                width: 300,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 90.0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Color(0xFF8A5991),
                        backgroundColor: Color(0xFFFFFFFF),
                      ),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text(
                        'Escanear QR',
                        style: TextStyle(fontSize: 18)
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersPage()));
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Color(0xFF8A5991),
                        backgroundColor: Color(0xFFFFFFFF),
                      ),
                      icon: const Icon(Icons.people),
                      label: const Text(
                        'Ver Usuarios',
                        style: TextStyle(fontSize: 18)
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}