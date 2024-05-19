
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smart_locker/Screen2.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smart_locker/gmail.dart';
import 'package:smart_locker/phone.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key});

  @override
  Widget build(BuildContext context) {
    String email = "";
    String password = "";

    FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();

    Future<void> login() async {
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Check if login is successful
        if (userCredential.user != null) {
          var server = await startServer(); // Initialize the server
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Screen2(server: server)),
          );

        } else {
          // Handle case when userCredential.user is null
          print('User credential is null');
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Login Failed'),
                content: Text('Invalid email or password. Please try again.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } catch (emailPasswordError) {
        // Handle invalid email/password or other errors
        print('Login Error: $emailPasswordError');
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Login Failed'),
              content: Text('Invalid email or password. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }


    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff764abc),
        title: const Center(child: Text('SMART LOCKER')),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(
                    image: NetworkImage('https://cdni.iconscout.com/illustration/premium/thumb/login-page-4468581-3783954.png'),
                    width: 300,
                    height: 300,
                  ),
                ],
              ),

              const Center(
                child: Text(
                  'IOT Based Smart Locker',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Martel Bold',
                    color: Color(0xff2D3142),
                  ),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: TextFormField(
                  onChanged: (value) {
                    email = value;
                  },
                  style: TextStyle(fontFamily: 'Roboto', fontSize: 16), // 1. Font Style
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.email),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)), // 2. Color Scheme
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue), // 2. Color Scheme
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: TextFormField(
                  onChanged: (value) {
                    password = value;
                  },
                  obscureText: true,
                  style: TextStyle(fontFamily: 'Roboto', fontSize: 16), // 1. Font Style
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.lock), // 4. Icon Update
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)), // 2. Color Scheme
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue), // 2. Color Scheme
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 25,
              ),
              Center(
                child: ElevatedButton(

                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.deepPurple, // Use a deep purple color for the background
                    backgroundColor: Colors.white, // Text color
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3, // Add a subtle shadow effect
                    shadowColor: Colors.black.withOpacity(0.3), // Adjust shadow color and opacity
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Martel Bold',
                    ),
                  ),
                ),



              ),
              const SizedBox(
                height: 5,
              ),

              const SizedBox(
                height: 15,
              ),
              Center(
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Martel Bold',
                    color: Color(0xff2D3142),
                  ),
                ),

              ),
              const SizedBox(
                height: 15,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  MyApp2()),
                  );
                },
                icon: Row(
                  children: [
                    Image.network(
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRVctjn1jdzRWOoayGR8H88ZfZJBObDZa3LMQAYJDEyaA&s',
                      width: 25,
                      height: 25,
                    ),

                  ],
                ),
                label: Text(
                  'Sign up with Google',
                  style: TextStyle(fontSize: 16), // Adjust text size
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue, // Button background color
                  backgroundColor: Colors.white, // Text color
                  padding: EdgeInsets.symmetric(vertical: 13, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  elevation: 3, // Add a subtle shadow effect
                  shadowColor: Colors.black.withOpacity(0.3), // Shadow color and opacity
                ),
              ),

              const SizedBox(height: 10,),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  MyPhone()),
                  );
                },
                icon: Row(
                  children: [

                    SizedBox(width: 8),
                    Icon(Icons.phone),
                  ],
                ),
                label: Text(
                  'Sign up with Phone',
                  style: TextStyle(fontSize: 16), // Adjust text size
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue, // Button background color
                  backgroundColor: Colors.white, // Text color
                  padding: EdgeInsets.symmetric(vertical: 13, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                  ),
                  elevation: 3, // Add a subtle shadow effect
                  shadowColor: Colors.black.withOpacity(0.3), // Shadow color and opacity
                ),
              ),

              const SizedBox(height: 10,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'If you don\'t have an account',
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Martel Bold',
                      color: Color(0xff2D3142),
                    ),
                  ),
                  TextButton(
                    onPressed: () {

                    },
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Martel Bold',
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),

            ],
          ),
        ),
      ),
    );
  }
}
