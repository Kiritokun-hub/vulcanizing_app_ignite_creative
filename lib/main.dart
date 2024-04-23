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
  List<Widget> screens = [HomeScreen(), ProfileScreen(), ReviewScreen()];

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
        appBar: AppBar(title: const Text('Ignite Creative')),
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
                    icon: Icon(Icons.person),
                    label: 'Profile',
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
      appBar: AppBar(
        title: Text('Home'),
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
            child: Icon(Icons.add),
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingInProgressScreen(userId: 'UserId',),
                ),
              );
            },
            child: Icon(Icons.timer), // Stopwatch icon represents booking in process
          ),
        ],
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
      appBar: AppBar(
        title: const Text('Book Accepted'),
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  // Stream to listen for changes in the finish collection with matching userId
  Stream<List<Map<String, dynamic>>> _finishStream(String userId) {
    return FirebaseFirestore.instance
        .collection('finish')
        .where('userId', isEqualTo: userId) // Filter by userId
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  // Function to submit review
  void submitReview(BuildContext context) async {
    String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Add review to collection
    try {
      await FirebaseFirestore.instance.collection('reviews').add({
        'userId': userId,
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
      appBar: AppBar(
        title: Text('Review'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
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
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text('Shop Owner ID: ${bookings[index]['shopOwnerId']}'),
                        // You can add more details if needed
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Status: ${bookings[index]['status']}'),
                            SizedBox(height: 10),
                            // Review submission section
                            Row(
                              children: <Widget>[
                                // Rating bar
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
                                    });
                                  },
                                ),
                                // Review text input
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Write your review here...',
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _review = value;
                                      });
                                    },
                                  ),
                                ),
                                // Submit button
                                ElevatedButton(
                                  onPressed: () {
                                    // Call submitReview when the user presses the submit button
                                    submitReview(context);
                                  },
                                  child: Text('Submit'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: 20),
          // Optionally, you can add a form for submitting reviews here
          // For example:
          // ReviewForm(),
        ],
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
                              Text('Booking submitted successfully.'),
                            ],
                          ),
                        ),
                      );
                      Navigator.pop(context);
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to submit booking. Please try again.'),
                        ),
                      );
                    }
                  }
                },
                child: Text('Submit'),
              ),
              SizedBox(height: 16.0),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
            ],
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
      body: Center(
        child: const Text('Profile content goes here'),
      ),
    );
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
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        items: ['Shop Owner', 'Customer']
                            .map((role) => DropdownMenuItem(
                                  child: Text(role),
                                  value: role,
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
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

      // Navigate to the appropriate screen based on user role
      if (_selectedRole == 'Shop Owner') {
        // Navigate back to the main screen
        Navigator.pop(context);
      } else {
        // Navigate to the profile screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainApp()),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
        ),
      );
    }
  }
}