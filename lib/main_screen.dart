import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController _imageController = PageController();
  int currentImage = 0;

  List<String> images = [];
  bool _isLoadingData = true;

  Timer? _dataTimer;
  Timer? _slideTimer;
  StreamSubscription<DocumentSnapshot>? _settingsSubscription;

  int slideDuration = 5; // 🟢 Default duration

  @override
  void initState() {
    super.initState();
    _listenToSlideDuration(); // 🟢 slideshow2 തത്സമയം ലിസൺ ചെയ്യുന്നു
    _fetchFirebaseData();

    // 5 മിനിറ്റിൽ ഫയർബേസ് ഡാറ്റ പുതുക്കുന്നു
    _dataTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _fetchFirebaseData(),
    );

    _startSlideShow();
  }

  // 🟢 slideshow2 ലെ മാറ്റങ്ങൾ ലൈവ് ആയി സ്ട്രീം ചെയ്യുന്നു
  void _listenToSlideDuration() {
    _settingsSubscription = FirebaseFirestore.instance
        .collection('screen_settings')
        .doc('slideshow2')
        .snapshots()
        .listen((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            var data = snapshot.data() as Map<String, dynamic>;
            int newDuration = (data['duration'] ?? 5).toInt();
            if (newDuration != slideDuration && newDuration > 0) {
              slideDuration = newDuration;
              _restartSlideShow();
            }
          }
        }, onError: (e) => debugPrint("Slide speed stream error: $e"));
  }

  Future<void> _fetchFirebaseData() async {
    try {
      var photosSnapshot = await FirebaseFirestore.instance
          .collection('main_photos')
          .where('showOnScreen', isEqualTo: true)
          .get();

      List<String> tempImages = photosSnapshot.docs
          .map(
            (doc) => (doc.data()).containsKey('imageUrl')
                ? doc['imageUrl'].toString()
                : '',
          )
          .where((url) => url.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          images = tempImages;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void _startSlideShow() {
    _slideTimer?.cancel();
    _slideTimer = Timer.periodic(Duration(seconds: slideDuration), (timer) {
      if (!mounted || images.isEmpty) return;
      if (currentImage < images.length - 1) {
        currentImage++;
      } else {
        currentImage = 0;
      }
      if (_imageController.hasClients) {
        _imageController.animateToPage(
          currentImage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _restartSlideShow() {
    _startSlideShow();
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    _dataTimer?.cancel();
    _slideTimer?.cancel();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0EA5E9)),
            )
          : images.isEmpty
          ? const Center(
              child: Text(
                "NO POSTER SELECTED FOR MAIN SCREEN",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white24,
                ),
              ),
            )
          : SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: PageView.builder(
                controller: _imageController,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    images[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          "Image Missing",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 20,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}
