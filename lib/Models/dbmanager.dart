import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbBookManager {
  Database? _database;

  Future openDb() async {
    if (_database == null) {
      _database = await openDatabase(
          join(await getDatabasesPath(), "booksProj.db"),
          version: 1, onCreate: (Database db, int version) async {
        await db.execute(
          "CREATE TABLE book(id INTEGER PRIMARY KEY autoincrement, name TEXT, author Text, desc TEXT, user TEXT, fav TEXT)",
        );
      });
    }
  }

  Future<int> insertBook(Book book) async {
    await openDb();
    return await _database!.insert('book', book.toMap());
  }

  Future<List<Book>> getBookList(String? user) async {
    await openDb();
    final List<Map<String, dynamic>> maps = await _database!
        .query('book', where: "user = ? ORDER BY name", whereArgs: [user]);
    return List.generate(maps.length, (i) {
      return Book(
        id: maps[i]['id'],
        name: maps[i]['name'],
        desc: maps[i]['desc'],
        author: maps[i]['author'],
        user: maps[i]['user'],
        fav: maps[i]['fav'] == 'true',
      );
    });
  }

  Future<List<Book>> getSearchBookList(String filter, String? user) async {
    await openDb();
    final List<Map<String, dynamic>> maps = await _database!.query('book',
        where: "user = ? AND name LIKE ? ORDER BY name",
        whereArgs: [user, '%$filter%']);
    return List.generate(maps.length, (i) {
      return Book(
        id: maps[i]['id'],
        name: maps[i]['name'],
        desc: maps[i]['desc'],
        author: maps[i]['author'],
        user: maps[i]['user'],
        fav: maps[i]['fav'] == 'true'
      );
    });
  }

  Future<int> updateBook(Book book) async {
    await openDb();
    return await _database!.rawUpdate('''
    UPDATE book
    SET name = ?, author = ?, desc = ?,fav = ?
    WHERE id = ? AND user = ?
    ''', [book.name,book.author,book.desc,book.fav.toString(),book.id, book.user]);
  }

  Future<void> deleteBook(int? id, String? user) async {
    await openDb();
    await _database!
        .delete('book', where: "user = ? AND id = ?", whereArgs: [user, id]);
  }

  Future<int> updateBookFav(Book book,String fav) async{
    await openDb();
    return await _database!.rawUpdate('''
    UPDATE book
    SET fav = ?
    WHERE id = ? AND user = ?
    ''', [fav,book.id, book.user]);
  }

  Future<Set<Book>> getBookFav(String? user) async {
    await openDb();
    final List<Map<String, dynamic>> maps = await _database!
        .query('book', where: "user = ? AND fav = ? ORDER BY name", whereArgs: [user,"true"]);
    List<Book> res= List.generate(maps.length, (i) {
      return Book(
        id: maps[i]['id'],
        name: maps[i]['name'],
        desc: maps[i]['desc'],
        author: maps[i]['author'],
        user: maps[i]['user'],
        fav: maps[i]['fav'] == 'true',
      );
    });
    return res.toSet();
  }

}

class Book {
  final int? id;
  final String name;
  final String author;
  final String desc;
  final String? user;
  final bool? fav;

  Book(
      {this.id,
      required this.name,
      required this.author,
      required this.desc,
      this.user,
      this.fav});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'author': author,
      'desc': desc,
      'user': user,
      'fav': fav
    };
  }
}
