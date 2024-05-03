import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vulcanizing_app_ignite_creative/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int selectedTab = 0;
  List<Widget> screens = [HomeScreen(),  ReviewScreen()];

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((event) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/lugo.png',
              height: 40,
              width: 40,
            ),
            SizedBox(width: 8),
            Text(
              'Ignite Creative',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'Pacifico',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
      ),
        
        body: FirebaseAuth.instance.currentUser == null
            ? SignInScreen(
                providers: [EmailAuthProvider()],
                actions: [
                  AuthStateChangeAction<SignedIn>((context, state) {
                    setState(() {});
                  }),
                  AuthStateChangeAction<UserCreated>((context, state) {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => InformationScreen(),
                    ));
                  }),
                ],
              )
            : screens[selectedTab],
        bottomNavigationBar: FirebaseAuth.instance.currentUser == null
            ? null
            : BottomNavigationBar(
                currentIndex: selectedTab,
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  
                  BottomNavigationBarItem(
                    icon: Icon(Icons.book),
                    label: 'Review',
                  ),
                  
                ],
                onTap: (value) {
                  setState(() {
                    selectedTab = value;
                  });
                },
                backgroundColor: Color.fromARGB(255, 250, 227, 194), // Baguhin ang kulay ng background ng navigation bar
                selectedItemColor: Colors.black, // Baguhin ang kulay kapag pinipindot
              ),

      ),
    );
  }
}





class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(211, 173, 98, 31),
      appBar: AppBar(
  title: Text(
    'Book',
    style: TextStyle(
      fontWeight: FontWeight.bold, // Bagong setting para gawing bold ang text
    ),
  ),
  backgroundColor: Color.fromARGB(255, 255, 166, 0),
),

      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => BookingForm(),
              );
            },
            backgroundColor: Color.fromARGB(255, 255, 166, 0), // Palitan ang background color ng FloatingActionButton
            foregroundColor: Colors.black, // Kulay ng icon
            child: Icon(Icons.add),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingInProgressScreen(userId: 'UserId'),
                ),
              );
            },
            backgroundColor: Color.fromARGB(255, 255, 166, 0), // Palitan ang background color ng FloatingActionButton
            foregroundColor: Colors.black, // Kulay ng icon
            child: Icon(Icons.timer), // Stopwatch icon represents booking in process
          ),
        ],
      ),
      body: Center(
        child: Image.asset(
          'assets/lugo.png', // Lagyan ng tamang path ang iyong larawan
          width: 500 , // Palitan ang lapad ng larawan ayon sa iyong preference
          height: 500, // Palitan ang taas ng larawan ayon sa iyong preference
        ),
      ),
    );
  }
}

class BookingInProgressScreen extends StatelessWidget {
  final String userId; // Define userId parameter here

  BookingInProgressScreen({required this.userId});

  // Stream to listen for changes in the pending collection
  Stream<List<String>> _pendingStream(String currentUserId) {
    return FirebaseFirestore.instance
        .collection('pending')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc['shopOwnerId'] as String).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
              backgroundColor: Color.fromARGB(211, 173, 98, 31),

      appBar: AppBar(
      backgroundColor: Color.fromARGB(255, 255, 166, 0),
         title: Text(
    'On Proccess',
    style: TextStyle(
      fontWeight: FontWeight.bold, // Bagong setting para gawing bold ang text
    ),
  ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
  'Shop Owner IDs Accepted your Booking',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white, // Bagong kulay ng text
  ),
),

