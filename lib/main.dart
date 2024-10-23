import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pokedata/createMyPose.dart';
import 'package:pokedata/login.dart';
import 'package:pokedata/register.dart';
import 'package:pokedata/commu.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http; 
import 'dart:async';

String gloname = "";
File? _image;
String? namebefor = "";
String pokendexnow = "002";
String inputText = '';
int itemsid = 1;
int abilityid = 1;
int moveindex = 0;
String _locationMessage = '';
GoogleMapController? _mapController;
LatLng? _currentPosition;
LatLng? positionpost;
String textpost = "";
dynamic pokedexdata, typedata, itemsdata, abilitydata, movedata;
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  loadJsonData();
  runApp(MyApp());
  setupBackgroundTask();
}




final Map<String, Color> typeColor = {
  'Grass': Color.fromARGB(255, 0, 255, 8),
  'Fire': Color.fromARGB(255, 244, 124, 54),
  'Water': Color.fromARGB(255, 0, 140, 255),
  'Normal': Color.fromARGB(210, 245, 207, 186),
  'Fighting': Color.fromARGB(255, 255, 0, 0),
  'Flying': Color.fromARGB(255, 122, 191, 255),
  'Poison': Color.fromARGB(255, 177, 0, 151),
  'Ground': Color.fromARGB(255, 255, 227, 101),
  'Rock': Color.fromARGB(255, 205, 174, 36),
  'Bug': Color.fromARGB(255, 119, 230, 28),
  'Ghost': Color.fromARGB(255, 84, 61, 107),
  'Steel': Color.fromARGB(255, 174, 174, 174),
  'Electric': Color.fromARGB(255, 238, 245, 44),
  'Psychic': Color.fromARGB(255, 198, 106, 167),
  'Ice': Color.fromARGB(255, 0, 255, 234),
  'Dragon': Color.fromARGB(255, 38, 0, 255),
  'Dark': const Color.fromARGB(255, 71, 27, 27),
  'Fairy': Color.fromARGB(255, 255, 88, 216),
  'Physical': const Color.fromARGB(96, 203, 15, 15),
  'Block': const Color.fromARGB(255, 103, 103, 103),
  'Special': Color.fromARGB(255, 248, 150, 235),
};

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();





class MyApp extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      title: 'Pokemon',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/commu': (context) => Homepage(),
        '/createPose' :(context) => CreateMyPost(),
        '/Pokemon': (context) => PokemonList(),
        '/Moves': (context) => Moves(),
        '/Movesdetail': (context) => MovesDetail(),
        '/Ability': (context) => Ability(),
        '/Abilitydetail': (context) => AbilityDetail(),
        '/Item': (context) => Item(),
        '/Types': (context) => Types(),
        '/Itemdetail': (context) => ItemDetail(),
        '/Detail': (context) => Detail(),
      },
    );
  }
}







void setupBackgroundTask() {
  const Duration interval = Duration(seconds: 5);
  Timer.periodic(interval, (Timer t) {
    backgroundTask();
  });
}

Future<void> backgroundTask() async {
  await sendHttpRequest();
}


Future<void> sendHttpRequest() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  Future<void> _showNotification(String name) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'your channel id',
      'your channel name',
      channelDescription: 'your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    await flutterLocalNotificationsPlugin.show(
      0,
      name,
      'New Post',
      notificationDetails,
      payload: '',
    );
  }
try {
    final response = await http.get(Uri.parse('http://210.246.215.133:2200/get'));
    if(response.body != "" && response.body != namebefor){
      namebefor = response.body;
       _showNotification(response.body);
    }
    if(response.body == ""){
      namebefor = response.body;
    }
  } catch (e) {
    print('Error sending HTTP request: $e');
  }

}



Future<void> loadJsonData() async {
  String jsonString = await rootBundle.loadString('assets/data/pokedex.json');
  pokedexdata = json.decode(jsonString);
  jsonString = await rootBundle.loadString('assets/data/types.json');
  typedata = json.decode(jsonString);
  jsonString = await rootBundle.loadString('assets/data/items.json');
  itemsdata = json.decode(jsonString);
  jsonString = await rootBundle.loadString('assets/data/ability.json');
  abilitydata = json.decode(jsonString);
  jsonString = await rootBundle.loadString('assets/data/moves.json');
  movedata = json.decode(jsonString);
  
}


class Post extends StatefulWidget {
  @override
  _PostState createState() => _PostState();
}


