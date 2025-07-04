import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class SwipeView extends StatefulWidget {
  const SwipeView({super.key});

  @override
  State<SwipeView> createState() => _SwipeViewState();
}

class FullScreenPlayer extends StatefulWidget {
  final YoutubePlayerController controller;

  const FullScreenPlayer({required this.controller, super.key});

  @override
  State<FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<FullScreenPlayer> {
  late YoutubePlayerController _fullScreenController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // Ekranı yatay yöne zorla
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Status bar'ı gizle
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Tam ekran için ayrı controller oluştur
    _fullScreenController = YoutubePlayerController(
      initialVideoId: '4oBmtMA9RtI',
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        hideControls: false, // Kontrolleri göster
        enableCaption: false,
        hideThumbnail: true,
        disableDragSeek: false,
        useHybridComposition: true,
        forceHD: false,
        startAt: widget.controller.value.position.inSeconds,
      ),
    );

    // 3 saniye sonra listener'ı aktif et
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _isInitialized = true;
      });

      // Tam ekran durumu değiştiğinde listener ekle
      _fullScreenController.addListener(() {
        if (_isInitialized &&
            _fullScreenController.value.isFullScreen == false) {
          // YouTube Player'ın tam ekranından çıkıldığında bu sayfadan da çık
          Navigator.pop(context);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: YoutubePlayer(
                controller: _fullScreenController,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.red,
                progressColors: ProgressBarColors(
                  playedColor: Colors.red,
                  handleColor: Colors.redAccent,
                ),
                onEnded: (metaData) {
                  Navigator.pop(context);
                },
              ),
            ),
            // Geri dönüş butonu ekle
            Positioned(
              top: 40,
              left: 20,
              child: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeViewState extends State<SwipeView> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    // Ana controller'ı tanımla
    _controller = YoutubePlayerController(
      initialVideoId: '4oBmtMA9RtI',
      flags: YoutubePlayerFlags(
        autoPlay: true,
        mute: true, // Ana sayfada ses kapalı
        hideControls: true, // Ana sayfada kontroller gizli
        enableCaption: false,
        hideThumbnail: true,
        disableDragSeek: false,
        useHybridComposition: true,
        forceHD: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        centerTitle: true,
        leading: IconButton(onPressed: () {}, icon: Icon(Icons.menu)),
        title: Text(
          "Swipe ",
          style: TextStyle(
            fontFamily: "Caveat Brush",
            fontSize: 40,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: Icon(Icons.person)),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.11,
              horizontal: screenWidth * 0.1,
            ),
            child: Text(
              "Film Name", //DATA AYARLANDIKTAN SONRA DÜZELT!!
              style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 20),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.099,
              horizontal: screenWidth * 0.4,
            ),
            child: Icon(
              Icons.star,
              color: Colors.black,
              size: screenWidth * 0.09999999999999,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.099,
              horizontal: screenWidth * 0.4,
            ),
            child: Icon(
              Icons.star,
              color: Colors.yellow,
              size: screenWidth * 0.1,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.52,
              screenHeight * 0.103,
              0,
              0,
            ),
            child: Text(
              "9.4",
              style: TextStyle(fontSize: 20, fontFamily: 'PlayfairDisplay'),
            ),
          ), //DATA AYARLANDIKTAN SONRA DÜZELT!!
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.65,
              screenHeight * 0.08,
              0,
              0,
            ),
            child: Image.asset(
              "assets/images/logo.png",
              width: screenWidth * 0.08,
              height: screenHeight * 0.09,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.75,
              screenHeight * 0.103,
              0,
              0,
            ),
            child: Text(
              "9.4",
              style: TextStyle(fontSize: 20, fontFamily: 'PlayfairDisplay'),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.87,
              screenHeight * 0.109,
              0,
              0,
            ),
            child: Image.asset(
              "assets/images/netflix_icon.png",
              width: screenWidth * 0.03,
              height: screenHeight * 0.03,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.15),
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: screenHeight * 0.5,
              child: Stack(
                children: [
                  ClipRect(
                    child: OverflowBox(
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: screenWidth * 2.5,
                          height: screenWidth * 2.5 * 9 / 16,
                          child: YoutubePlayer(
                            controller: _controller,
                            showVideoProgressIndicator: false,
                            onReady: () {},
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: IconButton(
                      onPressed: () {
                        // Tam ekran için yeni sayfa açalım
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    FullScreenPlayer(controller: _controller),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.1,
              screenHeight * 0.7,
              0,
              0,
            ),
            child: Text(
              "Creator:MERT NAZCAN",
              style: TextStyle(fontSize: 12, fontFamily: 'PlayfairDisplay'),
            ),
          ), //DATA AYARLANDIKTAN SONRA DÜZELT!!
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.1,
              screenHeight * 0.72,
              0,
              0,
            ),
            child: Text(
              "GENRE:ACTION COMEDY",
              style: TextStyle(fontSize: 12, fontFamily: 'PlayfairDisplay'),
            ),
          ), //DATA AYARLANDIKTAN SONRA DÜZELT!!
          Padding(
            padding: EdgeInsets.fromLTRB(
              screenWidth * 0.1,
              screenHeight * 0.74,
              0,
              0,
            ),
            child: Text(
              "CAST : MERT NAZCAN, MERT NAZCAN",
              style: TextStyle(fontSize: 12, fontFamily: 'PlayfairDisplay'),
            ),
          ),
        ],
      ),
    );
  }
}
