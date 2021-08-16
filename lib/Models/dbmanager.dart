import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbBookManager {
  Database? _database;

  Future openDb() async {
    if (_database == null) {
      _database = await openDatabase(join(await getDatabasesPath(), "books.db"),
          version: 1, onCreate: (Database db, int version) async {
        await db.execute(
          "CREATE TABLE book(id INTEGER PRIMARY KEY autoincrement, name TEXT, author Text, desc TEXT)",
        );
      });
    }
  }

  Future<int> insertBook(Book book) async {
    await openDb();
    return await _database!.insert('book', book.toMap());
  }

  Future<List<Book>> getBookList() async {
    await openDb();
    final List<Map<String, dynamic>> maps = await _database!.query('book');
    return List.generate(maps.length, (i) {
      return Book(
          id: maps[i]['id'],
          name: maps[i]['name'],
          desc: maps[i]['desc'],
          author: maps[i]['author']);
    });
  }

  Future<List<Book>> getSearchBookList(String filter) async {
    await openDb();
    final List<Map<String, dynamic>> maps = await _database!.query(
        'book',
        where: "name LIKE ?",
        whereArgs: ['%$filter%']
    );
    return List.generate(maps.length, (i) {
      return Book(
          id: maps[i]['id'],
          name: maps[i]['name'],
          desc: maps[i]['desc'],
          author: maps[i]['author']);
    });
  }


  Future<int> updateBook(Book book) async {
    await openDb();
    return await _database!
        .update('book', book.toMap(), where: "id = ?", whereArgs: [book.id]);
  }

  Future<void> deleteBook(int? id) async {
    await openDb();
    await _database!.delete('book', where: "id = ?", whereArgs: [id]);
  }
}

class Book {
  final int? id;
  final String name;
  final String author;
  final String desc;

  Book({this.id, required this.name, required this.author, required this.desc});

  Map<String, dynamic> toMap() {
    return {'name': name, 'author': author, 'desc': desc};
  }
}
