import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'score_slider.dart';

class DigitalScreen extends StatefulWidget {
  const DigitalScreen({super.key});

  @override
  State<DigitalScreen> createState() => _DigitalScreenState();
}

class _DigitalScreenState extends State<DigitalScreen> {
  final PageController _imageController = PageController();

  final ValueNotifier<int> _currentImageNotifier = ValueNotifier<int>(0);
  final ValueNotifier<String> _updatesNotifier = ValueNotifier<String>(
    "MAGNIS MAC UPDATES",
  );

  List<String> images = [];
  bool _isLoadingData = true;

  Timer? _dataTimer;
  Timer? _slideTimer;
  StreamSubscription<DocumentSnapshot>? _settingsSubscription;

  int slideDuration = 5;

  @override
  void initState() {
    super.initState();
    _listenToSlideDuration();
    _fetchFirebaseData();

    // Polling every 5 minutes
    _dataTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _fetchFirebaseData(),
    );

    startSlideShow();
  }

  void _listenToSlideDuration() {
    _settingsSubscription = FirebaseFirestore.instance
        .collection('screen_settings')
        .doc('slideshow')
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
          .collection('cloudinary_photos')
          .where('showOnScreen', isEqualTo: true)
          .get();

      List<String> tempImages = [];
      for (var doc in photosSnapshot.docs) {
        var data = doc.data();
        if (data.containsKey('imageUrl') && data['imageUrl'] != null) {
          String originalUrl = data['imageUrl'].toString();
          if (originalUrl.isNotEmpty) {
            // ക്വാളിറ്റി കുറയ്ക്കാതെ Original URL നേരിട്ട് ആഡ് ചെയ്യുന്നു
            tempImages.add(originalUrl);
          }
        }
      }

      // 2. Fetch UPDATES (news_lines)
      String tempUpdates = "MAGNIS MAC UPDATES";

      var newsSnapshot = await FirebaseFirestore.instance
          .collection('news_lines')
          .where('showOnScreen', isEqualTo: true)
          .get();

      if (newsSnapshot.docs.isNotEmpty) {
        List<String> newsList = [];
        for (var doc in newsSnapshot.docs) {
          var data = doc.data();
          if (data.containsKey('text') && data['text'] != null) {
            String txt = data['text'].toString().trim();
            if (txt.isNotEmpty) newsList.add(txt);
          }
        }
        if (newsList.isNotEmpty) {
          tempUpdates = newsList.join("   ---   ");
        }
      }

      _updatesNotifier.value = tempUpdates;

      if (mounted) {
        setState(() {
          images = tempImages;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint("Firebase Fetch Error Handled: $e");
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  void startSlideShow() {
    _slideTimer?.cancel();
    _slideTimer = Timer.periodic(Duration(seconds: slideDuration), (timer) {
      if (!mounted || images.isEmpty) return;
      int nextImage = (_currentImageNotifier.value < images.length - 1)
          ? _currentImageNotifier.value + 1
          : 0;
      if (_imageController.hasClients) {
        _imageController.animateToPage(
          nextImage,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeIn,
        );
      }
    });
  }

  void _restartSlideShow() {
    startSlideShow();
  }

  @override
  void dispose() {
    _settingsSubscription?.cancel();
    _dataTimer?.cancel();
    _slideTimer?.cancel();
    _imageController.dispose();
    _currentImageNotifier.dispose();
    _updatesNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgBackground = Color(0xFF0B0F19);
    const Color bgSurface = Color(0xFF161D2F);
    const Color bgCard = Color(0xFF242F49);
    const Color accentColor = Color(0xFF10B981);
    const Color textPrimary = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgBackground,
      body: Column(
        children: [
          // HEADER AREA
          Container(
            height: 90,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: bgSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: bgCard.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.display_settings_rounded,
                      color: accentColor,
                      size: 36,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "MAGNIS MAC UPDATES",
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "DIGITAL NOTICEBOARD",
                          style: TextStyle(
                            color: accentColor.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const DigitalClockDisplay(),
              ],
            ),
          ),

          // MAIN BODY
          Expanded(
            child: Row(
              children: [
                // POSTER SLIDER
                Expanded(
                  flex: 4,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 6, 6, 12),
                    decoration: BoxDecoration(
                      color: bgSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: bgCard.withValues(alpha: 0.4)),
                    ),
                    child: _isLoadingData
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: accentColor,
                              strokeWidth: 3,
                            ),
                          )
                        : images.isEmpty
                        ? const Center(
                            child: Text(
                              "NO POSTER SELECTED FOR LIVE SCREEN",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white24,
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              color: bgSurface,
                              child: Column(
                                children: [
                                  // 1. ഫോട്ടോ മാത്രം വരുന്ന ഭാഗം
                                  Expanded(
                                    child: PageView.builder(
                                      controller: _imageController,
                                      itemCount: images.length,
                                      onPageChanged: (index) {
                                        _currentImageNotifier.value = index;
                                      },
                                      itemBuilder: (context, index) {
                                        return Image.network(
                                          images[index],
                                          fit: BoxFit.contain,
                                          cacheWidth: 1080,
                                          errorBuilder: (_, _, _) =>
                                              const Center(
                                                child: Text(
                                                  "Image Missing",
                                                  style: TextStyle(
                                                    color: Colors.redAccent,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                        );
                                      },
                                    ),
                                  ),

                                  // 2. പോസ്റ്ററിന് തികച്ചും പുറത്ത് അടിയിലായി മാത്രമുള്ള Smooth Dots Bar
                                  if (images.length > 1)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: ValueListenableBuilder<int>(
                                        valueListenable: _currentImageNotifier,
                                        builder: (context, currentIndex, child) {
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: List.generate(
                                              images.length,
                                              (index) {
                                                bool isActive =
                                                    currentIndex == index;
                                                return AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 250,
                                                  ),
                                                  curve: Curves.easeOut,
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 3,
                                                      ),
                                                  height: 7,
                                                  width: isActive ? 22 : 7,
                                                  decoration: BoxDecoration(
                                                    color: isActive
                                                        ? accentColor
                                                        : Colors.white
                                                              .withValues(
                                                                alpha: 0.25,
                                                              ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),

                // LIVE SCORE PANEL & BITHAQA CHAMPIONS
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(6, 6, 12, 6),
                          decoration: BoxDecoration(
                            color: bgSurface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: bgCard.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const ClipRRect(
                            borderRadius: BorderRadius.all(Radius.circular(18)),
                            child: ScoreSlider(),
                          ),
                        ),
                      ),

                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('bithaqa_champions')
                            .doc('current')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              snapshot.data == null ||
                              !snapshot.data!.exists) {
                            return const SizedBox.shrink();
                          }

                          var data =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          if (data == null) return const SizedBox.shrink();

                          bool isEnabled = data['isEnabled'] ?? false;
                          if (!isEnabled) return const SizedBox.shrink();

                          String bithaqaDate = data['date'] ?? 'SELECT DATE';
                          List<String> champions = [
                            data['champ1'] ?? '',
                            data['champ2'] ?? '',
                            data['champ3'] ?? '',
                            data['champ4'] ?? '',
                          ];

                          return Container(
                            height: 180,
                            margin: const EdgeInsets.fromLTRB(6, 6, 12, 12),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: bgSurface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFF0F766E),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "BITHAQA CHAMPIONS",
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  bithaqaDate.toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: champions.asMap().entries.map((
                                      entry,
                                    ) {
                                      int index = entry.key;
                                      String name = entry.value;

                                      Color boxColor = (index == 0)
                                          ? Colors.black
                                          : (name.isEmpty
                                                ? Colors.transparent
                                                : const Color(
                                                    0xFFDC2626,
                                                  ).withValues(alpha: 0.85));

                                      BoxBorder? boxBorder = (index == 0)
                                          ? Border.all(
                                              color: Colors.white,
                                              width: 1.2,
                                            )
                                          : (name.isNotEmpty
                                                ? Border.all(
                                                    color: Colors.white,
                                                    width: 1,
                                                  )
                                                : Border.all(
                                                    color: Colors.white12,
                                                  ));

                                      return Container(
                                        width: double.infinity,
                                        height: 25,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: boxColor,
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                          border: boxBorder,
                                        ),
                                        child: Text(
                                          name.isNotEmpty ? name : "name here",
                                          style: TextStyle(
                                            color: name.isNotEmpty
                                                ? textPrimary
                                                : Colors.white30,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // OPTIMIZED UPDATES TICKER (UPDATES ONLY)
          Container(
            height: 55,
            decoration: const BoxDecoration(
              color: bgSurface,
              border: Border(
                top: BorderSide(color: Colors.white10, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  color: accentColor,
                  height: double.infinity,
                  alignment: Alignment.center,
                  child: const Text(
                    "UPDATES",
                    style: TextStyle(
                      color: bgBackground,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                Expanded(
                  child: RepaintBoundary(
                    child: ValueListenableBuilder<String>(
                      valueListenable: _updatesNotifier,
                      builder: (context, text, child) {
                        return TvSmoothTicker(
                          text: text.toUpperCase(),
                          textStyle: GoogleFonts.gayathri(
                            color: textPrimary.withValues(alpha: 0.95),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TV TICKER (OVERFLOW BUG FIXED & SEAMLESS LOOP)
// ---------------------------------------------------------------------------
class TvSmoothTicker extends StatefulWidget {
  final String text;
  final TextStyle textStyle;

  const TvSmoothTicker({
    super.key,
    required this.text,
    required this.textStyle,
  });

  @override
  State<TvSmoothTicker> createState() => _TvSmoothTickerState();
}

class _TvSmoothTickerState extends State<TvSmoothTicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const String defaultText = "MISBAHUL HUDA UPDATES 2026-27";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _checkAndStartAnimation();
  }

  void _checkAndStartAnimation() {
    bool isDefaultNews = (widget.text.trim() == defaultText);

    if (isDefaultNews) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
    } else {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  void didUpdateWidget(covariant TvSmoothTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.reset();
      _checkAndStartAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDefaultNews = (widget.text.trim() == defaultText);

    // 1. വാർത്തകൾ ഇല്ലാത്തപ്പോൾ നടുവിൽ Static ആയി നിൽക്കും
    if (isDefaultNews) {
      return Center(
        child: Text(
          widget.text,
          style: widget.textStyle,
          maxLines: 1,
          textAlign: TextAlign.center,
        ),
      );
    }

    // 2. വാർത്തകൾ ഉള്ളപ്പോൾ (Overflow Box വഴി മഞ്ഞ വരകൾ പൂർണ്ണമായി മാറ്റി)
    return ClipRect(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FractionalTranslation(
            translation: Offset(-_controller.value * 0.5, 0.0),
            child: OverflowBox(
              minWidth: 0,
              maxWidth: double.infinity,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.text,
                    style: widget.textStyle,
                    maxLines: 1,
                    softWrap: false,
                  ),
                  const SizedBox(width: 150),
                  Text(
                    widget.text,
                    style: widget.textStyle,
                    maxLines: 1,
                    softWrap: false,
                  ),
                  const SizedBox(width: 150),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DIGITAL CLOCK
// ---------------------------------------------------------------------------
class DigitalClockDisplay extends StatefulWidget {
  const DigitalClockDisplay({super.key});

  @override
  State<DigitalClockDisplay> createState() => _DigitalClockDisplayState();
}

class _DigitalClockDisplayState extends State<DigitalClockDisplay> {
  late String currentTime;
  late String currentDate;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateTime(),
    );
  }

  void _updateTime() {
    final now = DateTime.now();
    if (mounted) {
      setState(() {
        currentTime = DateFormat('hh:mm:ss a').format(now);
        currentDate = DateFormat('EEEE, dd MMM yyyy').format(now);
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          currentTime,
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontSize: 26,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          currentDate,
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