class _PostState extends State<Post> {
  TextEditingController _textEditingController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _getLocationPermission();
  }
  
  Future<void> _getLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {}
    }
  }

  Future<void> _getImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _takePicture() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _getLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      print('Could not get location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 228, 52, 64),
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          icon: Icon(Icons.menu),
        ),
        actions: [
          Image.asset("assets/images/moves.png"),
        ],
        title: Text("Post"),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 10,
            ),
            FractionallySizedBox(
              widthFactor: 0.95,
              child: TextField(
                controller: _textEditingController,
                maxLines: 5,
                onChanged: (text) {
                  textpost = text;
                },
                decoration: InputDecoration(
                  hintText: 'What are you thinking?',
                  border: OutlineInputBorder(

                    borderSide: BorderSide(color: Colors.black),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w200,
                  fontFamily: 'MochiyPopOne',
                  color: const Color.fromARGB(255, 22, 22, 22),
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color.fromARGB(255, 103, 103, 103),
                  width: 2.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    child: _image == null
                        ? Icon(
                            Icons.camera_alt,
                            size: 300,
                            color: Colors.grey,
                          )
                        : Image.file(
                            _image!,
                            fit: BoxFit.scaleDown,
                          ),
                    height: 350,
                    width: 350,
                  )
                ],
              ),
              width: 400,
              height: 400,
            ),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: _getImageFromGallery,
                    child: Icon(Icons.image),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _takePicture,
                    child: Icon(Icons.camera_alt),
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      _getLocation();
                      if (_currentPosition != null) {
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                            height: 600,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: GoogleMap(
                                    onMapCreated: (controller) {
                                      setState(() {
                                        _mapController = controller;
                                      });
                                    },
                                    initialCameraPosition: CameraPosition(
                                      target: _currentPosition!,
                                      zoom: 15.0,
                                    ),
                                    markers: Set<Marker>.from([
                                      Marker(
                                        markerId: MarkerId('current_position'),
                                        position: _currentPosition!,
                                      ),
                                    ]),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        positionpost = _currentPosition;
                                        _currentPosition = null;
                                        Navigator.pop(context);
                                      },
                                      child: Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        _currentPosition = null;
                                        Navigator.pop(context);
                                      },
                                      child: Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                    child: Icon(Icons.add_location_alt),
                  ),
                ],
              ),
            ),
            if (positionpost != null) Text(positionpost.toString()),
            SizedBox(height: 30,),
            ElevatedButton(
              onPressed: ()async {
                if(_image != null && textpost != ""){
                  String name = "Somsak";
                  String url = 'http://210.246.215.133:2200/set?namepost='+name;
                  await http.get(Uri.parse(url));
                  Navigator.pop(context);
                }
              },
              child: Text(
                  "POST",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'MochiyPopOne',
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
      drawer: AppDrawer(context),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 23, 0, 174),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/images/logo.png', // Change the path according to your image location
              width: 320,
              height: 320,
            ),
            Text("Login",
                style: TextStyle(
                    fontSize: 70,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'MochiyPopOne',
                    color: Colors.white)),
            SizedBox(height: 70),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionalTranslation(
                translation: Offset(
                    1, 0), // Adjust the values for your desired indentation
                child: Text(
                  "ID",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'MochiyPopOne',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            FractionallySizedBox(
              widthFactor: 0.8, // Set the width factor to 80%
              child: TextField(
                onChanged: (text) {
                  pokendexnow = text;
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'MochiyPopOne',
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/second');
              },
              child: Text('Go to Second Page'),
            ),
          ],
        ),
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(inputText),
        ),
      ),
    );
  }
}

class poketype extends StatelessWidget {
  final String text;
  final Color? color;