            StreamBuilder<List<String>>(
              stream: _pendingStream(FirebaseAuth.instance.currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                List<String> shopOwnerIds = snapshot.data ?? [];
                if (shopOwnerIds.isEmpty) {
                  return Center(child: Text('No shop owner IDs found.'));
                }
                return Expanded(
                  child: ListView.builder(
                    itemCount: shopOwnerIds.length,
                    itemBuilder: (context, index) {
                      return Card(
                          color: Color.fromARGB(255, 250, 211, 134), // Palitan ang background color ng Card

                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text('Shop Owner ID: ${shopOwnerIds[index]}'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


class ReviewScreen extends StatefulWidget {
  @override
  _ReviewScreenState createState() => _ReviewScreenState();
}
class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  String _review = '';
  String _currentReview = '';
  int _selectedCardIndex = -1; // Track the index of the selected card

  Stream<List<Map<String, dynamic>>> _finishStream(String userId) {
    return FirebaseFirestore.instance
        .collection('finish')
        .where('userId', isEqualTo: userId) // Filter by userId
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  void submitReview(BuildContext context, String shopOwnerId) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Add review to collection
    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'userId': userId,
        'shopOwnerId': shopOwnerId, // Add shopOwnerId to the review
        'rating': _rating,
        'review': _review,
        'timestamp': DateTime.now(),
      });
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review submitted successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
@override
Widget build(BuildContext context) {
  String userId = FirebaseAuth.instance.currentUser?.uid ?? ''; // Get current userId
  return Scaffold(
    backgroundColor: Color.fromARGB(211, 173, 98, 31), 
    appBar: AppBar(
      backgroundColor: Color.fromARGB(255, 255, 166, 0), // Palitan ang background color ng AppBar
      title: Text('Review'),
      actions: [
        IconButton(
          icon: Icon(Icons.logout), // I-icon para sa logout
          onPressed: () {
            FirebaseAuth.instance.signOut(); // Mag-logout gamit ang FirebaseAuth
            Navigator.pushReplacementNamed(context, '/login'); // Pumunta sa screen ng login
          },
        ),
      ],
    ),
    body: StreamBuilder<List<Map<String, dynamic>>>(
      stream: _finishStream(userId), // Pass userId to _finishStream
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        List<Map<String, dynamic>> bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return Center(child: Text('No bookings found.'));
        }
        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            // Display only the shopOwnerId from the finish collection
            String shopOwnerId = bookings[index]['shopOwnerId'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCardIndex = index;
                  _rating = 0; // Reset rating when a card is selected
                });
              },
              child: Card(
                color: Color.fromARGB(255, 250, 211, 134), // Palitan ang background color ng Card
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text('Shop Owner ID: $shopOwnerId'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${bookings[index]['status']}'),
                      SizedBox(height: 10),
                      _selectedCardIndex == index
                          ? Row(
                              children: <Widget>[
                                RatingBar.builder(
                                  initialRating: _rating.toDouble(),
                                  minRating: 1,
                                  direction: Axis.horizontal,
                                  allowHalfRating: false,
                                  itemCount: 5,
                                  itemSize: 30,
                                  itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                                  itemBuilder: (context, _) => Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  onRatingUpdate: (double rating) {
                                    setState(() {
                                      _rating = rating.toInt();
                                      print('Rating changed: $_rating');
                                    });
                                  },
                                ),
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Write your review here...',
                                    ),
                                    onChanged: (value) {
                                      _currentReview = value;
                                    },
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _review = _currentReview;
                                    });
                                    submitReview(context, shopOwnerId);
                                  },
                                  child: Text(
                                    'Submit',
                                    style: TextStyle(color: Colors.white), // Bagong kulay ng text
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color.fromARGB(211, 173, 98, 31), // Bagong background color
                                  ),
                                ),
                              ],
                            )
                          : SizedBox.shrink(), // Hide the stars if the card is not selected
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
}
class BookingForm extends StatefulWidget {
  @override
  _BookingFormState createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  late User _currentUser;
  late String _currentLocation = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _emailController = TextEditingController();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentLocation =
          '${position.latitude.toString()}, ${position.longitude.toString()}';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }
@override
Widget build(BuildContext context) {
  return SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Card(
        color: Color.fromARGB(255, 250, 211, 134),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.0),
               ElevatedButton(
  onPressed: () async {
    if (_formKey.currentState!.validate()) {
      try {
        String documentId = FirebaseFirestore.instance.collection('booking').doc().id;
        await _uploadBooking(documentId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Booking submitted successfully.', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
        Navigator.pop(context);
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit booking. Please try again.', style: TextStyle(color: Colors.white)),
          ),
        );
      }
    }
  },
  child: Text('Submit', style: TextStyle(color: Colors.white)),
  style: ElevatedButton.styleFrom(
    backgroundColor: Color.fromARGB(211, 173, 98, 31), // Bagong background color
  ),
),
SizedBox(height: 16.0),
TextButton(
  onPressed: () {
    Navigator.pop(context);
  },
  child: Text(
    'Cancel',
    style: TextStyle(color: Colors.white),
  ),
  style: TextButton.styleFrom(
    backgroundColor: Color.fromARGB(211, 173, 98, 31), // Bagong background color
  ),
),



              ],
            ),
          ),
        ),
      ),
    ),
  );
}


  Future<void> _uploadBooking(String documentId) async {
    try {
      await FirebaseFirestore.instance.collection('booking').doc(documentId).set({
        'bookingId': documentId, // Field para sa document ID ng booking
        'name': _nameController.text,
        'phoneNumber': _phoneNumberController.text,
        'email': _emailController.text,
        'currentLocation': _currentLocation,
        'timestamp': DateTime.now(),
        'userId': _currentUser.uid,
        'status': 'pending',
        'shopOwnerId': '',
      });
    } catch (error) {
      throw error;
    }
  }

  Future<String> getBookingStatus(String bookingId) async {
    final DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('booking').doc(bookingId).get();
    return snapshot['status'];
  }

  Future<String> getAcceptedShopOwner(String bookingId) async {
    final DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('booking').doc(bookingId).get();
    return snapshot['shopOwnerId'];
  }

  Future<List<DocumentSnapshot>> getUserBookings() async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('booking').where('userId', isEqualTo: _currentUser.uid).get();
    return querySnapshot.docs;
  }
}


class InformationScreen extends StatefulWidget {
  @override
  _InformationScreenState createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  late User? _user;
  final _formKey = GlobalKey<FormState>();
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  String _selectedRole = 'Customer';

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Information'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            width: 400,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'User ID: ${_user?.uid}',
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: InputDecoration(labelText: 'First Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(labelText: 'Last Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _saveUserInfo();
                          }
                        },
                        child: Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveUserInfo() async {
    String firstName = _firstNameController.text;
    String lastName = _lastNameController.text;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user?.uid)
          .set({
        'firstName': firstName,
        'lastName': lastName,
        'role': _selectedRole,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User information saved successfully'),
        ),
      );

      // Always set the role to Customer
      _selectedRole = 'Customer';

      // Navigate to the profile screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainApp()),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
        ),
      );
    }
  }
}