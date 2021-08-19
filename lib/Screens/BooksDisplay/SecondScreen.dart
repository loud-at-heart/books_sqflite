import 'dart:async';

import 'package:books_sqflite/Models/dbmanager.dart';
import 'package:books_sqflite/Screens/BooksDisplay/Display.dart';
import 'package:books_sqflite/Widgets/custom_dialog_box.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_gravatar/flutter_gravatar.dart';

class SecondScreen extends StatefulWidget {
  const SecondScreen({Key? key}) : super(key: key);

  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  bool isloggedin = false;
  String query = '';
  final DbBookManager dbmanager = new DbBookManager();
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _authorController = TextEditingController();
  final _descController = TextEditingController();
  final _formKey = new GlobalKey<FormState>();
  Book? book;
  List<Book>? booklist = [];
  late final SlidableController slidableController;
  int? id;
  bool? fav;
  Set<Book>_saved = {};

  checkAuthentification() async {
    _auth.authStateChanges().listen((user) {
      if (user == null && mounted) {
        Navigator.of(context).pushReplacementNamed("start");
      }
    });
  }

  getUser() async {
    User? firebaseUser = _auth.currentUser;
    await firebaseUser?.reload();
    firebaseUser = _auth.currentUser;

    if (firebaseUser != null) {
      setState(() {
        this.user = firebaseUser!;
        this.isloggedin = true;
      });
    }
  }

  signOut() async {
    _auth.signOut();

    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  }

