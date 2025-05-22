import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class SwipeView extends StatefulWidget {
  const SwipeView({super.key});

  @override
  State<SwipeView> createState() => _SwipeViewState();
}

class _SwipeViewState extends State<SwipeView> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: '4oBmtMA9RtI',
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: true,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
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
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0,
              horizontal: screenWidth * 0.02,
            ),
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.06,
                    horizontal: screenWidth * 0.07,
                  ),
                  child: Text(
                    "Film Name", //DATA AYARLANDIKTAN SONRA DÜZELT!!
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 20,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.06,
                    horizontal: screenWidth * 0.02,
                  ),
                  child: Stack(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.black,
                        size: screenWidth * 0.09999999999999,
                      ),
                      Icon(
                        Icons.star,
                        color: Colors.yellow,
                        size: screenWidth * 0.1,
                      ),
                    ],
                  ),
                ),
                Text(
                  "9.4",
                  style: TextStyle(fontSize: 15, fontFamily: 'PlayfairDisplay'),
                ), //DATA AYARLANDIKTAN SONRA DÜZELT!!
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.06,
                    horizontal: screenWidth * 0.08,
                  ),
                  child: Image.asset(
                    "assets/images/logo.png",
                    width: screenWidth * 0.08,
                    height: screenHeight * 0.08,
                  ),
                ),
                Text(
                  "9.4",
                  style: TextStyle(fontSize: 15, fontFamily: 'PlayfairDisplay'),
                ), //DATA AYARLANDIKTAN SONRA DÜZELT!!
              ],
            ),
          ),
          Container(
            color: Colors.black,
            width: double.infinity, 
            height: screenHeight * 0.6, 
            child: Center(
              child: YoutubePlayerScaffold(
                controller: _controller,
                aspectRatio: 4 / 3,
                builder: (context, player) {
                  return SizedBox(
                    width: screenWidth, 
                    height: screenHeight * 0.6, 
                    child: player,
                  );
                },
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                "Creator:MERT NAZCAN",
                style: TextStyle(fontSize: 12, fontFamily: 'PlayfairDisplay'),
              ), //DATA AYARLANDIKTAN SONRA DÜZELT!!
              Text(
                "GENRE:ACTION COMEDY",
                style: TextStyle(fontSize: 12, fontFamily: 'PlayfairDisplay'),
              ), //DATA AYARLANDIKTAN SONRA DÜZELT!!
              Text(
                "CAST : MERT NAZCAN, MERT NAZCAN",
                style: TextStyle(fontSize: 12, fontFamily: 'PlayfairDisplay'),
              ), //DATA AYARLANDIKTAN SONRA DÜZELT!!],)
            ],
          ),
        ],
      ),
    );
  }
}
