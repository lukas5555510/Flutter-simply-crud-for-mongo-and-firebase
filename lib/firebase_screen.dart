import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'mongo.dart';

class FirestoreCrudScreen extends StatefulWidget {
  const FirestoreCrudScreen({super.key});

  @override
  _FirestoreCrudScreenState createState() => _FirestoreCrudScreenState();
}

class User {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;

  User({required this.id, required this.name, required this.email, required this.phoneNumber});
}

class _FirestoreCrudScreenState extends State<FirestoreCrudScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  final CollectionReference _collection = FirebaseFirestore.instance.collection('users');

  User? _selectedUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firestore CRUD - Users'),
      ),
      body: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _phoneNumberController,
            decoration: InputDecoration(labelText: 'Phone Number'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_selectedUser == null) {
                _addUser(
                  _nameController.text,
                  _emailController.text,
                  _phoneNumberController.text,
                );
              } else {
                _updateUser(
                  _selectedUser!.id,
                  _nameController.text,
                  _emailController.text,
                  _phoneNumberController.text,
                );
              }
            },
            child: Text('Add User / Update User'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MongoDBScreen()));
            },
            child: Text('Go to MongoDB Screen'),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _collection.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();

              return Expanded(
                child: ListView(
                  children: snapshot.data!.docs.map((doc) {
                    final user = User(
                      id: doc.id,
                      name: doc['name'],
                      email: doc['email'],
                      phoneNumber: doc['phoneNumber'],
                    );

                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text(user.email),
                      onTap: () {
                        _selectUser(user);
                      },
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _deleteUser(user.id);
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _addUser(String name, String email, String phoneNumber) {
    _collection.add({
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
    });

    _clearControllers();
  }

  void _updateUser(String userId, String name, String email, String phoneNumber) {
    _collection.doc(userId).update({
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
    });

    _clearControllers();
    _clearSelectedUser();
  }

  void _deleteUser(String userId) {
    _collection.doc(userId).delete();
    _clearSelectedUser();
  }

  void _selectUser(User user) {
    _selectedUser = user;
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneNumberController.text = user.phoneNumber;
  }

  void _clearSelectedUser() {
    _selectedUser = null;
    _clearControllers();
  }

  void _clearControllers() {
    _nameController.clear();
    _emailController.clear();
    _phoneNumberController.clear();
  }
}
