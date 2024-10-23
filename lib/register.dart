import 'package:pokedata/login.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formstate = GlobalKey<FormState>();
  TextEditingController _email = TextEditingController();
  TextEditingController _password = TextEditingController();
  final _username = TextEditingController();
  final _imageProfile =
      'https://exsinnot.com/1000.png';
  final store = FirebaseFirestore.instance;
  // final _

  final auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Register',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color.fromARGB(255, 228, 52, 84),
          foregroundColor: Colors.white,
        ),
        body: Form(
            key: _formstate,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: ListView(
                padding: EdgeInsets.only(left: 10, right: 10),
                children: <Widget>[
                  buildEmailField(),
                  SizedBox(
                    height: 10,
                  ),
                  buildUsernameField(),
                  SizedBox(
                    height: 10,
                  ),
                  buildPasswordField(),
                  SizedBox(
                    height: 20,
                  ),
                  buildRegisterButton(),
                ],
              ),
            )));
  }

  ElevatedButton buildRegisterButton() {
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
      child: const Text('Register'),
      onPressed: () async {
        print('Register new account');
        if (_formstate.currentState!.validate()) {
          print(_email.text);
          print(_password.text);
          print(_username.text);
          final user = await auth.createUserWithEmailAndPassword(
              email: _email.text.trim(), password: _password.text.trim());
          await user.user!.sendEmailVerification();
          User? userCurrent = user.user;
          if (userCurrent != null) {
            print(userCurrent.uid);
            Map<String, dynamic> data = {
              'email': _email.text,
              'username': _username.text,
              'imageProfile': _imageProfile
            };
            await store
                .collection('account')
                .doc(userCurrent.uid)
                .set(data)
                .then((_) {
              print('Data added successfully with custom document ID!');
            }).catchError((error) {
              print('Error adding data: $error');
            });
            
          }
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
              ModalRoute.withName('/'));
        } else {
          print('Invalid Form');
        }
      },
    );
  }

  TextFormField buildPasswordField() {
    return TextFormField(
      controller: _password,
      validator: (value) {
        if (value!.length < 8) {
          return 'Please Enter more than 8 Character';
        } else {
          return null;
        }
      },
      obscureText: true,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        labelText: 'Password',
        icon: Icon(Icons.lock),
      ),
    );
  }

  TextFormField buildEmailField() {
    return TextFormField(
      controller: _email,
      validator: (value) {
        if (value!.isEmpty) {
          return 'Please fill in E-mail field';
        } else {
          return null;
        }
      },
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Email',
        icon: Icon(Icons.email),
        hintText: 'exam@example.com',
      ),
    );
  }

  TextFormField buildUsernameField() {
    return TextFormField(
      controller: _username,
      validator: (value) {
        if (value!.isEmpty) {
          return 'Please fill in Username field';
        } else {
          return null;
        }
      },
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Username',
        icon: Icon(Icons.person),
      ),
    );
  }
}
