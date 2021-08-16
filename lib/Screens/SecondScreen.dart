import 'package:books_sqflite/Models/dbmanager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  List<Book>? booklist;
  late final SlidableController slidableController;
  int? id;

  checkAuthentification() async {
    _auth.authStateChanges().listen((user) {
      if (user == null) {
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
    searchBooks();
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
      List<Book> result = await dbmanager.getSearchBookList(query);
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
              title: Text('Add Book'),
            ),
            body: ListView(
              children: <Widget>[
                Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          decoration: new InputDecoration(
                              labelText: 'Book Name',
                              hintText: "Enter Book Name"),
                          controller: _nameController,
                          validator: (val) => val!.isNotEmpty
                              ? null
                              : 'Name Should Not Be empty',
                        ),
                        TextFormField(
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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
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
                      leading: InkWell(
                        child: Icon(Icons.power_settings_new),
                        onTap: signOut,
                      ),
                      title: Text(
                        "Hello ${user!.displayName}",
                        style: TextStyle(
                          fontSize: 30.0,
                          color: Color(0xff5E56E7),
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w600,
                        ),
                      ))
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
          child: !isloggedin
              ? CircularProgressIndicator()
              : booklist!.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: booklist == null ? 0 : booklist!.length,
                      itemBuilder: (BuildContext context, int index) {
                        Book bk = booklist![index];
                        return Slidable(
                          actionPane: SlidableStrechActionPane(),
                          controller: slidableController,
                          secondaryActions: <Widget>[
                            new IconSlideAction(
                              caption: 'Edit',
                              color: Colors.black45,
                              icon: Icons.edit,
                              onTap: () {
                                setState(() {
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
                                dbmanager.deleteBook(bk.id);
                                setState(() {
                                  booklist!.removeAt(index);
                                });
                              },
                            ),
                          ],
                          child: InkWell(
                            child: Card(
                              child: Container(
                                width: width * 0.9,
                                child: ListTile(
                                  leading: Icon(Icons.book),
                                  title: Text('${bk.name}'),
                                  subtitle: Text(
                                    '${bk.author}',
                                    style: TextStyle(
                                        color: Colors.black.withOpacity(0.6)),
                                  ),
                                ),
                              ),
                            ),
                            onTap: (){

                            },
                          ),
                        );
                      },
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
            desc: _descController.text);
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
    List<Book> res = await dbmanager.getBookList();
    setState(() {
      booklist = res;
    });
  }

  _updateBook(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (book == null) {
        Book bk = new Book(
            id: id,
            name: _nameController.text,
            author: _authorController.text,
            desc: _descController.text);
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
          id=null;
        });
      }
    }
  }
}
