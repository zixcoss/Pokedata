import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:pokedata/main.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
final auth = FirebaseAuth.instance;
final store = FirebaseFirestore.instance;
User? user = FirebaseAuth.instance.currentUser;
class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State createState() => _HomepageState();
}
Future<void> saveJsonFile() async {
  Map<String, dynamic> jsonData = {"email": "", "pass": ""};
    final directory =
        await getApplicationDocumentsDirectory(); // รับ directory ที่ app สามารถเขียนไฟล์ได้
    final file = File('${directory.path}/s.json'); // สร้าง reference ไฟล์
    final jsonString = jsonEncode(jsonData); // แปลงข้อมูลเป็น JSON string
    await file.writeAsString(jsonString); // เขียนลงไฟล์
}
class _HomepageState extends State<Homepage> {
  
  
  String getCurrentUserUID() {
    return FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: store.collection('post').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              backgroundColor: Colors.grey[300],
              appBar: AppBar(
                backgroundColor: Color.fromARGB(255, 228, 52, 84),
                foregroundColor: Colors.white,
                title:
                    const Text("Posts", style: TextStyle(color: Colors.white)),
                bottom: const TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(
                        Icons.groups,
                        color: Color.fromARGB(255, 255, 255, 255),
                        size: 30,
                      ),
                    ),
                    Tab(
                      icon: Icon(Icons.person,
                          color: Color.fromARGB(255, 255, 255, 255), size: 30),
                    ),
                  ],
                  indicatorColor: Colors.white,
                  indicatorPadding: EdgeInsets.only(bottom: 5),
                ),
                actions: <Widget>[
                  IconButton(
                    onPressed: (){Navigator.pushNamed(context, '/createPose');}, 
                    icon: Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
              drawer: AppDrawer(context),
              body: TabBarView(
                children: [
                  snapshot.hasData ? buildPostList(snapshot.data!):const Center(child: Text('No Feed',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),),
                  snapshot.hasData ? buildMyPostList(snapshot.data!,getCurrentUserUID()):const Center(child: Text('No Feed',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),),
                ],
              ),
            ),
          );
        });
  }

  

  ListView buildPostList(QuerySnapshot data) {
    
  return ListView.builder(
    itemCount: data.size,
    itemBuilder: (BuildContext context, int index) {
      var post = data.docs.elementAt(index);
      var imagePost = post['imagePost'] ?? '';
      var latitude = post['lat'] ?? 0.0;
      var longitude = post['long'] ?? 0.0;
      var uid = post['uid'];
      var likes = post['like'].length;

      return FutureBuilder(
        future: FirebaseFirestore.instance.collection('account').doc(uid).get(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            if (userSnapshot.hasData) {
              var userData = userSnapshot.data!;
              var username = userData['username'];
              var profileImageUrl = userData['imageProfile']; 

              return GestureDetector(
                child: Card(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  margin: EdgeInsets.only(top: 5, bottom: 10, right: 5, left: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.only(bottom: 10, top: 10),
                        child: Row(
                          children: [
                            SizedBox(width: 10),
                            CircleAvatar(
                              backgroundImage: NetworkImage(profileImageUrl), // แสดงรูปโปรไฟล์ของผู้ใช้
                              radius: 25,
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        username ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      if (imagePost != null && imagePost.isNotEmpty && latitude != 0.0 && longitude != 0.0)
                                        GestureDetector(
                                          onTap: () {
                                            _launchGoogleMaps(
                                              latitude,
                                              longitude,
                                            );
                                          },
                                          child: Text(
                                            'อยู่ที่',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (imagePost != null && imagePost.isNotEmpty && latitude != 0.0 && longitude != 0.0)
                                    GestureDetector(
                                      onTap: () {
                                        _launchGoogleMaps(
                                          latitude,
                                          longitude,
                                        );
                                      },
                                      child: Text(
                                        '${latitude},${longitude}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (post['description'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(
                      post['description'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (imagePost.isNotEmpty &&
                    Uri.parse(imagePost).isAbsolute)
                  Center(
                    child: Image.network(
                      imagePost,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  if(latitude != 0.0 && longitude != 0.0)
                    Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        _launchGoogleMaps(
                          latitude,
                          longitude,
                        );
                      },
                      child: SizedBox(
                        height: 200,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              latitude,
                              longitude,
                            ),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(
                                '${latitude},${longitude}',
                              ),
                              position: LatLng(
                                latitude,
                                longitude,
                              ),
                              infoWindow: InfoWindow(
                                title: '${latitude},${longitude}',
                              ),
                            ),
                          },
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        likes.toString(),
                        style: TextStyle(fontSize: 20),
                      ),
                      buildLikeButton(post.id,uid),
                    ],
                  ),
                )
                    ],
                  ),
                ),
              );
            } else {
              return Text('User not found'); // แสดงข้อความหากไม่พบข้อมูลผู้ใช้
            }
          }
        },
      );
    },
  );
}

  Future<void> deletePost(String postId) async {
  try {
    await FirebaseFirestore.instance.collection('post').doc(postId).delete();
    print('Post deleted successfully');
  } catch (e) {
    print('Error deleting post: $e');
  }
}
  ListView buildMyPostList(QuerySnapshot data,String currentUid) {
  
  return ListView.builder(
    itemCount: data.size,
    itemBuilder: (BuildContext context, int index) {
      var post = data.docs.elementAt(index);
      
      var imagePost = post['imagePost'] ?? '';
      var latitude = post['lat'] ?? 0.0;
      var longitude = post['long'] ?? 0.0;
      var postUID = post['uid'];
      var likes = post['like'].length;

      if (postUID == currentUid){
      return FutureBuilder(
        future: FirebaseFirestore.instance.collection('account').doc(currentUid).get(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else {
            if (userSnapshot.hasData) {
              var userData = userSnapshot.data!;
              var username = userData['username'];
              var profileImageUrl = userData['imageProfile']; 

              return GestureDetector(
                child: Card(
                  color: const Color.fromARGB(255, 255, 255, 255),
                  margin: EdgeInsets.only(top: 5, bottom: 10, right: 5, left: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.only(bottom: 10, top: 10),
                        child: Row(
                          children: [
                            SizedBox(width: 10),
                            CircleAvatar(
                              backgroundImage: NetworkImage(profileImageUrl), // แสดงรูปโปรไฟล์ของผู้ใช้
                              radius: 25,
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        username ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      if (imagePost != null && imagePost.isNotEmpty && latitude != 0.0 && longitude != 0.0)
                                        GestureDetector(
                                          onTap: () {
                                            _launchGoogleMaps(
                                              latitude,
                                              longitude,
                                            );
                                          },
                                          child: Text(
                                            'อยู่ที่',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (imagePost != null && imagePost.isNotEmpty && latitude != 0.0 && longitude != 0.0)
                                    GestureDetector(
                                      onTap: () {
                                        _launchGoogleMaps(
                                          latitude,
                                          longitude,
                                        );
                                      },
                                      child: Text(
                                        '${latitude},${longitude}',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                             Expanded(
                          flex: 1,
                          child: IconButton(
                              padding: EdgeInsets.only(right: 20),
                              alignment: Alignment.centerRight,
                              onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Confirm Delete"),
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () {
                                              deletePost(post.id); // เรียกใช้ฟังก์ชันลบโพสต์
                                              Navigator.of(context).pop(); // ปิดกล่องโต้ตอบหลังจากลบโพสต์
                                            },
                                            child: Icon(Icons.check_circle),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                                Navigator.pop(context);
                                            },
                                            child: Icon(Icons.cancel),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              icon: Icon(
                                Icons.delete,
                                size: 40,
                                color: Color.fromARGB(255, 228, 52, 84),
                              )))
                          ],
                        ),
                      ),
                      if (post['description'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(
                      post['description'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (imagePost.isNotEmpty &&
                    Uri.parse(imagePost).isAbsolute)
                  Center(
                    child: Image.network(
                      imagePost,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  if(latitude != 0.0 && longitude != 0.0)
                    Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GestureDetector(
                      onTap: () {
                        _launchGoogleMaps(
                          latitude,
                          longitude,
                        );
                      },
                      child: SizedBox(
                        height: 200,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              latitude,
                              longitude,
                            ),
                            zoom: 15,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId(
                                '${latitude},${longitude}',
                              ),
                              position: LatLng(
                                latitude,
                                longitude,
                              ),
                              infoWindow: InfoWindow(
                                title: '${latitude},${longitude}',
                              ),
                            ),
                          },
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        likes.toString(),
                        style: TextStyle(fontSize: 20),
                      ),
                      buildLikeButton(post.id,postUID),
                    ],
                  ),
                )
                    ],
                  ),
                ),
              );
            } else {
              return Text('User not found');
            }
          }
        },
      );
      }else{
        return SizedBox();
      }
    },
  );
}

  Stream<bool> isPostLikedByUser(String postId, String uid) {
    // สร้าง Stream จาก Firestore ที่เฝ้าดูการเปลี่ยนแปลงของ document ของโพสต์
    return FirebaseFirestore.instance
        .collection('post')
        .doc(postId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        // ตรวจสอบว่ามี field ที่เก็บ array ของ uid ของผู้ที่ไลค์โพสต์หรือไม่
        List<dynamic> likes = snapshot.get('like');
        // ตรวจสอบว่า uid ของผู้ใช้ปัจจุบันอยู่ใน array นั้นหรือไม่
        return likes.contains(uid);
      }
      return false;
    });
  }

  Widget buildLikeButton(String postId, String uid) {
  // สมมติว่าคุณมี stream ที่เฝ้าดูการเปลี่ยนแปลงของการไลค์
  Stream<bool> isLikedStream = isPostLikedByUser(postId, uid);

  return StreamBuilder<bool>(
    stream: isLikedStream,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return CircularProgressIndicator(); // แสดง indicator ระหว่างโหลด
      } else if (snapshot.hasData) {
        bool isLiked = snapshot.data!;
        return IconButton(
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border, // ตั้งค่าไอคอนตามสถานะการไลค์
            color: isLiked ? Colors.red : Colors.grey,
            size: 40
          ),
          onPressed: () {
            if (isLiked) {
              unlikePost(postId, uid); // ถ้ากดไลค์แล้ว กดอีกครั้งเพื่อ unlike
            } else {
              likePost(postId, uid); // ถ้ายังไม่ได้กดไลค์ กดเพื่อ like
            }
          },
        );
      } else {
        return IconButton(
          icon: Icon(Icons.favorite_border, color: Colors.grey, size: 40),
          onPressed: () {}, // ไม่ทำอะไรเมื่อไม่มีข้อมูล
        );
      }
    },
  );
}

  Future<void> likePost(String postId, String uid) async {
    final postRef = FirebaseFirestore.instance.collection('post').doc(postId);
    await postRef.update({
      'like': FieldValue.arrayUnion([uid]) // เพิ่ม UID ลงในอาร์เรย์ likes
    });
  }

  Future<void> unlikePost(String postId, String uid) async {
    final postRef = FirebaseFirestore.instance.collection('post').doc(postId);

    await postRef.update({
      'like': FieldValue.arrayRemove([uid]) // ลบ UID ออกจากอาร์เรย์ likes
    });
  }

  void _launchGoogleMaps(double latitude, double longitude) async {
    final Uri url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalNonBrowserApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<String> getAddressFromLatLong(
      double latitude, double longitude) async {
    final String url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=AIzaSyBFL7uuYou-lKEymEAsAD9v9S7kjICNAXs';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      if (jsonResponse['results'].length > 0) {
        return jsonResponse['results'][0]['formatted_address'];
      } else {
        return "No address available";
      }
    } else {
      throw Exception('Failed to load address');
    }
  }

  Future<DocumentSnapshot> getCurrentUserData() async {
    var currentUser = auth.currentUser;
    var userData =
        await store.collection('account').doc(currentUser!.uid).get();
    return userData;
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a photo'),
                onTap: () {
                  _getImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from gallery'),
                onTap: () {
                  _getImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      print(pickedFile);
      File imageFile = File(pickedFile.path);
      print(imageFile);
      String? imageUrl = await uploadImage(imageFile);
      if (imageUrl != null) {
        print('Image uploaded successfully: $imageUrl');
        final userDocRef = FirebaseFirestore.instance
            .collection('account')
            .doc(auth.currentUser!.uid);
        userDocRef.update({'imageProfile': imageUrl}).then((value) {
          print('Image Profile updated successfully!');
        }).catchError((error) {
          print('Failed to update Image Profile: $error');
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("SUCCESS"), duration: Duration(milliseconds: 800)));
      } else {
        print('Failed to upload image');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("FAILED"), duration: Duration(milliseconds: 800)));
      }
    } else {
      print('No image selected.');
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      // สร้าง Reference ใหม่ใน Firebase Storage
      String fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + '.png';
      firebase_storage.Reference reference = firebase_storage
          .FirebaseStorage.instance
          .ref()
          .child('acc_profile/$fileName');
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
Drawer AppDrawer(BuildContext context) {
  Future<String?> uploadImage(File imageFile) async {
    try {
      // สร้าง Reference ใหม่ใน Firebase Storage
      String fileName =
          DateTime.now().millisecondsSinceEpoch.toString() + '.png';
      firebase_storage.Reference reference = firebase_storage
          .FirebaseStorage.instance
          .ref()
          .child('acc_profile/$fileName');
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
  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      print(pickedFile);
      File imageFile = File(pickedFile.path);
      print(imageFile);
      String? imageUrl = await uploadImage(imageFile);
      if (imageUrl != null) {
        print('Image uploaded successfully: $imageUrl');
        final userDocRef = FirebaseFirestore.instance
            .collection('account')
            .doc(auth.currentUser!.uid);
        userDocRef.update({'imageProfile': imageUrl}).then((value) {
          print('Image Profile updated successfully!');
        }).catchError((error) {
          print('Failed to update Image Profile: $error');
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("SUCCESS"), duration: Duration(milliseconds: 800)));
      } else {
        print('Failed to upload image');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("FAILED"), duration: Duration(milliseconds: 800)));
      }
    } else {
      print('No image selected.');
    }
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Take a photo'),
                onTap: () {
                  _getImage(ImageSource.camera);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from gallery'),
                onTap: () {
                  _getImage(ImageSource.gallery);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

    return Drawer(
        child: StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('account')
          .doc(auth.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          var username = userData['username'];
          var imageProfile = userData['imageProfile'];
          gloname = username;
          
          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 228, 52, 84),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () {
                              _showImagePicker(context);
                            },
                            child: CircleAvatar(
                              child: Icon(
                                Icons.photo_camera,
                                color: Color.fromARGB(255, 150, 29, 51),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 6,
                          ),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  String? newName;
                                  return AlertDialog(
                                    title: Text('Edit username.'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          TextField(
                                            onChanged: (value) {
                                              newName = value;
                                            },
                                            decoration: InputDecoration(
                                              hintText: 'Enter your username',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          if (newName!.length > 10) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text(
                                                    'Error',
                                                    style: TextStyle(
                                                        color: Colors.red,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ), // หัวเรื่องของป๊อปอัป
                                                  content: Text(
                                                      'Name must be less than 10 characters.',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .red)), // เนื้อหาข้อความแสดงเตือน
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop(); // ปิดป๊อปอัป
                                                      },
                                                      child: Text(
                                                          'OK'), // ข้อความบนปุ่ม OK
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          } else {
                                            print('New name: $newName');
                                            final userDocRef = FirebaseFirestore
                                                .instance
                                                .collection('account')
                                                .doc(auth.currentUser!.uid);
                                            userDocRef.update({
                                              'username': newName
                                            }).then((value) {
                                              print(
                                                  'Username updated successfully!');
                                              // Navigator.of(context).pop();
                                              Navigator.pushNamedAndRemoveUntil(
                                                  context,
                                                  '/commu',
                                                  (route) => false);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text("SUCCESS"),
                                                      duration: Duration(
                                                          milliseconds: 1000)));
                                            }).catchError((error) {
                                              print(
                                                  'Failed to update username: $error');
                                              Navigator.pushNamedAndRemoveUntil(
                                                  context,
                                                  '/commu',
                                                  (route) => false);
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text("FAILED"),
                                                      duration: Duration(
                                                          milliseconds: 1000)));
                                            });
                                          }
                                        },
                                        child: Text('Save'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: CircleAvatar(
                              child: Icon(
                                Icons.edit,
                                color: Color.fromARGB(255, 150, 29, 51),
                              ),
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          new Container(
                              width: 80.0,
                              height: 80.0,
                              decoration: new BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: Color.fromARGB(255, 255, 238, 84),
                                      width: 3),
                                  shape: BoxShape.circle,
                                  image: new DecorationImage(
                                      fit: BoxFit.fill,
                                      image: new NetworkImage(imageProfile)))),
                          SizedBox(
                            width: 15,
                          ),
                          Text(
                            username, // Use newName if available, otherwise use username
                            style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      )
                    ],
                  )),
              ListTile(
                leading: Image.asset("assets/images/ball.png"),
                title: Text('Pokemon'),
                onTap: () {
                  Navigator.pushNamed(context, '/Pokemon');
                },
              ),
              ListTile(
                leading: Image.asset("assets/images/moves.png"),
                title: Text('Moves'),
                onTap: () {
                  Navigator.pushNamed(context, '/Moves');
                },
              ),
              ListTile(
                leading: Image.asset("assets/images/ability.png"),
                title: Text('Ability'),
                onTap: () {
                  Navigator.pushNamed(context, '/Ability');
                },
              ),
              ListTile(
                leading: Image.asset("assets/images/item.png"),
                title: Text('Item'),
                onTap: () {
                  Navigator.pushNamed(context, '/Item');
                },
              ),
              ListTile(
                leading: Image.asset("assets/images/types.png"),
                title: Text('Types'),
                onTap: () {
                  Navigator.pushNamed(context, '/Types');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.people_alt,
                  size: 40,
                ),
                title: Text('Community'),
                onTap: () {
                  Navigator.pushNamed(context, '/commu');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.logout,
                  size: 40,
                ),
                title: Text('Log Out'),
                onTap: () {
                  saveJsonFile();
                  auth.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Log Out"),
                      duration: Duration(milliseconds: 800)));
                },
              ),
            ],
          );
        }
      },
    ));
  }