  @override
  void initState() {
    super.initState();
    this.checkAuthentification();
    this.getUser();
    Timer(Duration(milliseconds: 1000), () => searchBooks());

    slidableController = SlidableController(
      onSlideAnimationChanged: handleSlideAnimationChanged,
      onSlideIsOpenChanged: handleSlideIsOpenChanged,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Animation<double>? _rotationAnimation;
  Color _fabColor = Colors.blue;

  void handleSlideAnimationChanged(Animation<double>? slideAnimation) {
    setState(() {
      _rotationAnimation = slideAnimation;
    });
  }

  void handleSlideIsOpenChanged(bool? isOpen) {
    setState(() {
      _fabColor = isOpen! ? Colors.green : Colors.blue;
    });
  }

  void searchQuery(String query) async {
    print('Started Query Searching');
    if (query.isNotEmpty) {
      List<Book> result = await dbmanager.getSearchBookList(query, user!.email);
      print(result.length);
      setState(() {
        booklist = result;
      });
    }
  }

  void _pushAdd() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          double width = MediaQuery.of(context).size.width;
          return Scaffold(
            appBar: AppBar(
                backgroundColor: Colors.white,
                automaticallyImplyLeading: false,
                textTheme: Theme.of(context).textTheme,
                toolbarHeight: 90.0,
                elevation: 0.0,
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(90),
                  child: ListTile(
                      leading: InkWell(
                        child: SvgPicture.asset('assets/images/Back.svg'),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      title: Text(
                        id == null ? "Add Book" : "Update Book",
                        style: TextStyle(
                          fontSize: 30.0,
                          color: Color(0xff5E56E7),
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                        ),
                      )),
                )),
            body: ListView(
              children: <Widget>[
                Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                    textInputAction: TextInputAction.next,
                          decoration: new InputDecoration(
                              labelText: 'Book Name',
                              hintText: "Enter Book Name"),
                          controller: _nameController,
                          validator: (val) => val!.isNotEmpty
                              ? null
                              : 'Name Should Not Be empty',
                        ),
                        TextFormField(
                          textInputAction: TextInputAction.next,
                          decoration: new InputDecoration(
                              labelText: 'Author',
                              hintText: "Enter Author Name"),
                          controller: _authorController,
                          validator: (val) => val!.isNotEmpty
                              ? null
                              : 'Author Should Not Be empty',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: TextFormField(
                            controller: _descController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: "Description",
                              hintText: "Enter Description",
                              fillColor: Colors.white,
                              border: new OutlineInputBorder(
                                borderRadius: new BorderRadius.circular(25.0),
                                borderSide: new BorderSide(),
                              ),
                            ),
                            validator: (val) => val!.isNotEmpty
                                ? null
                                : 'Description Should Not Be empty',
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              primary: Color(0xff5E56E7)),
                          child: Container(
                              width: width * 0.9,
                              child: Text(
                                id == null ? 'Submit' : 'Update',
                                textAlign: TextAlign.center,
                              )),
                          onPressed: () {
                            id == null
                                ? _submitBook(context)
                                : _updateBook(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          final tiles = _saved.map(
                (Book book) {
              return ListTile(
                leading: Icon(Icons.book),
                title: Text(
                  book.name,
                ),
                subtitle: Text(
                  book.author
                ),
                onTap: () {
                  FocusScope.of(context).unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => BookDisplay(
                          bk: book,
                        )),
                  );
                },
              );
            },
          );
          final divided = tiles.isNotEmpty
              ? ListTile.divideTiles(context: context, tiles: tiles).toList()
              : <Widget>[];

          return Scaffold(
            appBar: AppBar(
                backgroundColor: Colors.white,
                automaticallyImplyLeading: false,
                textTheme: Theme.of(context).textTheme,
                toolbarHeight: 90.0,
                elevation: 0.0,
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(90),
                  child: ListTile(
                      leading: InkWell(
                        child: SvgPicture.asset('assets/images/Back.svg'),
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      title: Text(
                        "Favourites",
                        style: TextStyle(
                          fontSize: 30.0,
                          color: Color(0xff5E56E7),
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                        ),
                      )),
                )),
            body: ListView(children: divided),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        textTheme: Theme.of(context).textTheme,
        toolbarHeight: 175.0,
        elevation: 0.0,
        bottom: PreferredSize(
          child: Column(
            children: [
              user != null
                  ? ListTile(
                      /*leading: InkWell(
                        child: Icon(Icons.power_settings_new),
                        onTap: signOut,
                      ),*/
                      title: Text(
                        "Hello ${user!.displayName}",
                        style: TextStyle(
                          fontSize: 30.0,
                          color: Color(0xff5E56E7),
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Wrap(
                        spacing: 12,
                        children: [
                          InkWell(
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Color(0xff5E56E7),
                              child: CircleAvatar(
                                radius: 17,
                                backgroundImage: NetworkImage(
                                    Gravatar(user!.email.toString())
                                        .imageUrl(defaultImage: "identicon")),
                              ),
                            ),
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return CustomDialogBox(
                                      title: "Hi ${user!.displayName} !",
                                      descriptions:
                                          "Hello ${user!.displayName} you are Logged in as ${user!.email}",
                                      text: "Logout",
                                      img: Gravatar(user!.email.toString())
                                          .imageUrl(defaultImage: "identicon"),
                                      func: signOut,
                                    );
                                  });
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.favorite,color: Colors.red,),
                            onPressed: () {
                              _pushSaved();
                            },
                          )
                        ],
                      ),
                    )
                  : SizedBox(
                      child: CircularProgressIndicator(),
                      height: 50.0,
                      width: 50.0,
                    ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  textInputAction: TextInputAction.search,
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: TextStyle(
                      color: Color(0xFFA0A0A0),
                    ),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Theme.of(context).accentColor),
                    ),
                    filled: true,
                    fillColor: Color(0xFFF0F0F6),
                    focusColor: Color(0xFFF0F0F6),
                    prefixIcon: SvgPicture.asset(
                      'assets/images/Search.svg',
                      fit: BoxFit.none,
                    ),
                    suffixIcon: query.isNotEmpty
                        ? InkWell(
                            child: SvgPicture.asset(
                              'assets/images/Cancel.svg',
                              fit: BoxFit.none,
                            ),
                            onTap: () {
                              _searchController.clear();
                              searchBooks();
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      // results.clear();
                      query = '';
                      query = value;
                    });
                    query.isEmpty ? searchBooks() : searchQuery(query);
                    // query.isEmpty ? print('Empty') : print(query);
                  },
                  onSubmitted: (value) {
                    setState(() {
                      // results.clear();
                      query = value;
                    });
                    query.isEmpty ? searchBooks() : searchQuery(query);
                    // query.isEmpty ? print('Empty') : print(query);
                  },
                ),
              ),
            ],
          ),
          preferredSize: Size.fromHeight(175),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: height * 0.7,
          child: !isloggedin
              ? Center(child: CircularProgressIndicator())
              : booklist!.length != 0 && user!.email != null
                  ? ListView.separated(
                      shrinkWrap: true,
                      itemCount: booklist == null ? 0 : booklist!.length,
                      itemBuilder: (BuildContext context, int index) {
                        Book bk = booklist![index];
                        return Card(
                          child: Container(
                            width: width * 0.9,
                            child: InkWell(
                              child: Slidable(
                                actionPane: SlidableStrechActionPane(),
                                controller: slidableController,
                                secondaryActions: <Widget>[
                                  new IconSlideAction(
                                    caption: 'Edit',
                                    color: Colors.black45,
                                    icon: Icons.edit,
                                    onTap: () {
                                      setState(() {
                                        fav = bk.fav;
                                        id = bk.id;
                                        _nameController.text = bk.name;
                                        _authorController.text = bk.author;
                                        _descController.text = bk.desc;
                                        _pushAdd();
                                      });
                                    },
                                  ),
                                  new IconSlideAction(
                                    caption: 'Delete',
                                    color: Colors.red,
                                    icon: Icons.delete,
                                    onTap: () {
                                      Book bk_temp = bk;
                                      dbmanager.deleteBook(bk.id, user!.email);
                                      setState(() {
                                        booklist!.removeAt(index);
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        duration: const Duration(seconds: 10),
                                        content: Text('Undo Deleting Book'),
                                        action: SnackBarAction(
                                          label: 'Undo',
                                          onPressed: () {
                                            dbmanager.insertBook(bk_temp);
                                            searchBooks();
                                          },
                                        ),
                                      ));
                                    },
                                  ),
                                ],
                                child: ListTile(
                                  leading: Icon(Icons.book),
                                  title: Text('${bk.name}'),
                                  subtitle: Text(
                                    '${bk.author}',
                                    style: TextStyle(
                                        color: Colors.black.withOpacity(0.6)),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(bk.fav!
                                        ? Icons.favorite
                                        : Icons.favorite_border),
                                    color: bk.fav! ? Colors.red : null,
                                    onPressed: () {
                                      setState(() {
                                        bk.fav!
                                            ? dbmanager
                                                .updateBookFav(bk, "false")
                                                .then((id) => {
                                                      ScaffoldMessenger
                                                              .of(context)
                                                          .showSnackBar(new SnackBar(
                                                              content: FittedBox(
                                                                  fit: BoxFit
                                                                      .scaleDown,
                                                                  child: new Text(
                                                                      '${bk.name} Removed form Favourite !')))),
                                                      searchBooks()
                                                    })
                                            : dbmanager
                                                .updateBookFav(bk, "true")
                                                .then((id) => {
                                                      ScaffoldMessenger
                                                              .of(context)
                                                          .showSnackBar(new SnackBar(
                                                              content: FittedBox(
                                                                  fit: BoxFit
                                                                      .scaleDown,
                                                                  child: new Text(
                                                                      '${bk.name} Added to Favourite !')))),
                                                      searchBooks()
                                                    });
                                      });
                                    },
                                  ),
                                ),
                              ),
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => BookDisplay(
                                            bk: bk,
                                          )),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => SizedBox(
                        height: 2.0,
                      ),
                    )
                  : Column(
                      children: <Widget>[
                        SizedBox(height: 40.0),
                        Container(
                          height: 300,
                          child: Image(
                            image: AssetImage("assets/images/welcome.webp"),
                            fit: BoxFit.contain,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(15),
                          child: Text(
                            "No Books Found",
                            style: TextStyle(
                                fontSize: 20.0, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pushAdd,
        backgroundColor: Color(0xff5E56E7),
        child: Icon(Icons.add),
      ),
    );
  }

  void _submitBook(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (book == null) {
        Book bk = new Book(
          name: _nameController.text,
          author: _authorController.text,
          desc: _descController.text,
          user: user!.email,
        );
        dbmanager.insertBook(bk).then((id) => {
              _nameController.clear(),
              _authorController.clear(),
              _descController.clear(),
              Navigator.pop(context),
              ScaffoldMessenger.of(context).showSnackBar(
                  new SnackBar(content: new Text('Book Added !'))),
              print('Book Added to Db ${id}'),
              searchBooks()
            });
      }
    }
  }

  searchBooks() async {
    print(user!.email);
    List<Book> res = await dbmanager.getBookList(user!.email);
    Set<Book> savedRes =  await dbmanager.getBookFav(user!.email);
    setState(() {
      booklist = res;
      _saved = savedRes;
    });
    booklist!.forEach((element) =>
        print(element.name)
    );
    _saved.forEach((element) =>
        print(element.name)
    );
  }

  _updateBook(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (book == null) {
        Book bk = new Book(
          id: id,
          name: _nameController.text,
          author: _authorController.text,
          desc: _descController.text,
          user: user!.email,
          fav: fav,
        );
        dbmanager.updateBook(bk).then((id) => {
              _nameController.clear(),
              _authorController.clear(),
              _descController.clear(),
              Navigator.pop(context),
              ScaffoldMessenger.of(context).showSnackBar(
                  new SnackBar(content: new Text('Book Updated !'))),
              print('Book Updated to Db ${id}'),
              searchBooks()
            });
        setState(() {
          id = null;
        });
      }
    }
  }
}
