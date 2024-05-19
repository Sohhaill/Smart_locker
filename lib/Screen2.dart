import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';



const int SERVER_PORT = 80;

Future<HttpServer> startServer() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 4000);
  print('Server running on port 4000');
  return server;
}

class MyApp extends StatelessWidget {

  final HttpServer server;

  MyApp(this.server);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Locker Control',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Screen2(server: server),
    );
  }
}

class Screen2 extends StatefulWidget {
  final HttpServer server;


  const Screen2({required this.server, Key? key}) : super(key: key);

  @override
  State<Screen2> createState() => _Screen2State();
}

class _Screen2State extends State<Screen2> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  int _selectedIndex = 0;
  WebViewController? _controller;
  bool isImageCaptured = false;
  final TextEditingController _pinController = TextEditingController();
  final String correctPin = '123';
  String message = '';
  DateTime? lockOpenDateTime;
  String? loggedInUserEmail;
  bool _dataSaved = false;
  bool _dataSaved1 = false;
  String base64Image = '';



  @override
  void initState() {
    super.initState();

    // Initialize Flutter Local Notifications
    var initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Listen for requests
    widget.server.listen((HttpRequest request) async {
      if (request.method == 'POST') {
        try {
          if (request.headers.contentType?.mimeType == 'image/jpeg') {
            // Read the request body as bytes
            List<int> bodyBytes = await request.fold<List<int>>([], (previous, element) => previous..addAll(element));
            // Convert bytes to base64 string
            base64Image = base64Encode(bodyBytes);
            print('Received image from ESP32 cam:');
            // Print the base64 encoded image data
            setState(() {
              // Handle the received image data
              // _image = Image.memory(bodyBytes);
            });
          } else {
            // Handle other types of requests
            final requestBody = await utf8.decoder.bind(request).join();
            print('Received message from ESP32 cam: $requestBody');
            print(base64Image);
            setState(() {
              message = requestBody; // Update the message to display on the screen
            });
            _showNotification('Received message: $requestBody');
            switch (requestBody) {
              case 'Unauthorized Person detected':
                _showNotification('Received message: $requestBody');
                break;
              case 'New user added successfully.':
                _showNotification('New user added successfully.');
                break;
              case 'Fingerprint deleted successfully.':
                _showNotification('Fingerprint deleted successfully.');
                break;
              case 'Lock is open':
                _showNotification('Lock is open');
                break;
              case 'Please type in the ID # (from 1 to 10) you want to save this finger as...':
              // Handle specific message without notification
                break;
              case 'Lock is close':
                _showNotification('Lock is close');
                break;
              default:
                _showNotification('Unknown message received: $requestBody');
            }
          }

          request.response
            ..statusCode = HttpStatus.ok
            ..close();
        } catch (e) {
          print('Error processing request: $e');
          request.response
            ..statusCode = HttpStatus.internalServerError
            ..write('Error processing request: $e')
            ..close();
        }
      } else {
        // Handle other HTTP methods (e.g., GET)
        request.response
          ..statusCode = HttpStatus.methodNotAllowed
          ..write('Unsupported request method')
          ..close();
      }
    });
  }


  Future<void> _showNotification(String message) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true, // Use default notification sound
    );
    var platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'New Message',
      message,
      platformChannelSpecifics,
    );
  }

  Future<void> sendCommand(String command, {String? parameter}) async {
    final url = 'http://192.168.100.15:$SERVER_PORT';
    try {
      final response = await http.post(
        Uri.parse(url),
        body: parameter != null ? '$command $parameter' : command,
        headers: {'Content-Type': 'text/plain'},
      );
      if (response.statusCode == 200) {
        print('Command sent successfully: $command');
      } else {
        print('Failed to send command: $command');
      }
    } catch (e) {
      print('Error sending command: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> retrieveData() {
    final reference = FirebaseDatabase.instance.reference().child('lock_open_data');
    try {
      return reference.onValue.map((event) {
        if (event.snapshot.value != null) {
          List<Map<String, dynamic>> dataList = [];
          if (event.snapshot.value is Map<dynamic, dynamic>) {
            Map<dynamic, dynamic> snapshotValue = event.snapshot.value as Map<dynamic, dynamic>;
            snapshotValue.forEach((key, value) {
              dataList.add(Map<String, dynamic>.from(value));
            });
          }
          return dataList;
        } else {
          return [];
        }
      });
    } catch (e) {
      print('Error fetching data: $e');
      return Stream.value([]); // Return an empty stream if an error occurs
    }
  }
  Stream<List<Map<String, dynamic>>> retrieveUnauthorizedData() {
    final reference = FirebaseDatabase.instance.reference().child('unauthorized');
    try {
      return reference.onValue.map((event) {
        if (event.snapshot.value != null) {
          List<Map<String, dynamic>> dataList = [];
          if (event.snapshot.value is Map<dynamic, dynamic>) {
            Map<dynamic, dynamic> snapshotValue = event.snapshot.value as Map<dynamic, dynamic>;
            snapshotValue.forEach((key, value) {
              dataList.add(Map<String, dynamic>.from(value));
            });
          }
          return dataList;
        } else {
          return [];
        }
      });
    } catch (e) {
      print('Error fetching data: $e');
      return Stream.value([]); // Return an empty stream if an error occurs
    }
  }






  void saveLockOpenData(String userEmail) {
    // Get a reference to your Firebase Realtime Database
    final reference = FirebaseDatabase.instance.reference();

    // Get the current date and time
    final DateTime now = DateTime.now();

    // Format the date and time as a string
    final String formattedDate = '${now.year}-${now.month}-${now.day}';
    final String formattedTime = '${now.hour}:${now.minute}:${now.second}';

    // Prepare the data to be saved
    final Map<String, dynamic> data = {
      'date': formattedDate,
      'time': formattedTime,
      'user_email': userEmail,
    };

    // Save the data to Firebase Realtime Database
    reference.child('lock_open_data').push().set(data)
        .then((_) {
      print('Data saved successfully.');
    })
        .catchError((error) {
      print('Failed to save data: $error');
    });
  }
  void saveImageData(String base64ImageData) {
    // Get a reference to your Firebase Realtime Database
    final reference = FirebaseDatabase.instance.reference();

    // Get the current date and time
    final DateTime now = DateTime.now();

    // Format the date and time as a string
    final String formattedDate = '${now.year}-${now.month}-${now.day}';
    final String formattedTime = '${now.hour}:${now.minute}:${now.second}';

    // Prepare the data to be saved
    final Map<String, dynamic> data = {
      'date': formattedDate,
      'time': formattedTime,
      'imageData': base64ImageData,
    };

    // Save the data to Firebase Realtime Database
    reference.child('unauthorized').push().set(data)
        .then((_) {
      print('Image data saved successfully.');
    })
        .catchError((error) {
      print('Failed to save image data: $error');
    });
  }




  void _getUserEmail() {
    // Get the currently signed-in user
    User? user = FirebaseAuth.instance.currentUser;

    // If the user is signed in
    if (user != null) {
      // Get the user's email
      String? email = user.email;

      // Set the loggedInUserEmail variable with the user's email
      setState(() {
        loggedInUserEmail = email;
      });
    } else {
      // If no user is signed in, set loggedInUserEmail to null
      setState(() {
        loggedInUserEmail = null;
      });
    }
  }

  void _showPinDialog(Function commandCallback) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter PIN'),
          content: TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: InputDecoration(hintText: 'PIN'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_pinController.text == correctPin) {
                  commandCallback();
                } else {
                  // Show error message or do something else
                  print('Incorrect PIN');
                }
                Navigator.pop(context);
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnlockButton() {
    return Container(
      width: 250,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffF97038).withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _showPinDialog(() => sendCommand('O')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white12,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 15,
            fontFamily: 'Martel Bold',
          ),
          padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Unlock',
          style: TextStyle(fontSize: 15),
        ),
      ),
    );
  }
  Widget _deleteuser() {
    return Container(
      width: 200,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xffF97038),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffF97038).withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _showPinDialog(() => sendCommand('D')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black12,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 19,
            fontFamily: 'Martel Bold',
          ),
          padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Delete',
          style: TextStyle(fontSize: 15),
        ),
      ),
    );
  }
  Widget _Adduser() {
    return Container(
      width: 250,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xffF97038),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffF97038).withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _showPinDialog(() => sendCommand('E')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black12,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 19,
            fontFamily: 'Martel Bold',
          ),
          padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Add User',
          style: TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildLockOpenDataList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: retrieveData(),
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          List<Map<String, dynamic>> data = snapshot.data ?? [];
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> lockOpenData = data[index];
              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  title: Text(
                    'User Email: ${lockOpenData['user_email'] ?? ''}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      Text(
                        'Date: ${lockOpenData['date']}',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Time: ${lockOpenData['time']}',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.lock_open, color: Colors.green),
                  onTap: () {
                    // Add any onTap functionality if needed
                  },
                ),
              );
            },
          );
        }
      },
    );
  }
  Widget _buildUnauthorizedDataList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: retrieveUnauthorizedData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          List<Map<String, dynamic>> data = snapshot.data ?? [];
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> unauthorizedData = data[index];
              // Extract date, time, and base64 image data from the map
              String date = unauthorizedData['date'];
              String time = unauthorizedData['time'];
              String base64ImageData = unauthorizedData['imageData'];
              // Decode base64 image data
              Uint8List imageDataBytes = base64Decode(base64ImageData);
              // Create an Image widget from decoded bytes
              Image image = Image.memory(imageDataBytes);
              // Display date, time, and image
              return Container(
                margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Date: $date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Time: $time',
                        style: TextStyle(
                          fontSize: 14.0,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: image,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }






  Widget _buildLockButton() {
    return Container(
      width: 250,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xffF97038),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffF97038).withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _showPinDialog(() => sendCommand('L')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black12,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 19,
            fontFamily: 'Martel Bold',
          ),
          padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Lock',
          style: TextStyle(fontSize: 15),
        ),
      ),
    );
  }
  Widget _buzzeron() {
    return Container(
      width: 250,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xffF97038),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffF97038).withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _showPinDialog(() => sendCommand('B')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black12,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 19,
            fontFamily: 'Martel Bold',
          ),
          padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Buzzer On',
          style: TextStyle(fontSize: 15),
        ),
      ),
    );
  }
  Widget _buzzeroff() {
    return Container(
      width: 250,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xffF97038),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xffF97038).withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _showPinDialog(() => sendCommand('P')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black12,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 19,
            fontFamily: 'Martel Bold',
          ),
          padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: const Text(
          'Buzzer Off',
          style: TextStyle(fontSize: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff764abc),
        centerTitle: false,
        title: const Text('Smart Locker'),
      ),
      body: _buildBody(),
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Colors.blue,
        buttonBackgroundColor: Colors.blue,
        height: 50,
        items: const [
          Icon(Icons.camera_alt_outlined, size: 30),
          Icon(Icons.fingerprint_outlined, size: 30),
          Icon(Icons.lock, size: 30),
          Icon(Icons.mark_as_unread_sharp, size: 30),
          Icon(Icons.picture_in_picture, size: 30),
          Icon(Icons.crisis_alert_sharp, size: 30),
          Icon(Icons.image, size: 30),

        ],
        onTap: _onNavigationBarItemTapped,

      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return Center(
          child:  WebView(
            initialUrl: 'http://192.168.100.16',
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController webViewController) {
              _controller = webViewController;
            },
            gestureNavigationEnabled: true,
            debuggingEnabled: false,
            userAgent: 'YourCustomUserAgent',
            gestureRecognizers: Set(),
          ),

        );
      case 1:
        return Container(
          color: Colors.grey, // Set the background color here
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Fingerprint Control',
                  style: TextStyle(
                    fontSize: 25,
                    fontFamily: 'Martel Bold',
                    color: Color(0xff2D3142),
                  ),
                ),
                const SizedBox(height: 50),
                _Adduser(),
                const SizedBox(height: 20),
                _deleteuser(),
                const SizedBox(height: 40),
                Text(
                  ' $message',
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Martel Bold',
                    color: Color(0xff2D3142),
                  ),
                ),
              ],
            ),
          ),
        );


      case 2:
        return Container(
          color: Colors.grey, // Set the background color here
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Relay Control',
                  style: TextStyle(
                    fontSize: 25,
                    fontFamily: 'Martel Bold',
                    color: Color(0xff2D3142),
                  ),
                ),
                const SizedBox(height: 40),
                _buildUnlockButton(),
                const SizedBox(height: 20),
                _buildLockButton(),
                const SizedBox(height: 40),
                Text(
                  ' $message',
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Martel Bold',
                    color: Color(0xff2D3142),
                  ),
                ),
              ],
            ),
          ),
        );
      case 3:
        return Container(
          color: Colors.grey, // Set the background color here
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Buzzer Control',
                  style: TextStyle(
                    fontSize: 25,
                    fontFamily: 'Martel Bold',
                    color: Color(0xff2D3142),
                  ),
                ),
                const SizedBox(height: 40),
                _buzzeron(),
                const SizedBox(height: 20),
                _buzzeroff(),

              ],
            ),
          ),
        );
      case 4:

        if (!_dataSaved && message == 'Lock is open') {
          _getUserEmail();
          saveLockOpenData(loggedInUserEmail!);
          _dataSaved = true; // Mark data as saved
        }

        return _buildLockOpenDataList();

      case 5:
        if (message == 'Unauthorized Person detected') {
          // Save the image data to Firebase Realtime Database
          saveImageData(base64Image);
        }

        return _buildUnauthorizedDataList();




      case 6:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Received Image',
                style: TextStyle(
                  fontSize: 25,
                  fontFamily: 'Martel Bold',
                  color: Color(0xff2D3142),
                ),
              ),
              const SizedBox(height: 20),
              // Check if base64Image is not null and decode the image
              if (base64Image != null) ...[
                // Decode the base64 string to bytes
                Image.memory(
                  base64Decode(base64Image),
                  width: 300,
                  height: 300,
                ),
              ] else ...[
                // If base64Image is null, display a placeholder or an empty container
                Container(),
              ],
            ],
          ),
        );



      default:
        return Container();
    }
  }

  Widget _buildFeature(String feature) {
    return Row(
      children: [
        const Icon(
          Icons.check,
          color: Colors.green,
          size: 20,
        ),
        const SizedBox(
          width: 5,
        ),
        Text(
          feature,
          style: TextStyle(
            fontSize: 16,
            color: Color(0xff2D3142),
          ),
        ),
      ],
    );
  }




  void _onNavigationBarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    // Close the server when the app is disposed
    widget.server.close();
    super.dispose();
  }
}