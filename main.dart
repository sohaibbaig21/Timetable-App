import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';

void main() {
  runApp(TimetableApp());
}

class TimetableApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timetable App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.pink[900],
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: AppBarTheme(color: Colors.pink[800]),
        floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: Colors.pink[700]),
        buttonTheme: ButtonThemeData(buttonColor: Colors.pink[600]),
      ),
      home: UploadScreen(),
    );
  }
}

class UploadScreen extends StatefulWidget {
  @override
  _UploadScreenState createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  List<String> courses = [];
  Map<String, dynamic> timetable = {};

  Future<void> pickExcelFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (result != null) {
      var bytes = result.files.single.bytes;
      if (bytes != null) {
        var excel = Excel.decodeBytes(bytes);
        processExcelData(excel);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel file uploaded successfully!')),
        );
      }
    }
  }

 void processExcelData(Excel excel) {
  setState(() {
    timetable.clear();
    courses.clear();
  });

  List<String> days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'];
  for (var day in days) {
    var sheet = excel.tables[day];
    if (sheet != null) {
      List<Map<String, String>> daySchedule = [];
      for (var row in sheet.rows.skip(3)) {
        if (row.isNotEmpty) {
          // Ensure we are getting the classroom from the first column
          String? classroom = row[0]?.value?.toString()?.trim();
          
          // Check if the classroom is not null or empty
          if (classroom == null || classroom.isEmpty) {
            classroom = "Unknown Classroom"; // Fallback if classroom is not available
          }

          for (int i = 1; i < row.length; i++) {
            String? course = row[i]?.value?.toString()?.trim();
            if (course != null && course.isNotEmpty) {
              // Ensure we properly add the course and its associated classroom
              daySchedule.add({
                'time': sheet.rows[1][i]?.value?.toString()?.trim() ?? '',
                'classroom': classroom,
                'course': course,
              });
              if (!courses.contains(course)) {
                courses.add(course);
              }
            }
          }
        }
      }
      if (daySchedule.isNotEmpty) {
        timetable[day] = daySchedule;
      }
    }
  }
  setState(() {});
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Timetable')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: pickExcelFile,
              child: Text('Upload Excel File'),
            ),
            SizedBox(height: 20),
            if (courses.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CourseSelectionScreen(courses, timetable)),
                  );
                },
                child: Text('Select Courses'),
              ),
          ],
        ),
      ),
    );
  }
}

class CourseSelectionScreen extends StatefulWidget {
  final List<String> courses;
  final Map<String, dynamic> timetable;
  CourseSelectionScreen(this.courses, this.timetable);

  @override
  _CourseSelectionScreenState createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  List<String> selectedCourses = [];
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    List<String> filteredCourses = widget.courses.where((course) => course.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Select Courses')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Course',
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                setState(() {
                  searchQuery = query;
                });
              },
            ),
          ),
          Expanded(
            child: ListView(
              children: filteredCourses.map((course) {
                return CheckboxListTile(
                  title: Text(course),
                  value: selectedCourses.contains(course),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedCourses.add(course);
                      } else {
                        selectedCourses.remove(course);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TimetableScreen(widget.timetable, selectedCourses)),
          );
        },
      ),
    );
  }
}

class TimetableScreen extends StatelessWidget {
  final Map<String, dynamic> timetable;
  final List<String> selectedCourses;

  TimetableScreen(this.timetable, this.selectedCourses);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Timetable')),
      body: ListView(
        children: timetable.entries.map((entry) {
          String day = entry.key;
          List<Map<String, String>> schedule = entry.value;
          List<Map<String, String>> filteredSchedule = schedule.where((s) => selectedCourses.contains(s['course'])).toList();
          
          return ExpansionTile(
            title: Text(day, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            children: filteredSchedule.map((slot) => ListTile(
              title: Text('${slot['time']} - ${slot['course']}'),
              subtitle: Text('Classroom: ${slot['classroom']}'),
            )).toList(),
          );
        }).toList(),
      ),
    );
  }
}
