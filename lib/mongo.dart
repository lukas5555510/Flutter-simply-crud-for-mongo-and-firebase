import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;


class User {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;

  User({required this.id, required this.name, required this.email, required this.phoneNumber});
}

class MongoDBScreen extends StatefulWidget {
  @override
  _MongoDBScreenState createState() => _MongoDBScreenState();
}

class _MongoDBScreenState extends State<MongoDBScreen> {
  static connect() async {
    var db =
    await mongo.Db.create("mongodb+srv://test:test@cluster0.gdsa1av.mongodb.net/crud?retryWrites=true&w=majority");
    await db.open();
    inspect(db);
    var status = db.serverStatus();
    print(status);
    var collection = db.collection('users');
    print(await collection.find().toList());
    return db;
  }
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  User? _selectedUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mongo CRUD - Users'),
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
            onPressed: () async {
              if (_selectedUser == null) {
                await _addUser(
                  _nameController.text,
                  _emailController.text,
                  _phoneNumberController.text,
                );
              } else {
                await _updateUser(
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
              Navigator.pop(context);
            },
            child: Text('Come back to Firebase Screen'),
          ),
          FutureBuilder<List<User>>(
            future: _getUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('No Users found');
              } else {
                return Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final user = snapshot.data![index];

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
                            _getUsers();
                          },
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addUser(String name, String email, String phoneNumber) async {
    await _addUserToMongoDB(name, email, phoneNumber);
    _clearControllers();
  }

  Future<void> _updateUser(String userId, String name, String email, String phoneNumber) async {
    await _updateUserInMongoDB(userId, name, email, phoneNumber);
    _clearControllers();
    _clearSelectedUser();
  }

  Future<void> _deleteUser(String userId) async {
    await _deleteUserInMongoDB(userId);
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

  Future<List<User>> _getUsers() async {
    var db = await mongo.Db.create("mongodb+srv://test:test@cluster0.gdsa1av.mongodb.net/crud?retryWrites=true&w=majority");
    await db.open();
    var collection = db.collection('users');
    var results = await collection.find().toList();
    db.close();

    List<User> userList = results.map((data) {
      return User(
        id: data['_id'].toString(), // Załóżmy, że id jest przechowywane jako '_id' w Mapie
        name: data['name'],
        email: data['email'],
        phoneNumber: data['phone'],
      );
    }).toList();

    return userList;
  }

  Future<void> _addUserToMongoDB(String name, String email, String phoneNumber) async {
    var db =
    await mongo.Db.create("mongodb+srv://test:test@cluster0.gdsa1av.mongodb.net/crud?retryWrites=true&w=majority");
    await db.open();
    var collection = db.collection('users');
    collection.insert({"name":name,"email":email,"phone":phoneNumber});
    db.close();
    setState(() {});
  }

  Future<void> _updateUserInMongoDB(String userId, String name, String email, String phoneNumber) async {
    var db = await mongo.Db.create("mongodb+srv://test:test@cluster0.gdsa1av.mongodb.net/crud?retryWrites=true&w=majority");
    await db.open();
    var collection = db.collection('users');

    var updateData = {
      "name": name,
      "email": email,
      "phone": phoneNumber,
    };

    await collection.update(
      mongo.where.eq('_id', mongo.ObjectId.parse(normalizeIdString(userId))),
      {'\$set': updateData},
    );
    setState(() {});
    db.close();
  }

  Future<void> _deleteUserInMongoDB(String userId) async {
    var db = await mongo.Db.create("mongodb+srv://test:test@cluster0.gdsa1av.mongodb.net/crud?retryWrites=true&w=majority");
    await db.open();
    var collection = db.collection('users');

    var deleteCondition = {
      "_id": mongo.ObjectId.parse(normalizeIdString(userId)),
    };

    await collection.deleteOne(deleteCondition);

    db.close();
    setState(() {});
  }
  normalizeIdString(String s){
    return s.replaceAll('ObjectId("', '').replaceAll('")', '');
  }
}