  const poketype({Key? key, required this.text, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(50),
      ),
      height: 40,
      width: 120,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            fontFamily: 'MochiyPopOne',
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class Detail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<dynamic> list1 = [];
    List<dynamic> list2 = [];
    List<dynamic> list3 = [];
    List<dynamic> list4 = [];
    List<dynamic> list5 = [];
    List<dynamic> list6 = [];
    List<dynamic>? resultList;

    if (pokedexdata[int.parse(pokendexnow) - 1]['type'].length < 2) {
      for (int i = 0; i < typedata.length; i++) {
        if (typedata[i]['english'] ==
            pokedexdata[int.parse(pokendexnow) - 1]['type'][0]) {
          resultList = typedata[i]['ineffective'];
          break;
        }
      }
    } else {
      for (int i = 0; i < typedata.length; i++) {
        if (typedata[i]['english'] ==
            pokedexdata[int.parse(pokendexnow) - 1]['type'][0]) {
          list1 = typedata[i]['ineffective'];
          list3 = typedata[i]['effective'];
          list5 = typedata[i]['no_effect'];
          break;
        }
      }
      for (int i = 0; i < typedata.length; i++) {
        if (typedata[i]['english'] ==
            pokedexdata[int.parse(pokendexnow) - 1]['type'][1]) {
          list2 = typedata[i]['ineffective'];
          list4 = typedata[i]['effective'];
          list6 = typedata[i]['no_effect'];
          break;
        }
      }
      Set<dynamic> resultSet = {...list1, ...list2};

      Set<dynamic> ListBuff = {...list3, ...list4};
      resultSet.removeAll(ListBuff);
      resultSet.removeAll(list5);
      resultSet.removeAll(list6);
      resultList = resultSet.toList();
    }

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          backgroundColor:
              typeColor[pokedexdata[int.parse(pokendexnow) - 1]['type'][0]],
          leading: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/Pokemon');
              },
              icon: Icon(
                Icons.arrow_back,
                size: 50,
                color: Colors.black,
              )),
          title: Text(pokendexnow,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                fontFamily: 'MochiyPopOne',
                color: Colors.black,
              )),
        ),
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: typeColor[pokedexdata[int.parse(pokendexnow) - 1]['type']
                    [0]],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              height: 250,
              width: 1000,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/' + pokendexnow + '.png',
                    height: 240,
                  )
                ],
              ),
            ),
            Text(pokedexdata[int.parse(pokendexnow) - 1]['name']['english'],
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'MochiyPopOne',
                  color: Colors.black,
                )),
            SizedBox(height: 20),
            if (pokedexdata[int.parse(pokendexnow) - 1]['type'].length < 2)
              poketype(
                  text: pokedexdata[int.parse(pokendexnow) - 1]['type'][0],
                  color: typeColor[pokedexdata[int.parse(pokendexnow) - 1]
                      ['type'][0]])
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  poketype(
                      text: pokedexdata[int.parse(pokendexnow) - 1]['type'][0],
                      color: typeColor[pokedexdata[int.parse(pokendexnow) - 1]
                          ['type'][0]]),
                  poketype(
                      text: pokedexdata[int.parse(pokendexnow) - 1]['type'][1],
                      color: typeColor[pokedexdata[int.parse(pokendexnow) - 1]
                          ['type'][1]]),
                ],
              ),
            SizedBox(height: 20),
            Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                  ),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'HP',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'MochiyPopOne',
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    width: 120,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Container(
                    color: Colors.red,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [],
                    ),
                    width: pokedexdata[int.parse(pokendexnow) - 1]['base']
                            ['HP'] /
                        3,
                    height: 30,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    pokedexdata[int.parse(pokendexnow) - 1]['base']['HP']
                        .toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w200,
                      fontFamily: 'MochiyPopOne',
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                  ),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'ATK',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'MochiyPopOne',
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    width: 120,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Container(
                    color: Color.fromARGB(255, 255, 140, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [],
                    ),
                    width: pokedexdata[int.parse(pokendexnow) - 1]['base']
                            ['Attack'] /
                        3,
                    height: 30,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    pokedexdata[int.parse(pokendexnow) - 1]['base']['Attack']
                        .toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w200,
                      fontFamily: 'MochiyPopOne',
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                  ),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'DEF',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'MochiyPopOne',
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    width: 120,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Container(
                    color: Color.fromARGB(255, 233, 226, 17),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [],
                    ),
                    width: pokedexdata[int.parse(pokendexnow) - 1]['base']
                            ['Defense'] /
                        3,
                    height: 30,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    pokedexdata[int.parse(pokendexnow) - 1]['base']['Defense']
                        .toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w200,
                      fontFamily: 'MochiyPopOne',
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                  ),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'SP.ATK',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'MochiyPopOne',
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    width: 120,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Container(
                    color: Color.fromARGB(255, 4, 180, 255),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [],
                    ),
                    width: pokedexdata[int.parse(pokendexnow) - 1]['base']
                            ['Sp. Attack'] /
                        3,
                    height: 30,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    pokedexdata[int.parse(pokendexnow) - 1]['base']
                            ['Sp. Attack']
                        .toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w200,
                      fontFamily: 'MochiyPopOne',
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                  ),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'SP.DEF',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'MochiyPopOne',
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    width: 120,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Container(
                    color: Color.fromARGB(255, 106, 226, 73),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [],
                    ),
                    width: pokedexdata[int.parse(pokendexnow) - 1]['base']
                            ['Sp. Defense'] /
                        3,
                    height: 30,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    pokedexdata[int.parse(pokendexnow) - 1]['base']
                            ['Sp. Defense']
                        .toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w200,
                      fontFamily: 'MochiyPopOne',
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 50,
                  ),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'SPD',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'MochiyPopOne',
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    width: 120,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Container(
                    color: Color.fromARGB(255, 255, 124, 255),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [],
                    ),
                    width: pokedexdata[int.parse(pokendexnow) - 1]['base']
                            ['Speed'] /
                        3,
                    height: 30,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    pokedexdata[int.parse(pokendexnow) - 1]['base']['Speed']
                        .toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w200,
                      fontFamily: 'MochiyPopOne',
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Text("Weakness",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'MochiyPopOne',
                  color: Colors.black,
                )),
            SizedBox(height: 20),
            for (int i = 0; i < (resultList!.length / 3).ceil(); i++)
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int j = (i * 3);
                        j < resultList.length && j < (i * 3) + 3;
                        j++)
                      poketype(
                        text: resultList[j],
                        color: typeColor[resultList[j]],
                      ),
                  ],
                ),
              ),
          ],
        )));
  }
}

