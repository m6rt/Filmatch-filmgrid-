import 'package:filmgrid/firebase_options.dart';
import 'package:filmgrid/services/auth_page.dart';
import 'package:filmgrid/views/login_view.dart';
import 'package:filmgrid/views/swipe_view.dart';
import 'package:filmgrid/views/profile_view.dart';
import 'package:filmgrid/views/browse_view.dart';
import 'package:filmgrid/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:device_preview/device_preview.dart';

class MySeparator extends StatelessWidget {
  const MySeparator({Key? key, this.height = 1, this.color = Colors.black})
    : super(key: key);
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 10.0;
        final dashHeight = height;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
        );
      },
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase'i initialize et
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // .env dosyasını yükle - güvenli şekilde
    print('📁 Loading environment variables...');
    try {
      await dotenv.load(fileName: ".env");
      print('✅ Environment variables loaded');
    } catch (envError) {
      print('⚠️ .env file not found, using default values');
      // .env dosyası yoksa manuel olarak değerler ekle
      dotenv.env['TVDB_API_KEY'] = '';
      dotenv.env['YOUTUBE_API_KEY'] = '';
    }

    print('🚀 Starting app...');
    runApp(
      DevicePreview(
        enabled: false, // Debug ve profile modda çalışır
        builder: (context) => MyApp(),
      ),
    );
  } catch (e) {
    print('❌ Initialization error: $e');
    // Hata durumunda basit bir app çalıştır
    runApp(
      DevicePreview(
        enabled: !kReleaseMode,
        builder: (context) => ErrorApp(error: e.toString()),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FilmGrid',
      theme: AppTheme.theme,
      home: const SwipeView(),
      routes: {
        '/login': (context) => const Loginview(),
        '/swipe': (context) => const SwipeView(),
        '/profile': (context) => const ProfileView(),
        '/browse': (context) => const BrowseView(),
      },
      // Device Preview için gerekli
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
    );
  }
}

// Hata durumu için basit widget
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red),
                SizedBox(height: 20),
                Text(
                  'Initialization Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    // App'i yeniden başlat
                    main();
                  },
                  child: Text('Retry'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    // Basit mod ile başlat
                    runApp(SimpleApp());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: Text('Start in Safe Mode'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Basit mod
class SimpleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('FilmGrid - Safe Mode'),
          backgroundColor: Colors.blue,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.movie, size: 100, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                'FilmGrid',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text('App started in safe mode'),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SwipeView()),
                  );
                },
                child: Text('Go to SwipeView'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
