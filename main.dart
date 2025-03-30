import 'package:flutter/material.dart';
import 'package:imgtopdf/imagetopdf.dart';

void main() {
  runApp(MyApp());
}

class  MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'تحويل الصور إلى PDF',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ImageToPdfScreen(), // يجب أن يكون لديك هذا الكلاس في ملف آخر أو في نفس الملف
    );
  }
}