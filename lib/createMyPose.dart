import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pokedata/main.dart';
import 'package:http/http.dart' as http; 
import 'dart:async';
File? _image;
String pokendexnow = "002";
String inputText = '';
String _locationMessage = '';
GoogleMapController? _mapController;
LatLng? _currentPosition;
LatLng? positionpost;
String textpost = "";

class CreateMyPost extends StatefulWidget {
  @override
  _CreateMyPostState createState() => _CreateMyPostState();
}


class _CreateMyPostState extends State<CreateMyPost> {
  final auth = FirebaseAuth.instance;
  final store = FirebaseFirestore.instance;
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
        foregroundColor: Colors.white,
        backgroundColor: Color.fromARGB(255, 228, 52, 84),
        title: Text("Create Post",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold,color: Colors.white),),
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
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
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
              onPressed: () async {
                String? imagePost ; 
                if(_image!=null){
                    imagePost = await uploadImage(_image!);
                  }else{
                    imagePost = null;
                  };
                Map<String, dynamic> dataPost = {
                  'uid': auth.currentUser!.uid,
                  'description': textpost,
                  'imagePost': imagePost,
                  'lat': positionpost?.latitude,
                  'long': positionpost?.longitude,
                  'like': []
                };
                await store
                    .collection('post')
                    .doc()
                    .set(dataPost)
                    .then((_) {
                  print('Data added successfully with post!');
                  _image = null;
                  positionpost = null;
                }).catchError((error) {
                  print('Error adding data: $error');
                });

                String url = 'http://210.246.215.133:2200/set?namepost='+gloname;
                await http.get(Uri.parse(url));
                print(textpost);
                print(positionpost);
                print(_image?.path);
                print(dataPost);
                Navigator.pop(context);
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
    );
  }

  Future<String?> uploadImage(File imageFile) async {
  try {
    // สร้าง Reference ใหม่ใน Firebase Storage
    String fileName = DateTime.now().millisecondsSinceEpoch.toString()+'.png';
    firebase_storage.Reference reference = firebase_storage.FirebaseStorage.instance.ref().child('image_post/$fileName');
    // อัปโหลดไฟล์ไปยัง Firebase Storage
    firebase_storage.UploadTask uploadTask = reference.putFile(imageFile);
    // รอให้กระบวนการอัปโหลดเสร็จสมบูรณ์
    await uploadTask.whenComplete(() => print('Upload complete'));
    // ดึง URL ของรูปภาพที่อัปโหลดขึ้น Firebase Storage
    String downloadURL = await reference.getDownloadURL();
    return downloadURL;
  } catch (e) {
    print('Upload failed: $e');
    return null;
  }
}
}