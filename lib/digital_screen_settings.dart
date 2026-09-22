import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:web/web.dart' as web;
import 'package:google_fonts/google_fonts.dart';

import 'digital_screen.dart';

class DigitalScreenSettings extends StatefulWidget {
  const DigitalScreenSettings({super.key});

  @override
  State<DigitalScreenSettings> createState() => _DigitalScreenSettingsState();
}

class _DigitalScreenSettingsState extends State<DigitalScreenSettings> {
  final TextEditingController newsController = TextEditingController();

  bool isImageUploading = false;
  bool isNewsSaving = false;
  double slideDurationSeconds = 5.0;

  final String cloudName = "dklkkee5t";
  final String uploadPreset = "magnis";
  final String apiKey = "687849567946227";
  final String apiSecret = "_qC-F7qpR7aHgxUBVj05j-Ipv7s";

  static const Color bgBackground = Color(0xFF0F172A);
  static const Color bgSurface = Color(0xFF1E293B);
  static const Color accentColor = Colors.indigoAccent;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white60;

  @override
  void initState() {
    super.initState();
    _loadSlideDuration();
  }

  Future<void> _loadSlideDuration() async {
    var doc = await FirebaseFirestore.instance
        .collection('screen_settings')
        .doc('slideshow')
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
          .doc('slideshow')
          .set({'duration': duration.toInt()}, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error updating slide duration: $e");
    }
  }

  Future<void> uploadPhoto() async {
    final web.HTMLInputElement uploadInput =
        web.document.createElement('input') as web.HTMLInputElement;
    uploadInput.type = 'file';
    uploadInput.accept = 'image/*';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      if (uploadInput.files == null || uploadInput.files!.length == 0) {
        return;
      }
      final file = uploadInput.files!.item(0)!;
      final reader = web.FileReader();
      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((event) async {
        if (!mounted) return;
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
                filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
              ),
            );

          var response = await request.send();
          var responseData = await response.stream.bytesToString();

          if (response.statusCode == 200 || response.statusCode == 201) {
            var jsonResponse = jsonDecode(responseData);
            await FirebaseFirestore.instance
                .collection('cloudinary_photos')
                .add({
                  'imageUrl': jsonResponse['secure_url'],
                  'publicId': jsonResponse['public_id'] ?? '',
                  'createdAt': Timestamp.now(),
                  'showOnScreen': true,
                });
            _showMessage("Photo Uploaded Successfully!");
          }
        } catch (e) {
          _showMessage("Upload Error: $e", isError: true);
        } finally {
          if (mounted) setState(() => isImageUploading = false);
        }
      });
    });
  }

  Future<bool> _confirmDelete(BuildContext context, String itemType) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: bgSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  SizedBox(width: 10),
                  Text("Confirm Delete", style: TextStyle(color: textPrimary)),
                ],
              ),
              content: Text(
                "Are you sure you want to delete this $itemType?",
                style: const TextStyle(color: textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> deletePhoto(String docId, String publicId) async {
    bool confirm = await _confirmDelete(context, "photo");
    if (!confirm) return;

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
          .collection('cloudinary_photos')
          .doc(docId)
          .delete();
      _showMessage("Photo deleted successfully.");
    } catch (e) {
      _showMessage("Delete Error: $e", isError: true);
    }
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveNewsLine() async {
    String text = newsController.text.trim();
    if (text.isEmpty) {
      return;
    }
    setState(() => isNewsSaving = true);
    try {
      await FirebaseFirestore.instance.collection('news_lines').add({
        'text': text,
        'createdAt': Timestamp.now(),
        'showOnScreen': false,
      });
      newsController.clear();
      _showMessage("News line saved!");
    } catch (e) {
      _showMessage("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => isNewsSaving = false);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
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
    bool isMobile = screenWidth < 768;
    int crossAxisCount = screenWidth > 1200 ? 5 : (screenWidth > 768 ? 3 : 2);

    return Scaffold(
      backgroundColor: bgBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgSurface,
        title: const Text(
          "DIGITAL SCREEN SETTINGS",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 15 : 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slide Duration Control
            Container(
              decoration: BoxDecoration(
                color: bgSurface,
                borderRadius: BorderRadius.circular(16),
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
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: slideDurationSeconds,
                    min: 2,
                    max: 20,
                    divisions: 18,
                    activeColor: accentColor,
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

            // Photos Management Section
            Container(
              decoration: BoxDecoration(
                color: bgSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Upload Notice Board Photos",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  _buildProfessionalButton(
                    label: isImageUploading ? "Uploading..." : "Upload Photo",
                    icon: Icons.cloud_upload_rounded,
                    onPressed: isImageUploading ? null : uploadPhoto,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cloudinary_photos')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snapshot.data!.docs;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String originalUrl = data['imageUrl'] ?? '';

                    String thumbnailUrl = originalUrl.contains('/upload/')
                        ? originalUrl.replaceFirst(
                            '/upload/',
                            '/upload/f_auto,q_auto,w_400/',
                          )
                        : originalUrl;

                    return GestureDetector(
                      onTap: () => _showImagePreview(originalUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.network(
                                thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: bgBackground,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.white24,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.fullscreen_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Checkbox(
                                      activeColor: accentColor,
                                      value: data['showOnScreen'] ?? false,
                                      onChanged: (val) => FirebaseFirestore
                                          .instance
                                          .collection('cloudinary_photos')
                                          .doc(doc.id)
                                          .update({'showOnScreen': val}),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () => deletePhoto(
                                        doc.id,
                                        data['publicId'] ?? '',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 25),
            // News Announcement Section
            Container(
              decoration: BoxDecoration(
                color: bgSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: newsController,
                    style: const TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: "Type live announcement here...",
                      filled: true,
                      fillColor: bgBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: _buildProfessionalButton(
                      label: isNewsSaving ? "Saving..." : "Save News Line",
                      icon: Icons.campaign_rounded,
                      onPressed: isNewsSaving ? null : saveNewsLine,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('news_lines')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                var docs = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    return Card(
                      color: bgSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          doc['text'] ?? '',
                          style: GoogleFonts.gayathri(
                            color: textPrimary,
                            fontSize: 16,
                          ),
                        ),
                        leading: Switch(
                          activeColor: accentColor,
                          value: doc['showOnScreen'] ?? false,
                          onChanged: (val) => FirebaseFirestore.instance
                              .collection('news_lines')
                              .doc(doc.id)
                              .update({'showOnScreen': val}),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () async {
                            bool confirm = await _confirmDelete(
                              context,
                              "news line",
                            );
                            if (confirm) {
                              FirebaseFirestore.instance
                                  .collection('news_lines')
                                  .doc(doc.id)
                                  .delete();
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 30),
            Center(
              child: Container(
                width: isMobile ? double.infinity : 350,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [accentColor, Colors.indigo],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DigitalScreen()),
                  ),
                  label: const Text(
                    "LAUNCH LIVE DIGITAL SCREEN",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
