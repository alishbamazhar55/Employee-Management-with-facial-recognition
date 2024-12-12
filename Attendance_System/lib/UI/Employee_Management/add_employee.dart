import 'dart:io' show File;
import 'package:animate_do/animate_do.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:html' as html; // For web

import 'package:intl/intl.dart'; 



final String? Ip = dotenv.env['IP'];
final String? Port = dotenv.env['PORT'];

class AddEmployeeScreen extends StatefulWidget {
  const AddEmployeeScreen({Key? key}) : super(key: key);

  @override
  _AddEmployeeScreenState createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  DateTime? selectedDOB;
  String? selectedDesignation;
  String? selectedShift;
  String? customFileName;

  final List<String> designations = [
    'Manager',
    'Staff',
    'Finance Manager',
    'Chef',
    'Janitor'
  ];
  final List<String> shifts = ['Morning', 'Afternoon', 'Night'];

  CameraController? cameraController;

  Future<void> _submitEmployee() async {
    if (_formKey.currentState?.validate() ?? false) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? employeeId = prefs.getInt('employeeId');

      if (employeeId != null) {
        final response = await http.post(
          Uri.parse('http://$Ip:$Port/employee'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            'first_name': firstNameController.text,
            'last_name': lastNameController.text,
            'email': emailController.text,
            'cnic': cnicController.text,
            'phone_number': phoneController.text,
            'salary': salaryController.text,
            'username': usernameController.text,
            'password': passwordController.text,
            'dob': selectedDOB?.toIso8601String(),
            'designation': selectedDesignation,
            'shift': selectedShift,
            'addedBy': employeeId,
           'ProfilePhoto': "images/Upload_Pictures/$customFileName",

          }),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Employee added successfully!')),
          );
          _clearForm();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${jsonDecode(response.body)['error']}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Employee ID not found in SharedPreferences')),
        );
      }
    }
  }

  Future<void> _setCameraController() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      setState(() {
        cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
        );
      });

      try {
        await cameraController?.initialize();
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cameras available')),
      );
    }
  }




  CameraController? _cameraController;

  Future<void> _openCameraModal() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cameras available')),
      );
      return;
    }

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
    );

    try {
      await _cameraController!.initialize();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize camera: $e')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: _cameraController!.value.aspectRatio,
                  child: CameraPreview(_cameraController!),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final image = await _cameraController?.takePicture();
                        if (image != null) {
                          await _uploadImageToServer(image);
                        }
                      } catch (e) {
                        print("'Error capturing image: $e'");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error capturing image: $e')),
                        );
                      }
                    },
                    icon: const Icon(Icons.camera),
                    label: const Text('Capture Image'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    await _cameraController?.dispose();
  }


