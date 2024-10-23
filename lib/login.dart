import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert';
import 'package:pokedata/main.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

dynamic sdata;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

Future<void> saveJsonFile(Map<String, dynamic> jsonData) async {
  final directory =
      await getApplicationDocumentsDirectory(); // รับ directory ที่ app สามารถเขียนไฟล์ได้
  final file = File('${directory.path}/s.json'); // สร้าง reference ไฟล์
  final jsonString = jsonEncode(jsonData); // แปลงข้อมูลเป็น JSON string
  await file.writeAsString(jsonString); // เขียนลงไฟล์
}

Future<Map<String, dynamic>> readJsonFile() async {
  try {
    final directory =
        await getApplicationDocumentsDirectory(); // รับ directory ที่ app สามารถอ่านไฟล์ได้
    final file = File('${directory.path}/s.json'); // สร้าง reference ไฟล์
    final jsonString = await file.readAsString();
    Map<String, dynamic> jsonData = jsonDecode(jsonString);

    return jsonData;
  } catch (e) {
    Map<String, dynamic> jsonData = {"email": "", "pass": ""};
    final directory =
        await getApplicationDocumentsDirectory(); // รับ directory ที่ app สามารถเขียนไฟล์ได้
    final file = File('${directory.path}/s.json'); // สร้าง reference ไฟล์
    final jsonString = jsonEncode(jsonData); // แปลงข้อมูลเป็น JSON string
    await file.writeAsString(jsonString); // เขียนลงไฟล์
    return jsonData;
  }
}

Future<void> log(BuildContext context) async {
  final _formstate = GlobalKey<FormState>();
  String? email = sdata['email'];
  String? password = sdata['pass'];
  final auth = FirebaseAuth.instance;
  try {
    await auth
        .signInWithEmailAndPassword(email: email!, password: password!)
        .then((value) {
      if (value.user!.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Login Pass"),
            duration: Duration(milliseconds: 800)));
        Navigator.pushNamedAndRemoveUntil(
            context, '/Pokemon', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please verify email'),
          duration: Duration(milliseconds: 800),
        ));
      }
    }).catchError((reason) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Login of Password Invalid'),
        duration: Duration(milliseconds: 800),
      ));
    });
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found') {
      print('No user found for that email.');
    } else if (e.code == 'wrong-password') {
      print('Wrong password provided for that user.');
    }
  }
}

Future<void> loadjson(BuildContext context) async {
  sdata = await readJsonFile();
  if (sdata['email'] != "") {
    log(context);
  }
}

class _LoginPageState extends State<LoginPage> {
  final _formstate = GlobalKey<FormState>();
  String? email;
  String? password;
  final auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    loadjson(context);

    return Scaffold(
        backgroundColor: Color.fromARGB(255, 228, 52, 84),
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 228, 52, 84),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              // color: Colors.black,
              child: const Column(
                children: <Widget>[
                  Image(
                    image: AssetImage('assets/logo.png'),
                    width: 170,
                    height: 170,
                  ),
                  Text(
                    'POKEDATA',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 45,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 20,
            ),
            Expanded(
                child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(60),
                        topRight: Radius.circular(60),
                      ),
                    ),
                    child: Form(
                        autovalidateMode: AutovalidateMode.always,
                        key: _formstate,
                        child: Column(
                          children: <Widget>[
                            const Center(
                              child: Text(
                                'Login',
                                style: TextStyle(
                                    // fontFamily: 'Prompt',
                                    fontSize: 35,
                                    fontWeight: FontWeight.w900,
                                    color: Color.fromARGB(255, 228, 52, 84)),
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.only(
                                    top: 20, right: 10, left: 10),
                                children: [
                                  emailTextFormField(),
                                  SizedBox(
                                    height: 14,
                                  ),
                                  passwordTextFormField(),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  loginButton(),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        "Don't have an account yet?",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      GestureDetector(
                                        child: Text(
                                          'Sign up',
                                          style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  255, 228, 52, 84)),
                                        ),
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, '/register');
                                        },
                                      )
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        )))),
          ],
        ));
  }

  ElevatedButton loginButton() {
    return ElevatedButton(
      style: const ButtonStyle(
          backgroundColor:
              MaterialStatePropertyAll<Color>(Color.fromARGB(255, 228, 52, 84)),
          foregroundColor: MaterialStatePropertyAll<Color>(Colors.white),
          textStyle: MaterialStatePropertyAll<TextStyle>(TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          )),
          minimumSize: MaterialStatePropertyAll<Size>(Size.fromHeight(45))),
      child: Text('Login'),
      onPressed: () async {
        if (_formstate.currentState!.validate()) {
          print('Valid Form');
          _formstate.currentState!.save();
          try {
            await auth
                .signInWithEmailAndPassword(email: email!, password: password!)
                .then((value) {
              if (value.user!.emailVerified) {
                sdata['email'] = email;
                sdata['pass'] = password;
                saveJsonFile(sdata);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Login Pass"),
                    duration: Duration(milliseconds: 800)));
                Navigator.pushNamedAndRemoveUntil(
                    context, '/commu', (route) => false);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Please verify email'),
                  duration: Duration(milliseconds: 800),
                ));
              }
            }).catchError((reason) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Login of Password Invalid'),
                duration: Duration(milliseconds: 800),
              ));
            });
          } on FirebaseAuthException catch (e) {
            if (e.code == 'user-not-found') {
              print('No user found for that email.');
            } else if (e.code == 'wrong-password') {
              print('Wrong password provided for that user.');
            }
          }
        } else {
          print('Invalid Form');
        }
      },
    );
  }

  TextFormField passwordTextFormField() {
    return TextFormField(
      onSaved: (value) {
        password = value!.trim();
      },
      validator: (value) {
        if (value!.length < 8) {
          return 'Please Enter more than 8 Character';
        } else {
          return null;
        }
      },
      obscureText: true,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: Icon(Icons.lock),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 17),
      ),
    );
  }

  TextFormField emailTextFormField() {
    return TextFormField(
        onSaved: (value) {
          email = value!.trim();
        },
        validator: (value) {
          if (!validateEmail(value!)) {
            return 'Please fill in E-mail field';
          } else {
            return null;
          }
        },
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          hintText: 'Email',
          // filled: true,
          // fillColor: Color.fromARGB(255, 241, 241, 241),
          prefixIcon: Icon(Icons.email),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 17),
        ));
  }

  bool validateEmail(String value) {
    RegExp regex = RegExp(
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$');

    return (!regex.hasMatch(value)) ? false : true;
  }
}
