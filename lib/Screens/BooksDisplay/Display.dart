import 'package:books_sqflite/Models/dbmanager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class BookDisplay extends StatefulWidget {
  final Book? bk;

  const BookDisplay({Key? key, this.bk}) : super(key: key);

  @override
  _BookDisplayState createState() => _BookDisplayState();
}

class _BookDisplayState extends State<BookDisplay> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
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
                  "About Book",
                  style: TextStyle(
                    fontSize: 30.0,
                    color: Color(0xff5E56E7),
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                )),
          )),
      body: Container(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.fill,
                child: Text(
                  widget.bk!.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 50,
                  ),
                  maxLines: 2,
                ),
              ),
              FittedBox(
                fit: BoxFit.fitHeight,
                child: Text(
                  widget.bk!.author.toUpperCase(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.0,
                      fontSize: 20,
                      color: Colors.black26),
                ),
              ),
              Divider(
                thickness: 2.0,
                indent: 10,
                endIndent: 10,
              ),
              SizedBox(
                height: 20.0,
              ),
              Container(
                height: height * 0.58,
                child: SingleChildScrollView(
                  child: Text(
                    widget.bk!.desc,
                    style:
                        TextStyle(height: 2.5, wordSpacing: 3.0, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
