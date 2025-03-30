import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

// واجهة التطبيق الرئيسية لتحويل الصور إلى PDF
class ImageToPdfScreen extends StatefulWidget {
  @override
  _ImageToPdfScreenState createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  final picker = ImagePicker(); // كائن لاختيار الصور
  List<File> _images = []; // قائمة الصور الأصلية
  List<Uint8List?> _compressedImages = []; // قائمة الصور المضغوطة
  List<int> _imageSizes = []; // قائمة أحجام الصور بعد الضغط
  double _quality = 70.0; // جودة الصورة المضغوطة
  double _resizeFactor = 1.0; // نسبة تقليل الحجم
  int _imagesPerPage = 1; // عدد الصور في كل صفحة من PDF
  String? _savedPdfPath; // مسار ملف PDF المحفوظ

  // دالة لاختيار الصور من المعرض
  Future<void> pickImages() async {
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      List<File> originalFiles = pickedFiles.map((file) => File(file.path)).toList();
      List<Uint8List?> compressedList = [];
      List<int> sizesList = [];

      // ضغط كل صورة وحساب حجمها الجديد
      for (var file in originalFiles) {
        Uint8List? compressed = await compressImage(file, _quality.toInt(), _resizeFactor);
        compressedList.add(compressed);
        sizesList.add(compressed?.lengthInBytes ?? 0);
      }

      setState(() {
        _images.addAll(originalFiles);
        _compressedImages.addAll(compressedList);
        _imageSizes.addAll(sizesList);
      });
    }
  }

  // دالة لضغط الصور
  Future<Uint8List?> compressImage(File file, int quality, double resizeFactor) async {
    Uint8List? result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: quality,
      format: CompressFormat.jpeg,
      minWidth: (1000 * resizeFactor).toInt(),
      minHeight: (1000 * resizeFactor).toInt(),
    );
    return result;
  }

  // دالة لحذف صورة من القائمة
  void removeImage(int index) {
    setState(() {
      _images.removeAt(index);
      _compressedImages.removeAt(index);
      _imageSizes.removeAt(index);
    });
  }

  // دالة لإعادة ضغط الصور بعد تغيير الجودة أو الحجم
  Future<void> reprocessImages() async {
    List<Uint8List?> updatedCompressedImages = [];
    List<int> updatedSizes = [];
    for (var file in _images) {
      Uint8List? compressed = await compressImage(file, _quality.toInt(), _resizeFactor);
      updatedCompressedImages.add(compressed);
      updatedSizes.add(compressed?.lengthInBytes ?? 0);
    }
    setState(() {
      _compressedImages = updatedCompressedImages;
      _imageSizes = updatedSizes;
    });
  }

  // دالة لتحويل الصور المضغوطة إلى ملف PDF
  Future<void> convertToPdf() async {
    if (_compressedImages.isEmpty) return;
    final pdf = pw.Document();
    int pageCount = (_compressedImages.length / _imagesPerPage).ceil();

    for (int i = 0; i < pageCount; i++) {
      List<pw.Widget> pageImages = [];
      for (int j = 0; j < _imagesPerPage; j++) {
        int index = i * _imagesPerPage + j;
        if (index < _compressedImages.length && _compressedImages[index] != null) {
          final pdfImage = pw.MemoryImage(_compressedImages[index]!);
          pageImages.add(pw.Expanded(child: pw.Image(pdfImage, fit: pw.BoxFit.contain)));
        }
      }
      pdf.addPage(pw.Page(build: (pw.Context context) => pw.Column(children: pageImages)));
    }

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/converted_images.pdf");
    await file.writeAsBytes(await pdf.save());

    setState(() {
      _savedPdfPath = file.path;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("تم حفظ PDF في: ${file.path}")),
    );
  }

  // تحسين جودة الصور إلى الحد الأقصى
  void enhanceImageQuality() {
    setState(() {
      _quality = 100.0;
      _resizeFactor = 1.0;
    });
    reprocessImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('تحويل الصور إلى PDF'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: _images.isNotEmpty
                ? GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image.file(_images[index], fit: BoxFit.cover, width: double.infinity),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    "الحجم: ${( _imageSizes[index] / 1024).toStringAsFixed(2)} KB",
                                    style: TextStyle(fontSize: 12, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: GestureDetector(
                              onTap: () => removeImage(index),
                              child: CircleAvatar(
                                backgroundColor: Colors.red,
                                radius: 12,
                                child: Icon(Icons.close, size: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : Center(child: Text('اختر صورًا', style: TextStyle(fontSize: 18))),
          ),
          ElevatedButton(onPressed: pickImages, child: Text("تحميل الصور")),
          ElevatedButton(onPressed: convertToPdf, child: Text("تحويل إلى PDF")),
        ],
      ),
    );
  }
}