class PokemonList extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 228, 52, 64),
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          icon: Icon(Icons.menu),
        ),
        actions: [
          Image.asset("assets/images/ball.png"),
        ],
        title: Text("Pokemon List"),
      ),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: ListView.builder(
        // Adding ListView.builder as the body
        itemCount: 500, // Replace with the number of items in your list
        itemBuilder: (context, index) {
          String imgindex = (index + 1).toString().padLeft(3, '0');
          // Replace this with the widget you want to use for each item
          return Card(
              child: ListTile(
            leading: Image.asset("assets/images/$imgindex.png"),
            title: Text(imgindex + " " + pokedexdata[index]['name']['english']),
            onTap: () {
              pokendexnow = imgindex;
              Navigator.pushNamed(context, '/Detail');
            },
          ));
        },
      ),
      drawer: AppDrawer(context),
    );
  }
}

class Moves extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 228, 52, 64),
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          icon: Icon(Icons.menu),
        ),
        actions: [
          Image.asset("assets/images/moves.png"),
        ],
        title: Text("Moves"),
      ),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: ListView.builder(
        // Adding ListView.builder as the body
        itemCount: 300, // Replace with the number of items in your list
        itemBuilder: (context, index) {
          // Replace this with the widget you want to use for each item
          return Card(
              child: ListTile(
            title: Text(movedata['moves'][index]['name']),
            onTap: () {
              moveindex = index;
              Navigator.pushNamed(context, '/Movesdetail');
            },
          ));
        },
      ),
      drawer: AppDrawer(context),
    );
  }
}

class MovesDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 197, 63, 87),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/Moves');
          },
          icon: Icon(
            Icons.arrow_back,
            size: 50,
            color: Colors.black,
          ),
        ),
      ),
      backgroundColor: Color.fromARGB(255, 197, 63, 87),
      body: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(movedata['moves'][moveindex]['name'],
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'MochiyPopOne',
                        color: Colors.black,
                      )),
                  SizedBox(
                    height: 50,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 20.0),
                        child: Text(
                          'Type',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'MochiyPopOne',
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: 20.0),
                        child: Text(
                          'Category',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'MochiyPopOne',
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                          padding: EdgeInsets.only(left: 10.0),
                          child: poketype(
                            text: movedata['moves'][moveindex]['type'],
                            color:
                                typeColor[movedata['moves'][moveindex]['type']],
                          )),
                      Padding(
                          padding: EdgeInsets.only(right: 20.0),
                          child: poketype(
                            text: movedata['moves'][moveindex]['category'],
                            color: typeColor[movedata['moves'][moveindex]
                                ['category']],
                          )),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Power',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'MochiyPopOne',
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Text(
                                movedata['moves'][moveindex]['power']
                                        .toString() +
                                    " BP",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'MochiyPopOne',
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'PP',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'MochiyPopOne',
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Text(
                                movedata['moves'][moveindex]['power']
                                    .toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'MochiyPopOne',
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Accuracy',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'MochiyPopOne',
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Text(
                                movedata['moves'][moveindex]['accuracy']
                                        .toString() +
                                    "%",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  fontFamily: 'MochiyPopOne',
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Container(
                      child: Text(
                    movedata['moves'][moveindex]['description'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'MochiyPopOne',
                      color: const Color.fromARGB(255, 93, 93, 93),
                    ),
                  ))
                ],
              ),
            ),
          ),
        )
      ]),
    );
  }
}

