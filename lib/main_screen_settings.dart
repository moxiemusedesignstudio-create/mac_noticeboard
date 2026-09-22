import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:web/web.dart' as web;

class MainScreenSettings extends StatefulWidget {
  const MainScreenSettings({super.key});

  @override
  State<MainScreenSettings> createState() => _MainScreenSettingsState();
}

class _MainScreenSettingsState extends State<MainScreenSettings> {
  bool isImageUploading = false;
  double slideDurationSeconds = 5.0; // 🟢 slideshow2 duration state

  final String cloudName = "dklkkee5t";
  final String uploadPreset = "magnis";
  final String apiKey = "687849567946227";
  final String apiSecret = "_qC-F7qpR7aHgxUBVj05j-Ipv7s";

  static const Color bgBackground = Color(0xFF0F172A);
  static const Color bgSurface = Color(0xFF1E293B);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white60;

  @override
  void initState() {
    super.initState();
    _loadSlideDuration(); // 🟢 slideshow2 സമയം ലോഡ് ചെയ്യുന്നു
  }

  Future<void> _loadSlideDuration() async {
    var doc = await FirebaseFirestore.instance
        .collection('screen_settings')
        .doc('slideshow2') // 🟢 slideshow2 വാല്യൂ റീഡ് ചെയ്യുന്നു
        .get();
    if (doc.exists && doc.data() != null) {
      setState(() {
        slideDurationSeconds = (doc.data()!['duration'] ?? 5.0).toDouble();
      });
    }
  }

  Future<void> _saveSlideDuration(double duration) async {
    try {
      await FirebaseFirestore.instance
          .collection('screen_settings')
          .doc('slideshow2') // 🟢 slideshow2 ലേക്ക് സേവ് ചെയ്യുന്നു
          .set({'duration': duration.toInt()}, SetOptions(merge: true));
      _showMessage("Slideshow 2 duration updated!");
    } catch (e) {
      _showMessage("Error updating slide duration: $e", isError: true);
    }
  }

  Future<void> uploadPhoto() async {
    final web.HTMLInputElement uploadInput =
        web.document.createElement('input') as web.HTMLInputElement;
    uploadInput.type = 'file';
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      if (uploadInput.files == null || uploadInput.files!.length == 0) return;
      final file = uploadInput.files!.item(0)!;
      final reader = web.FileReader();
      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((event) async {
        setState(() => isImageUploading = true);
        try {
          final jsBuffer = reader.result as JSArrayBuffer;
          final ByteBuffer buffer = jsBuffer.toDart;
          Uint8List imageData = buffer.asUint8List();

          final url = Uri.parse(
            'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
          );
          var request = http.MultipartRequest('POST', url)
            ..fields['upload_preset'] = uploadPreset
            ..files.add(
              http.MultipartFile.fromBytes(
                'file',
                imageData,
                filename: 'main_${DateTime.now().millisecondsSinceEpoch}.jpg',
              ),
            );

          var response = await request.send();
          var responseData = await response.stream.bytesToString();

          if (response.statusCode == 200 || response.statusCode == 201) {
            var jsonResponse = jsonDecode(responseData);
            String imageUrl = jsonResponse['secure_url'];
            String publicId = jsonResponse['public_id'] ?? '';

            await FirebaseFirestore.instance.collection('main_photos').add({
              'imageUrl': imageUrl,
              'publicId': publicId,
              'createdAt': Timestamp.now(),
              'showOnScreen': true,
            });

            _showMessage("Photo Uploaded Successfully!");
          } else {
            _showMessage("Upload failed.", isError: true);
          }
        } catch (e) {
          _showMessage("Error: $e", isError: true);
        } finally {
          setState(() => isImageUploading = false);
        }
      });
    });
  }

  void _showImagePreviewDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              // 1. Zoomable Image Container
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            "Failed to load image",
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // 2. Floating Close Button
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black87,
                  radius: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndDelete(String docId, String publicId) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: bgSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
              SizedBox(width: 10),
              Text(
                "Delete Photo?",
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            "Are you sure you want to delete this photo?",
            style: TextStyle(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                "Delete",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await deletePhoto(docId, publicId);
    }
  }

  Future<void> deletePhoto(String docId, String publicId) async {
    try {
      if (publicId.isNotEmpty) {
        final int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final String signatureSource =
            "public_id=$publicId&timestamp=$timestamp$apiSecret";
        final String signature = sha1
            .convert(utf8.encode(signatureSource))
            .toString();

        final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/destroy',
        );
        await http.post(
          url,
          body: {
            'public_id': publicId,
            'timestamp': timestamp.toString(),
            'api_key': apiKey,
            'signature': signature,
          },
        );
      }
      await FirebaseFirestore.instance
          .collection('main_photos')
          .doc(docId)
          .delete();
      _showMessage("Photo deleted permanently!");
    } catch (e) {
      _showMessage("Error deleting photo: $e", isError: true);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 1200 ? 5 : (screenWidth > 768 ? 3 : 2);

    return Scaffold(
      backgroundColor: bgBackground,
      appBar: AppBar(
        backgroundColor: bgSurface,
        elevation: 0,
        title: const Text("MAIN SCREEN SETTINGS"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🟢 Slideshow 2 Duration Control (സ്ലൈഡ് സ്പീഡ് മാറ്റാനുള്ള സെക്ഷൻ)
            Container(
              decoration: BoxDecoration(
                color: bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Slide Transition Speed",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        "${slideDurationSeconds.toInt()} Seconds",
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: slideDurationSeconds,
                    min: 2,
                    max: 30,
                    divisions: 28,
                    activeColor: const Color(0xFF2563EB),
                    inactiveColor: Colors.white24,
                    label: "${slideDurationSeconds.toInt()} sec",
                    onChanged: (val) {
                      setState(() {
                        slideDurationSeconds = val;
                      });
                    },
                    onChangeEnd: (val) {
                      _saveSlideDuration(val);
                    },
                  ),
                ],
              ),
            ),

            // Upload Poster Section
            Container(
              decoration: BoxDecoration(
                color: bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Upload Main Screen Posters",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Images will display as full screen fit on TV",
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: isImageUploading ? null : uploadPhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: textPrimary,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: isImageUploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: textPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.cloud_upload_rounded, size: 20),
                    label: const Text(
                      "Upload Photo",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Manage Main Screen Posters",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('main_photos')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Text(
                    "No photos uploaded yet.",
                    style: TextStyle(color: Colors.white38),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    bool isLive = data['showOnScreen'] ?? false;
                    String imageUrl = data['imageUrl'] ?? '';

                    return Container(
                      decoration: BoxDecoration(
                        color: bgSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isLive
                              ? const Color(0xFF2563EB)
                              : Colors.white10,
                          width: isLive ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (imageUrl.isNotEmpty) {
                                  _showImagePreviewDialog(imageUrl);
                                }
                              },
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      activeColor: const Color(0xFF2563EB),
                                      value: isLive,
                                      onChanged: (val) => FirebaseFirestore
                                          .instance
                                          .collection('main_photos')
                                          .doc(doc.id)
                                          .update({'showOnScreen': val}),
                                    ),
                                    const Text(
                                      "Live",
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Material(
                                  color: Colors.redAccent.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _confirmAndDelete(
                                        doc.id,
                                        data['publicId'] ?? '',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
