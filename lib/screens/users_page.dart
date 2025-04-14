import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import '../utils/decrypt.dart';

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
      backgroundColor: const Color(0xFFF5EAFF),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFF5EAFF)],
              stops: [
                0.95,
                1.0
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text('Usuarios registrados'),
      ),
      body: Stack(
        children: [
          Opacity(
            opacity: 0.05,
            child: Center(
              child: Image.asset(
                'assets/imgs/sugus_icon.png',
                width: 300,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar por nombre, DNI, email o teléfono',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12))
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFF8d7591))
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFF8A5991))
                    ),
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
                      }).toList();

                    filteredUsers = searchText.isEmpty
                      ? users
                      : users.where((user) {
                        final dni = user['dni']?.toString().toLowerCase() ?? '';
                        final email = user['email']?.toString().toLowerCase() ?? '';
                        final name = user['name']?.toString().toLowerCase() ?? '';
                        final phone = user['phone']?.toString() ?? '';

                        return dni.contains(searchText) || name.contains(searchText) || email.contains(searchText) || phone.contains(searchText);
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
        ]
      )
    );
  }
}