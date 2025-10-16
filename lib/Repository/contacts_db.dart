import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sembast/sembast.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:contacts_app/Models/contact_model.dart';

/// Interface abstrata para repositórios de contatos
abstract class ContactRepository {
  Future<List<Contact>> getAllContacts();
  Future<void> insertContact(Contact contact);
  Future<void> updateContact(Contact contact);
  Future<void> deleteContact(Contact contact);

  /// Fábrica que retorna a implementação adequada para a plataforma
  factory ContactRepository() {
    if (kIsWeb) {
      return ContactRepositorySembastWeb();
    } else if (Platform.isAndroid || Platform.isIOS) {
      return ContactRepositorySqflite();
    } else {
      throw UnsupportedError('Plataforma não suportada');
    }
  }
}

//////////////////////////
// SQFLITE (Android / iOS)
//////////////////////////

class ContactRepositorySqflite implements ContactRepository {
  static sqflite.Database? _database;
  static const String tableName = 'contacts';

  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<sqflite.Database> _initDB() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'contacts.db');

    return await sqflite.openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT,
            email TEXT
          )
        ''');
      },
    );
  }

  @override
  Future<List<Contact>> getAllContacts() async {
    final db = await database;
    final maps = await db.query(tableName);
    return maps.map((map) => Contact.fromMap(map)).toList();
  }

  @override
  Future<void> insertContact(Contact contact) async {
    final db = await database;
    await db.insert(tableName, contact.toMap());
  }

  @override
  Future<void> updateContact(Contact contact) async {
    final db = await database;
    if (contact.id == null) throw Exception('ID do contato é nulo.');
    await db.update(
      tableName,
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  @override
  Future<void> deleteContact(Contact contact) async {
    final db = await database;
    if (contact.id == null) throw Exception('ID do contato é nulo.');
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }
}

//////////////////////////
// SEMBAST (Web)
//////////////////////////

class ContactRepositorySembastWeb implements ContactRepository {
  static const String dbName = 'contacts.db';
  static const String storeName = 'contacts';
  var factory = databaseFactoryWeb;

  var _db;

  final StoreRef<int, Map<String, dynamic>> store = intMapStoreFactory.store(storeName);

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await databaseFactoryWeb.openDatabase(dbName);
    return _db!;
  }

  @override
  Future<List<Contact>> getAllContacts() async {
    final database = await db;
    final records = await store.find(database);
    return records.map((record) {
      final data = Map<String, dynamic>.from(record.value);
      data['id'] = record.key;
      return Contact.fromMap(data);
    }).toList();
  }

  @override
  Future<void> insertContact(Contact contact) async {
    final database = await db;
    await store.add(database, contact.toMap());
  }

  @override
  Future<void> updateContact(Contact contact) async {
    final database = await db;
    if (contact.id == null) throw Exception('ID do contato é nulo.');
    await store.record(contact.id!).update(database, contact.toMap());
  }

  @override
  Future<void> deleteContact(Contact contact) async {
    final database = await db;
    if (contact.id == null) throw Exception('ID do contato é nulo.');
    await store.record(contact.id!).delete(database);
  }
}