Future<void> _uploadImageToServer(XFile image) async {
  final uri = Uri.parse('http://$Ip:$Port/upload'); // Replace with your server URL
  final request = http.MultipartRequest('POST', uri);

  // Generate a custom filename with the current date
  final String formattedDate = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  customFileName = 'image_$formattedDate.jpg';

  if (kIsWeb) {
    // Web: Convert the XFile to a Blob (needed for Flutter Web)
    final byteData = await image.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'file', 
        byteData, 
        filename: customFileName, // Set custom filename here
      ),
    );
  } else {
    // Mobile/Desktop: Use the XFile's path to upload directly
    request.files.add(
      await http.MultipartFile.fromPath(
        'file', 
        image.path,
        filename: customFileName, // Set custom filename here
      ),
    );
  }

  try {
    final response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: ${response.statusCode}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error uploading image: $e')),
    );
  }
}





    void _clearForm() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    cnicController.clear();
    phoneController.clear();
    salaryController.clear();
    usernameController.clear();
    passwordController.clear();
    setState(() {
      selectedDOB = null;
      selectedDesignation = null;
      selectedShift = null;
      customFileName = null;
    });
    _formKey.currentState?.reset();
  }
  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.blueGrey[900] ?? Colors.blueGrey,
              Colors.blueGrey[700] ?? Colors.blueGrey,
              Colors.blueGrey[400] ?? Colors.blueGrey,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: screenHeight * 0.07),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.01,
                horizontal: screenWidth * 0.03,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FadeInUp(
                    duration: const Duration(milliseconds: 1000),
                    child: const Text(
                      "Add Employee's Information",
                      style: TextStyle(color: Colors.white, fontSize: 40),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.01),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenHeight * 0.02,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                    horizontal: screenWidth * 0.03,
                  ),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          SizedBox(height: screenHeight * 0.03),
                          FadeInUp(
                            duration: const Duration(milliseconds: 1400),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.blueGrey[200] ?? Colors.blueGrey,
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment:MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  buildTextField(
                                      firstNameController, "First Name",
                                      isAlphabetOnly: true),
                                  buildTextField(
                                      lastNameController, "Last Name",
                                      isAlphabetOnly: true),
                                  buildTextField(emailController, "Email",
                                      isEmail: true),
                                  buildTextField(cnicController, "CNIC",
                                      isNumeric: true),
                                  buildTextField(
                                      phoneController, "Phone Number",
                                      isNumeric: true),
                                  buildTextField(
                                    salaryController,
                                    "Salary",
                                  ),
                                  buildTextField(
                                      usernameController, "Username"),
                                  buildTextField(passwordController, "Password",
                                      obscureText: true),
                                  buildDateOfBirthField(context),
                                  buildDropdown(
                                      "Select Designation", designations,
                                      (value) {
                                    setState(() {
                                      selectedDesignation = value;
                                    });
                                  }, selectedDesignation),
                                  buildDropdown("Select Shift", shifts,
                                      (value) {
                                    setState(() {
                                      selectedShift = value;
                                    });
                                  }, selectedShift),
                                  const SizedBox(height: 20),
                                  
                                  
                                        ElevatedButton.icon(
                                        onPressed:  _openCameraModal, // Open the camera modal
                                        icon: const Icon(Icons.camera_alt),
                                        label: const Text('Capture Image'),
                                      ),

                                     buildImagePreview(),
                                    
                                  

                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.05),
                          FadeInUp(
                            duration: const Duration(milliseconds: 1600),
                            child: MaterialButton(
                              onPressed: _submitEmployee,
                              height: 50,
                              color: Colors.blueGrey[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Center(
                                child: Text(
                                  "Submit",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String hintText,
      {bool obscureText = false,
      bool isEmail = false,
      bool isNumeric = false,
      bool isAlphabetOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: hintText,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.red, width: 2.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.red, width: 2.0),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty && hintText != "Last Name") {
            return 'Please enter $hintText';
          }
          if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Please enter a valid email address';
          }
          if (isNumeric) {
            if (hintText == "CNIC" &&
                (value.length != 13 || !RegExp(r'^[0-9]+$').hasMatch(value))) {
              return 'CNIC must be 13 digits';
            } else if (hintText == "Phone Number" &&
                (value.length != 11 || !RegExp(r'^[0-9]+$').hasMatch(value))) {
              return 'Phone Number must be 11 digits';
            }
          }
          if (isAlphabetOnly && !RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
            if (hintText == "Last Name" && value.isEmpty) {
              return null;
            }
            return 'Only alphabets are allowed';
          }
          if (hintText == "Salary") {
            double? salary = double.tryParse(value);
            if (salary == null || salary < 20000 || salary > 10000000) {
              return 'Salary must be between 20000 and 10000000';
            }
          }
          if (hintText == "Password") {
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
              return 'Password must contain at least one uppercase letter';
            }
            if (!RegExp(r'(?=.*[a-z])').hasMatch(value)) {
              return 'Password must contain at least one lowercase letter';
            }
            if (!RegExp(r'(?=.*[0-9])').hasMatch(value)) {
              return 'Password must contain at least one number';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget buildDateOfBirthField(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          setState(() {
            selectedDOB = pickedDate;
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedDOB != null
                    ? "${selectedDOB!.day}/${selectedDOB!.month}/${selectedDOB!.year}"
                    : "Select Date of Birth",
                style: TextStyle(
                  color: selectedDOB != null ? Colors.black : Colors.grey,
                  fontSize: 16.0,
                ),
              ),
              const Icon(Icons.calendar_today, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDropdown(String hint, List<String> items, ValueChanged<String?> onChanged, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
        hint: Text(hint),
        value: value,
        onChanged: onChanged,
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
      ),
    );
  }


  Widget buildImagePreview() {
  if (customFileName != null) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          'Selected Image: ${customFileName!.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Image.file(
          File(customFileName!.path!),
          height: 150,
          fit: BoxFit.cover,
        ),
      ],
    );
  } else {
    return const SizedBox(); // Return empty widget if no image is selected
  }
}

}

extension on String {
  get name => null;
  
  get path => null;
}