class Ability extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 228, 52, 64),
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          icon: Icon(Icons.menu),
        ),
        actions: [
          Image.asset("assets/images/ability.png"),
        ],
        title: Text("Ability"),
      ),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: ListView.builder(
        // Adding ListView.builder as the body
        itemCount: 235, // Replace with the number of items in your list
        itemBuilder: (context, index) {
          // Replace this with the widget you want to use for each item
          return Card(
              child: ListTile(
            title: Text(abilitydata['abilities'][index]['name']),
            onTap: () {
              abilityid = index;
              Navigator.pushNamed(context, '/Abilitydetail');
            },
          ));
        },
      ),
      drawer: AppDrawer(context),
    );
  }
}

class AbilityDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 197, 63, 87),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/Ability');
          },
          icon: Icon(
            Icons.arrow_back,
            size: 50,
            color: Colors.black,
          ),
        ),
      ),
      backgroundColor: Color.fromARGB(255, 197, 63, 87),
      body: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.all(20.0), // เพิ่มการเว้นระหว่างขอบ
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.8, // กำหนดความกว้างเป็น 80% ของความกว้างของหน้าจอ
              height: MediaQuery.of(context).size.height *
                  0.5, // กำหนดความสูงเป็น 50% ของความสูงของหน้าจอ
              decoration: BoxDecoration(
                color: Colors.white, // สีของกรอบ
                borderRadius:
                    BorderRadius.circular(20.0), // กำหนดรูปร่างของกรอบ
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Text(abilitydata['abilities'][abilityid]['name'],
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'MochiyPopOne',
                        color: Colors.black,
                      )),
                  SizedBox(
                    height: 50,
                  ),
                  Container(
                      child: Padding(
                    padding: EdgeInsets.all(20),
                    child:
                        Text(abilitydata['abilities'][abilityid]['description'],
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'MochiyPopOne',
                              color: Colors.grey,
                            )),
                  ))
                ],
              ),
            ),
          ),
        )
      ]),
    );
  }
}

class Item extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 228, 52, 64),
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          icon: Icon(Icons.menu),
        ),
        actions: [
          Image.asset("assets/images/item.png"),
        ],
        title: Text("Item"),
      ),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: ListView.builder(
        // Adding ListView.builder as the body
        itemCount: 300, // Replace with the number of items in your list
        itemBuilder: (context, index) {
          // Replace this with the widget you want to use for each item
          return Card(
              child: ListTile(
            leading: Image.asset(
                "assets/items/" + itemsdata[index]['id'].toString() + ".png"),
            title: (() {
              try {
                return Text(itemsdata[index]['name']['english']);
              } catch (e) {
                return Text(itemsdata[index]['name']);
              }
            })(),
            onTap: () {
              itemsid = index;
              Navigator.pushNamed(context, '/Itemdetail');
            },
          ));
        },
      ),
      drawer: AppDrawer(context),
    );
  }
}

class ItemDetail extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 197, 63, 87),
        leading: IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/Item');
          },
          icon: Icon(
            Icons.arrow_back,
            size: 50,
            color: Colors.black,
          ),
        ),
      ),
      backgroundColor: Color.fromARGB(255, 197, 63, 87),
      body: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Align(
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/items/' + (itemsid + 1).toString() + '.png',
                    fit: BoxFit.fill,
                    height: 180,
                    width: 180,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  (() {
                    try {
                      return Text(itemsdata[itemsid]['name']['english'],
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'MochiyPopOne',
                            color: Colors.black,
                          ));
                    } catch (e) {
                      return Text(itemsdata[itemsid]['name'],
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'MochiyPopOne',
                            color: Colors.black,
                          ));
                    }
                  })(),
                  Container(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(itemsdata[itemsid]['description'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            fontFamily: 'MochiyPopOne',
                            color: Colors.grey,
                          )),
                    ),
                  )
                ],
              ),
            ),
          ),
        )
      ]),
    );
  }
}

class Types extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 228, 52, 64),
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          icon: Icon(Icons.menu),
        ),
        actions: [
          Image.asset("assets/images/types.png"),
        ],
        title: Text("Types Chart"),
      ),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Container(
          child: Image.asset(
            'assets/images/typesdetail.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
      drawer: AppDrawer(context),
    );
  }
}

class Test extends StatelessWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 228, 52, 64),
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
          icon: Icon(Icons.menu),
        ),
        actions: [
          Image.asset("assets/images/types.png"),
        ],
        title: Text("Test"),
      ),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [],
        ),
      ),
      drawer: AppDrawer(context),
    );
  }
}


